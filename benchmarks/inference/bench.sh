#!/bin/bash
# https://docs.vllm.ai/en/latest/cli/bench/serve.html?h=bench#options

# vLLM benchmark
# Uses environment variables set by experiment scripts

# Server
HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"8000"}

# Create results directory if it doesn't exist
mkdir -p results

# Generate output filename based on current configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILENAME="benchmark_${MODEL##*/}_concurrency_${MAX_CONCURRENCY}_${TIMESTAMP}.json"

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

echo "Running benchmark with:"
echo "  Model: $MODEL"
echo "  Server: http://${HOST}:${PORT}"
echo "  Concurrency: $MAX_CONCURRENCY"
echo "  Prompts: $NUM_PROMPTS"
echo "  Input length: $RANDOM_INPUT_LEN"
echo "  Output length: $RANDOM_OUTPUT_LEN"
echo "  Output file: results/$OUTPUT_FILENAME"

echo "→ Starting power logging..."
nvidia-smi --query-gpu=timestamp,power.draw,utilization.gpu,utilization.memory \
    --format=csv \
    -l 1 > power_metrics_${EXPERIMENT_NAME}.csv &
NVIDIA_SMI_PID=$!

echo "→ Starting benchmark..."
vllm bench serve \
  --base-url http://${HOST}:${PORT} \
  --dataset-name $DATASET_NAME \
  --endpoint $ENDPOINT \
  --label $EXPERIMENT_NAME \
  --max-concurrency $MAX_CONCURRENCY \
  --metric-percentiles 50,95,99 \
  --model $MODEL \
  --no-oversample \
  --num-prompts $NUM_PROMPTS \
  --percentile-metrics ttft,tpot,itl,e2el \
  --random-input-len $RANDOM_INPUT_LEN \
  --random-output-len $RANDOM_OUTPUT_LEN \
  --result-dir "./results" \
  --result-filename $OUTPUT_FILENAME \
  --save-detailed \
  --save-result \
  --seed 54940 \
  --temperature $TEMPERATURE \
  --tokenizer $TOKENIZER \

# --no-stream # Do not load the dataset in streaming mode.
# --max-concurrency # Maximum number of concurrent requests. This can be used to help simulate an environment where a higher level component is enforcing a maximum number of concurrent requests. While the --request-rate argument controls the rate at which requests are initiated, this argument will control how many are actually allowed to execute at a time. This means that when used in combination, the actual request rate may be lower than specified with --request-rate, if the server is not processing requests fast enough to keep up.
# --request-rate Number of requests per second. If this is inf, then all the requests are sent at time 0. Otherwise, we use Poisson process or gamma distribution to synthesize the request arrival times.
# --burstiness Burstiness factor of the request generation. Only take effect when request_rate is not inf. Default value is 1, which follows Poisson process. Otherwise, the request intervals follow a gamma distribution. A lower burstiness value (0 < burstiness < 1) results in more bursty requests. A higher burstiness value (burstiness > 1) results in a more uniform arrival of requests.
# --profile Use Torch Profiler. The endpoint must be launched with VLLM_TORCH_PROFILER_DIR to enable profiler.


kill $NVIDIA_SMI_PID 2>/dev/null || true