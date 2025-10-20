#!/bin/bash
# Run the vLLM benchmark
# https://docs.vllm.ai/en/latest/cli/bench/serve.html

# Create results directory if it doesn't exist
mkdir -p results

# Generate output filename based on current configuration
TIMESTAMP=$(date +%Y%m%d_%H%M-%S)
OUTPUT_FILENAME="${TIMESTAMP}_${EXPERIMENT_NAME}_${MODEL##*/}_max-concurrency_${MAX_CONCURRENCY}_input-len_${RANDOM_INPUT_LEN}_output-len_${RANDOM_OUTPUT_LEN}_repetition_${REPETITION}.json"

# Wait for server to be ready
echo "→ Waiting for server to be ready..."
wait_for_server() {
    local host=${HOST:-"127.0.0.1"}
    local port=${PORT:-"8000"}
    local max_attempts=60
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
    return 1
}

sleep 60
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

# IMPORTANT: For deterministic GPU comparisons, consider locking GPU clocks:
# sudo nvidia-smi -pm 1  # Enable persistence mode
# sudo nvidia-smi -lgc <min_clock>,<max_clock>  # Lock graphics clock
# This prevents GPU Boost and thermal throttling from affecting results

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

# https://docs.vllm.ai/en/stable/cli/bench/serve.html
# --no-stream # Do not load the dataset in streaming mode.
# --max-concurrency # Maximum number of concurrent requests. This can be used to help simulate an environment where a higher level component is enforcing a maximum number of concurrent requests. While the --request-rate argument controls the rate at which requests are initiated, this argument will control how many are actually allowed to execute at a time. This means that when used in combination, the actual request rate may be lower than specified with --request-rate, if the server is not processing requests fast enough to keep up.
# --request-rate Number of requests per second. If this is inf, then all the requests are sent at time 0. Otherwise, we use Poisson process or gamma distribution to synthesize the request arrival times.
# --burstiness Burstiness factor of the request generation. Only take effect when request_rate is not inf. Default value is 1, which follows Poisson process. Otherwise, the request intervals follow a gamma distribution. A lower burstiness value (0 < burstiness < 1) results in more bursty requests. A higher burstiness value (burstiness > 1) results in a more uniform arrival of requests.

kill $NVIDIA_SMI_PID 2>/dev/null || true