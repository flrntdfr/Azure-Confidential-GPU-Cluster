# vLLM benchmark

source "./settings.sh"

EXTRA_FLAGS=""
#EXTRA_FLAGS="--poisson"

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
  $EXTRA_FLAGS