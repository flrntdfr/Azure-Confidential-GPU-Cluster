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
echo "  Max model length: ${MAX_MODEL_LEN:-8192}"
echo "  Max num seqs: ${MAX_NUM_SEQS:-256}"

vllm serve $MODEL \
  --disable-fastapi-docs \
  --disable-log-requests \
  --enable-server-load-tracking \
  --gpu-memory-utilization $GPU_MEMORY_UTIL \
  --max-model-len ${MAX_MODEL_LEN:-8192} \
  --max-num-seqs ${MAX_NUM_SEQS:-256} \
  --host $HOST --port $PORT \
  --seed 54940 \
  --tokenizer $TOKENIZER \
  $EXTRA_FLAGS

# --max-num-seqs # https://docs.vllm.ai/en/stable/cli/serve.html#-max-num-seqs
# --max-num-batched-tokens # https://docs.vllm.ai/en/stable/cli/serve.html#-max-num-batched-tokens
