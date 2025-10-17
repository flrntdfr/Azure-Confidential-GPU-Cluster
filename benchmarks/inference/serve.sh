#!/bin/bash
# Start the vLLM server
# Uses environment variables set by experiment scripts

export VLLM_ENABLE_V1_MULTIPROCESSING=0

# Set default values if not provided
HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"8000"}

echo "Starting vLLM server with:"
echo "  Model: $MODEL"
echo "  Host: $HOST:$PORT"
echo "  GPU memory utilization: $GPU_MEMORY_UTIL"

vllm serve $MODEL \
  --tokenizer $TOKENIZER \
  --gpu-memory-utilization $GPU_MEMORY_UTIL \
  --host $HOST --port $PORT \
  --disable-fastapi-docs \
  --enable-server-load-tracking \
  --seed 54940 \
  $EXTRA_FLAGS

# --max-num-seqs # https://docs.vllm.ai/en/stable/cli/serve.html#-max-num-seqs
# --max-num-batched-tokens # https://docs.vllm.ai/en/stable/cli/serve.html#-max-num-batched-tokens
