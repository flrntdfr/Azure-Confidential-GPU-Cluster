#!/bin/bash
# Run the vLLM benchmark
# https://docs.vllm.ai/en/latest/cli/bench/serve.html

HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"8000"}

# Create output directory
mkdir -p ./results/"$(dirname "$OUTPUT_FILENAME")"

# --------------------------- #
# Wait for server to be ready #
# --------------------------- #

echo "→ Waiting for server to be ready..."
wait_for_server() {
    local host=${HOST}
    local port=${PORT}
    local max_attempts=100
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" "http://${host}:${port}/health" | grep -q "200"; then
            echo "→ Server is ready!"
            return 0
        fi
        echo "→ [$attempt/$max_attempts] Server still not ready. waiting..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo "→ Server failed to start within expected time"
    exit 1
}

sleep 20
wait_for_server

# --------------- #
# Warmup requests #
# --------------- #

echo "→ Running 10 warmup requests..."
for i in {1..10}; do
    curl -s http://${HOST:-"127.0.0.1"}:${PORT:-"8000"}/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d '{
            "model": "'$MODEL'",
            "messages": [{"role": "user", "content": "Continue the following text: Maître corbeau, sur un arbre perché, tenait ..."}],
            "max_tokens": 20
        }' > /dev/null
done

# ---------------------- #
# Start power monitoring #
# ---------------------- #

# GPU

echo "→ Starting GPU power logging..."
echo "Output file: ./results/${OUTPUT_FILENAME%.*}_power_metrics_GPU.csv"
nvidia-smi --query-gpu=timestamp,power.draw,utilization.gpu,utilization.memory,clocks.gr,clocks.mem,temperature.gpu \
    --format=csv \
    -l 1 > ./results/${OUTPUT_FILENAME%.*}_power_metrics_GPU.csv &
NVIDIA_SMI_PID=$!

# CPU

echo "→ Starting CPU power logging..."
echo "Output file: ./results/${OUTPUT_FILENAME%.*}_power_metrics_CPU.csv"
if [ -d "/sys/class/powercap/amd-rapl" ]; then
    {
        echo "timestamp,package_power_watts"
        RAPL_DIR=$(ls -d /sys/class/powercap/amd-rapl*/*:0 2>/dev/null | head -1)
        ENERGY_FILE="${RAPL_DIR}/energy_uj"
        
        PREV_ENERGY=$(cat "$ENERGY_FILE" 2>/dev/null || echo 0)
        PREV_TIME=$(date +%s%N)
        
        while sleep 1; do
            CURR_ENERGY=$(cat "$ENERGY_FILE" 2>/dev/null || echo 0)
            CURR_TIME=$(date +%s%N)
            TIME_DIFF=$(awk "BEGIN {printf \"%.9f\", ($CURR_TIME - $PREV_TIME) / 1000000000}")
            ENERGY_DIFF=$((CURR_ENERGY - PREV_ENERGY))
            POWER=$(awk "BEGIN {printf \"%.2f\", ($ENERGY_DIFF / 1000000) / $TIME_DIFF}")
            echo "$(date +%Y-%m-%d\ %H:%M:%S),$POWER"
            PREV_ENERGY=$CURR_ENERGY
            PREV_TIME=$CURR_TIME
        done
    } > ./results/${OUTPUT_FILENAME%.*}_power_metrics_CPU.csv &
    CPU_MONITOR_PID=$!
else
    echo "→ AMD RAPL interface not found, CPU power monitoring disabled"
fi

# --------------- #
# Start benchmark #
# --------------- #

echo "Running benchmark with:"
echo "  Scripts: $(git rev-parse HEAD) ($(git rev-list --count HEAD))"
echo "  Model: $MODEL"
echo "  Server: http://${HOST}:${PORT}"
echo "  Concurrency: $MAX_CONCURRENCY"
echo "  Prompts: $NUM_PROMPTS"
echo "  Output file: results/$OUTPUT_FILENAME"

echo "→ Starting benchmark..."
vllm bench serve \
  --backend openai-chat \
  --base-url http://${HOST}:${PORT} \
  --burstiness ${BURSTINESS:-"1.0"} \
  --dataset-name $DATASET_NAME \
  $([ "$DATASET_NAME" != "random" ] && echo "--dataset-path $DATASET_PATH") \
  $([ "$DATASET_NAME" = "random" ] && echo "--random-input-len $RANDOM_INPUT_LEN") \
  $([ "$DATASET_NAME" = "random" ] && echo "--random-output-len $RANDOM_OUTPUT_LEN") \
  --endpoint $ENDPOINT \
  --label $EXPERIMENT_NAME \
  --max-concurrency $MAX_CONCURRENCY \
  --metric-percentiles 25,50,75,95,99 \
  --model $MODEL \
  --no-oversample \
  --num-prompts $NUM_PROMPTS \
  --percentile-metrics ttft,tpot,itl,e2el \
  --request-rate ${REQUEST_RATE:-"inf"} \
  --result-dir "./results" \
  --result-filename $OUTPUT_FILENAME \
  --save-detailed \
  --save-result \
  --seed 54940 \
  --temperature $TEMPERATURE \
  --tokenizer $TOKENIZER \
  $EXTRA_FLAGS_BENCH

kill $NVIDIA_SMI_PID 2>/dev/null || true
[ -n "$CPU_MONITOR_PID" ] && kill $CPU_MONITOR_PID 2>/dev/null || true