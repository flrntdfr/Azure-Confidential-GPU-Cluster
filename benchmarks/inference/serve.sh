#!/bin/bash
# Start the vLLM server
# https://docs.vllm.ai/en/latest/cli/serve.html

export VLLM_ENABLE_V1_MULTIPROCESSING=0

HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"8000"}

echo "Starting vLLM server with:"
echo "  Model:            $MODEL"
echo "  Tokenizer:        $TOKENIZER"
echo "  Max model length: $MAX_MODEL_LEN"
echo "  Max num seqs:     $MAX_NUM_SEQS"
echo "  Host:             $HOST:$PORT"
echo "  GPU memory utilization: $GPU_MEMORY_UTIL"

vllm serve $MODEL \
  --disable-fastapi-docs \
  --disable-log-requests \
  --enable-server-load-tracking \
  --gpu-memory-utilization $GPU_MEMORY_UTIL \
  --host $HOST --port $PORT \
  --max-model-len $MAX_MODEL_LEN \
  --max-num-seqs $MAX_NUM_SEQS \
  --seed 54940 \
  --tokenizer $TOKENIZER \
  $EXTRA_FLAGS