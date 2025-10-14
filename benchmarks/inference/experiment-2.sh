#!/bin/bash

# ------ #
# SYSTEM #
# ------ #

export OMP_NUM_THREADS=32
export TOKENIZERS_PARALLELISM=false # FIXME ?

# ----- #
# MODEL #
# ----- #

export MODEL=meta-llama/Llama-3.1-8B-Instruct
export TOKENIZER=meta-llama/Llama-3.1-8B-Instruct

# ------ #
# SERVER #
# ------ #

export GPU_MEMORY_UTIL=0.90
export MAX_MODEL_LEN=8192
export MAX_NUM_SEQS=256

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

echo "Starting experiment 2: Concurrency sweep"
echo "MODEL: $MODEL"

# Start server in background
echo "Starting vLLM server..."
./serve.sh &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to start..."
sleep 30

# Run benchmarks with different concurrency levels
for CONCURRENCY in 1 2 4 8 16 32 64; do
    echo "MAX_CONCURRENCY: $CONCURRENCY"
    export MAX_CONCURRENCY=$CONCURRENCY
    ./bench.sh
    
    # Small delay between runs
    sleep 5
done

# Stop server
echo "Stopping server..."
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true