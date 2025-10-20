#!/bin/bash
# Run the vLLM benchmark
# https://docs.vllm.ai/en/latest/cli/bench/serve.html

HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"8000"}

# Create results directory if it doesn't exist
mkdir -p results

# Generate output filename based on current configuration
TIMESTAMP=$(date +%Y%m%d_%H%M-%S)
OUTPUT_FILENAME="${TIMESTAMP}_${EXPERIMENT_NAME}_${MODEL##*/}_max-concurrency_${MAX_CONCURRENCY}_input-len_${RANDOM_INPUT_LEN}_output-len_${RANDOM_OUTPUT_LEN}_repetition_${REPETITION}.json"

# Wait for server to be ready
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

echo "→ Running 10 warmup requests..."
for i in {1..10}; do
    curl -s http://${HOST:-"127.0.0.1"}:${PORT:-"8000"}/v1/completions \
        -H "Content-Type: application/json" \
        -d '{
            "model": "'$MODEL'",
            "prompt": "Hello",
            "max_tokens": 10
        }' > /dev/null
done

echo "→ Starting power logging..."
nvidia-smi --query-gpu=timestamp,power.draw,utilization.gpu,utilization.memory,clocks.gr,clocks.mem,temperature.gpu \
    --format=csv \
    -l 1 > ./results/${TIMESTAMP}_${EXPERIMENT_NAME}_${MODEL##*/}_max-concurrency_${MAX_CONCURRENCY}_input-len_${RANDOM_INPUT_LEN}_output-len_${RANDOM_OUTPUT_LEN}_repetition_${REPETITION}_power_metrics.csv &
NVIDIA_SMI_PID=$!

echo "Running benchmark with:"
echo "  Model: $MODEL"
echo "  Server: http://${HOST}:${PORT}"
echo "  Concurrency: $MAX_CONCURRENCY"
echo "  Prompts: $NUM_PROMPTS"
echo "  Input length: $RANDOM_INPUT_LEN"
echo "  Output length: $RANDOM_OUTPUT_LEN"
echo "  Output file: results/$OUTPUT_FILENAME"

echo "→ Starting benchmark..."
vllm bench serve \
  --base-url http://${HOST:-"127.0.0.1"}:${PORT:-"8000"} \
  --burstiness ${BURSTINESS:-"1.0"} \
  --dataset-name $DATASET_NAME \
  --endpoint $ENDPOINT \
  --label $EXPERIMENT_NAME \
  --max-concurrency $MAX_CONCURRENCY \
  --metric-percentiles 25,50,75,95,99 \
  --model $MODEL \
  --no-oversample \
  --num-prompts $NUM_PROMPTS \
  --percentile-metrics ttft,tpot,itl,e2el \
  --random-input-len $RANDOM_INPUT_LEN \
  --random-output-len $RANDOM_OUTPUT_LEN \
  --request-rate ${REQUEST_RATE:-"inf"} \
  --result-dir "./results" \
  --result-filename $OUTPUT_FILENAME \
  --save-detailed \
  --save-result \
  --seed 54940 \
  --temperature $TEMPERATURE \
  --tokenizer $TOKENIZER \
  $EXTRA_FLAGS

kill $NVIDIA_SMI_PID 2>/dev/null || true