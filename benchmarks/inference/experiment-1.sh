#!/bin/bash

source .venv/bin/activate

# Set experiment name for tracking
export EXPERIMENT_NAME="experiment-1"

# ------ #
# SYSTEM #
# ------ #

export OMP_NUM_THREADS=32
export TOKENIZERS_PARALLELISM=false # FIXME ?

# ----- #
# MODEL #
# ----- #

#export MODEL=meta-llama/Llama-3.1-8B-Instruct
#export TOKENIZER=meta-llama/Llama-3.1-8B-Instruct

export MODEL=google/gemma-3-1b-it
export TOKENIZER=google/gemma-3-1b-it

# ------ #
# SERVER #
# ------ #

#export GPU_MEMORY_UTIL=0.95
export MAX_MODEL_LEN=8192
#export MAX_NUM_SEQS=256 # FIXME
export MAX_NUM_SEQS=16

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

echo "→ Starting experiment 1: Single request baseline"
echo "→ MODEL: $MODEL"
echo "→ MAX_CONCURRENCY: $MAX_CONCURRENCY"

# Start server in background
echo "→ Starting vLLM server..."
./serve.sh &
SERVER_PID=$!

# Run benchmark
echo "→ Running benchmark..."
for i in {1..$NUM_REPETITIONS}; do
    echo "→ Running repetition $i"
    ./bench.sh
done

# Stop server
echo "→ Stopping server..."
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true