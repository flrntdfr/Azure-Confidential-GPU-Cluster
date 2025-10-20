#!/bin/bash

source .venv/bin/activate

export EXPERIMENT_NAME="experiment-3"

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
    "google/gemma-3-1b-it"
    "meta-llama/Llama-3.1-8B-Instruct"
    "mistralai/Mistral-Small-24B-Instruct-2501"
    "Qwen/Qwen3-32B"
    # "deepseek-ai/DeepSeek-R1-Distill-Llama-70B"
)

export TOKENIZERS=(
    "google/gemma-3-1b-it"
    "meta-llama/Llama-3.1-8B-Instruct"
    "mistralai/Mistral-Small-24B-Instruct-2501"
    "Qwen/Qwen3-32B"
    # "deepseek-ai/DeepSeek-R1-Distill-Llama-70B"
)

export MAX_NUM_SEQS_VALUES=(
    1024
    512
    256
    64
    32
    # 1
)

export DATASET_NAME="random"
export RANDOM_INPUT_LEN=128
export RANDOM_OUTPUT_LEN=128
export NUM_PROMPTS=10 # ← FIXME (1000)
export MAX_CONCURRENCY=1
export TEMPERATURE=0
export ENDPOINT="/v1/completions"
export NUM_REPETITIONS=1 # ← FIXME omnifocus:///task/ihyxo8q5fbn

export INPUT_LEN_VALUES=(64 128 256 512 1024)
export OUTPUT_LEN_VALUES=(64 128 256 512 1024)

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


    # Bench
    for INPUT_LEN in ${INPUT_LEN_VALUES[@]}; do
        echo "INPUT_LEN: $INPUT_LEN"
        export INPUT_LEN=$INPUT_LEN

        for OUTPUT_LEN in ${OUTPUT_LEN_VALUES[@]}; do
            echo "OUTPUT_LEN: $OUTPUT_LEN"
            export OUTPUT_LEN=$OUTPUT_LEN


            echo "→ Running benchmark..."
            for i in $(seq 1 $NUM_REPETITIONS); do
                export REPETITION=$i
                echo "→ Running repetition $REPETITION"
                
                ./bench.sh
                
                # Take a breath
                sleep 5
            done

    # Stop server and wait for GPU cleanup
    echo "→ Stopping server..."
    pkill vllm || true

    # Wait for GPU memory to be released
    until nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | awk '{exit !($1 < 1000)}'; do
        echo "→ …Freeing memory"
        sleep 5
    done
    echo "→ GPU memory freed to go!"
done