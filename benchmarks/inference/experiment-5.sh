#!/bin/bash

source .venv/bin/activate

export EXPERIMENT_NAME="experiment-5"

# ------ #
# SYSTEM #
# ------ #

export OMP_NUM_THREADS=32
export TOKENIZERS_PARALLELISM=false # FIXME ?

# ----- #
# MODEL #
# ----- #

MODELS=(
    "meta-llama/Llama-3.1-8B-Instruct"          # 8B
    "Qwen/Qwen3-32B"                            # 32B
    "deepseek-ai/DeepSeek-R1-Distill-Llama-70B" # 70B
)

# ------ #
# SERVER #
# ------ #

export GPU_MEMORY_UTIL=0.90
export MAX_NUM_SEQS=256 # FIXME?

# --------- #
# BENCHMARK #
# --------- #

export NUM_REPETITIONS=5
export DATASET_NAME="random"
export RANDOM_INPUT_LEN=128
export RANDOM_OUTPUT_LEN=128
export NUM_PROMPTS=1000
export TEMPERATURE=0
export TIMEOUT=600

echo "Starting experiment 5: model size comparison"

for MODEL in "${MODELS[@]}"; do
    export MODEL="$MODEL"

    echo "MODEL: $MODEL"

    # Serve
    echo "Starting vLLM server..."
    ./serve.sh &
    SERVER_PID=$!

    # Bench
    echo "Waiting for server to start..."
    sleep 30

    ./bench.sh

    # Stop server
    echo "Stopping server..."
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
done