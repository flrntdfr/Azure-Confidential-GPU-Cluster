#!/bin/bash
# https://docs.vllm.ai/en/latest/cli/bench/serve.html?h=bench#options

# vLLM benchmark
# Uses environment variables set by experiment scripts

# Set default values if not provided
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
        echo "→ Attempt $attempt/$max_attempts: Server still not ready, waiting..."
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

vllm bench serve \
  --backend vllm \
  --base-url http://${HOST}:${PORT} \
  --endpoint $ENDPOINT \
  --model $MODEL \
  --tokenizer $TOKENIZER \
  --dataset-name $DATASET_NAME \
  --random-input-len $RANDOM_INPUT_LEN \
  --random-output-len $RANDOM_OUTPUT_LEN \
  --num-prompts $NUM_PROMPTS \
  --max-concurrency $MAX_CONCURRENCY \
  --seed 54940 \
  --temperature $TEMPERATURE \
  --percentile-metrics ttft,tpot,itl,e2el \
  --metric-percentiles 25,50,75,95,99 \
  #--disable-shuffle \ # FIXME
  #--disable-tqdm \ # FIXME
  --no-oversample \
  --save-result \
  --save-detailed \
  --metadata "experiment=${EXPERIMENT_NAME},model=${MODEL},tokenizer=${TOKENIZER},gpu_memory_util=${GPU_MEMORY_UTIL},max_model_len=${MAX_MODEL_LEN},max_num_seqs=${MAX_NUM_SEQS},num_repetitions=${NUM_REPETITIONS},dataset_name=${DATASET_NAME},omp_num_threads=${OMP_NUM_THREADS},temperature=${TEMPERATURE}" \
  --result-dir results \
  --result-filename $OUTPUT_FILENAME \
  ${EXTRA_BENCH_FLAGS:-}