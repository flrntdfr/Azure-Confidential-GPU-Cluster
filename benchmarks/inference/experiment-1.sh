#!/bin/bash

source .venv/bin/activate

export EXPERIMENT_NAME="experiment-1"

# ------ #
# SYSTEM #
# ------ #

export OMP_NUM_THREADS=32
export TOKENIZERS_PARALLELISM=false

# Critical for determinism across different GPUs:
export CUDA_LAUNCH_BLOCKING=0  # Set to 1 for debugging, 0 for performance
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:False"  # Consistent memory allocation

# For reproducible CUDA operations (may reduce performance):
# export CUBLAS_WORKSPACE_CONFIG=:4096:8
# export CUDA_DEVICE_ORDER=PCI_BUS_ID

# ----- #
# MODEL #
# ----- #

export MODELS=(
    "meta-llama/Llama-3.1-8B-Instruct"
    "Qwen/Qwen3-32B"
    "deepseek-ai/DeepSeek-R1-Distill-Llama-70B"
)

export TOKENIZERS=(
    "meta-llama/Llama-3.1-8B-Instruct"
    "Qwen/Qwen3-32B"
    "deepseek-ai/DeepSeek-R1-Distill-Llama-70B"
)

export MAX_NUM_SEQSS=(
    256
    64
    32
)

# ------ #
# SERVER #
# ------ #

export GPU_MEMORY_UTIL=0.90 # 90%
export MAX_MODEL_LEN=8192

# For deterministic benchmarks, consider adding:
# export EXTRA_FLAGS="--enforce-eager"  # Disables CUDA graphs for determinism

# --------- #
# BENCHMARK #
# --------- #

export NUM_REPETITIONS=5
export DATASET_NAME="random"
export RANDOM_INPUT_LEN=128
export RANDOM_OUTPUT_LEN=128
export NUM_PROMPTS=1000
export MAX_CONCURRENCY=1
export TEMPERATURE=0
export ENDPOINT="/v1/completions"

echo "→ Starting experiment 1"

echo "→ Collecting system information..."
bash ./collect-system-info.sh $EXPERIMENT_NAME

# Run benchmark
echo "→ Running benchmark..."
for i in "${!MODELS[@]}"; do
    export MODEL="${MODELS[$i]}"
    export TOKENIZER="${TOKENIZERS[$i]}"
    export MAX_NUM_SEQS="${MAX_NUM_SEQSS[$i]}"

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
    done

    # Stop server
    echo "→ Stopping server..."
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
done