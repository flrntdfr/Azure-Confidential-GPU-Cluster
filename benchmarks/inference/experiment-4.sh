#!/bin/bash

source .venv/bin/activate

export EXPERIMENT_NAME="experiment-4"

# ------ #
# SYSTEM #
# ------ #

export OMP_NUM_THREADS=32
export TOKENIZERS_PARALLELISM=false
export CUDA_LAUNCH_BLOCKING=0                               # 1 = debugging, 0 = performance
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:False"  # Consistent memory allocation

# ------ #
# SERVER #
# ------ #

export GPU_MEMORY_UTIL=0.90 # 90%
export MAX_MODEL_LEN=8192

# --------- #
# BENCHMARK #
# --------- #

export MODELS=(
    "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B"
    "deepseek-ai/DeepSeek-R1-Distill-Qwen-14B"
    "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"
    "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
)

export TOKENIZERS=(
    "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B"
    "deepseek-ai/DeepSeek-R1-Distill-Qwen-14B"
    "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"
    "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
)

export MAX_NUM_SEQS_VALUES=(
    32
    64
    256
    1024
)

export DATASET_NAME="sharegpt"
export DATASET_PATH="./ShareGPT_V3_unfiltered_cleaned_split.json"
export RANDOM_INPUT_LEN=0  # Disable random
export RANDOM_OUTPUT_LEN=0 # Disable random
export NUM_PROMPTS=1000
export MAX_CONCURRENCY=1
export TEMPERATURE=0.7
export ENDPOINT="/v1/chat/completions"
export NUM_REPETITIONS=1 # ← FIXME omnifocus:///task/mIlki-CJgvQ

echo "→ Starting ${EXPERIMENT_NAME}"
echo "→ Collecting system information..."
bash ./collect-system-info.sh $EXPERIMENT_NAME

# Run benchmark
echo "→ Running benchmark..."
for i in "${!MODELS[@]}"; do
    export MODEL="${MODELS[$i]}"
    export TOKENIZER="${TOKENIZERS[$i]}"
    export MAX_NUM_SEQS="${MAX_NUM_SEQS_VALUES[$i]}"

    echo "MODEL: $MODEL"
    echo "TOKENIZER: $TOKENIZER"
    echo "MAX_NUM_SEQS: $MAX_NUM_SEQS"

    # Serve
    echo "→ Starting vLLM server..."
    ./serve.sh &
    SERVER_PID=$!

    # Bench
    echo "→ Running benchmark..."
    for i in $(seq 1 $NUM_REPETITIONS); do
        export REPETITION=$i
        echo "→ Running repetition $REPETITION"
        
        ./bench.sh
        
        # Take a breath
        sleep 5
    done

    # Stop server
    echo "→ Stopping server..."
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
done