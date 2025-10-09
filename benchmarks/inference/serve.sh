# vLLM server

source "./settings.sh"

HOST="127.0.0.1"
PORT="8000"
API_KEY="dummy"
GPU_MEMORY_UTIL=0.90
EXTRA_FLAGS="--enable-chunked-prefill --disable-log-requests"

vllm serve $MODEL \
  --tokenizer $TOKENIZER \
  --max-model-len $MAX_MODEL_LEN \
  --max-num-seqs $MAX_NUM_SEQS \
  --gpu-memory-utilization $GPU_MEMORY_UTIL \
  --host $HOST --port $PORT \
  --api-key $API_KEY \
  $EXTRA_FLAGS