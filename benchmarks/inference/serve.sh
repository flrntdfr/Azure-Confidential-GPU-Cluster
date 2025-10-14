#!/bin/bash

# vLLM server
# Uses environment variables set by experiment scripts

# Set default values if not provided
HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"8000"}
API_KEY=${API_KEY:-"dummy"}
EXTRA_FLAGS=${EXTRA_FLAGS:-"--enable-chunked-prefill --disable-log-requests"}

echo "Starting vLLM server with:"
echo "  Model: $MODEL"
echo "  Host: $HOST:$PORT"
echo "  Max model length: $MAX_MODEL_LEN"
echo "  Max sequences: $MAX_NUM_SEQS"
echo "  GPU memory utilization: $GPU_MEMORY_UTIL"

vllm serve $MODEL \
  --tokenizer $TOKENIZER \
  --max-model-len $MAX_MODEL_LEN \
  --max-num-seqs $MAX_NUM_SEQS \
  --gpu-memory-utilization $GPU_MEMORY_UTIL \
  --host $HOST --port $PORT \
  --api-key $API_KEY \
  $EXTRA_FLAGS