#!/bin/bash

source .venv/bin/activate

export EXPERIMENT_NAME="experiment-3"

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

echo "Starting experiment 3: Sequence length sensitivity"
echo "MODEL: $MODEL"

# Start server in background
echo "Starting vLLM server..."
./serve.sh &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to start..."
sleep 30

# Test matrix: input x output lengths
for INPUT_LEN in 64 128 256 512 1024; do
    for OUTPUT_LEN in 64 128 256 512 1024; do
        RANDOM_INPUT_LEN=$INPUT_LEN
        RANDOM_OUTPUT_LEN=$OUTPUT_LEN
        NUM_PROMPTS=500
        MAX_CONCURRENCY=8 # FIXME from prev result?
        
        ./bench.sh

        # Take a breath
        sleep 5
    done
done

# Stop server
echo "Stopping server..."
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true