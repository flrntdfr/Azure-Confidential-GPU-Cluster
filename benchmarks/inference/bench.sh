#!/bin/bash

# vLLM benchmark
# Uses environment variables set by experiment scripts

# Set default values if not provided
HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"8000"}
TIMEOUT=${TIMEOUT:-600}

# Create results directory if it doesn't exist
mkdir -p results

# Generate output filename based on current configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILENAME="benchmark_${MODEL##*/}_concurrency_${MAX_CONCURRENCY}_${TIMESTAMP}.json"

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
  --endpoint /v1/chat/completions \
  --model $MODEL \
  --tokenizer $TOKENIZER \
  --dataset-name $DATASET_NAME \
  --random-input-len $RANDOM_INPUT_LEN \
  --random-output-len $RANDOM_OUTPUT_LEN \
  --num-prompts $NUM_PROMPTS \
  --max-concurrency $MAX_CONCURRENCY \
  --temperature $TEMPERATURE \
  --timeout $TIMEOUT \
  --output-path results/$OUTPUT_FILENAME \
  ${EXTRA_BENCH_FLAGS:-}