#!/bin/bash
#SBATCH --job-name=vLLM-experiment-2
#SBATCH --partition=lrz-hgx-h100-94x4 # Partition
#SBATCH --nodes=1                     # Number of nodes to allocate
#SBATCH --ntasks-per-node=1           # One task per node
#SBATCH --gres=gpu:1                  # Total GPUs needed for all experiments
#SBATCH --cpus-per-task=40            # CPUs per task
#SBATCH --mem=0                       # Use entire memory of node
#SBATCH --time=4:00:00                # Maximum run time
#SBATCH --output=results/experiment-2-%j.out
#SBATCH --error=results/experiment-2-%j.err

source bootstrap.sh

export EXPERIMENT_NAME="experiment-2"
export TIMESTAMP=$(date +%Y%m%d_%H%M-%S)

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
    "Qwen/Qwen3-32B"
)

export TOKENIZERS=(
    "Qwen/Qwen3-32B"
)

export MAX_NUM_SEQS_VALUES=(
    64
)

export MAX_CONCURRENCY_VALUES=(1 2 4 8 12 16 20 24 32 40 48 64 128 256 512 1024)

export DATASET_NAME="sharegpt"
export DATASET_PATH="./ShareGPT_V3_unfiltered_cleaned_split.json"
export NUM_PROMPTS=1000
export TEMPERATURE=0.7
export ENDPOINT="/v1/chat/completions"
export NUM_REPETITIONS=5

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
    for MAX_CONCURRENCY in ${MAX_CONCURRENCY_VALUES[@]}; do
        echo "MAX_CONCURRENCY: $MAX_CONCURRENCY"
        export MAX_CONCURRENCY=$MAX_CONCURRENCY

        echo "→ Running benchmark..."
        for i in $(seq 1 $NUM_REPETITIONS); do
            
            echo "→ Running repetition $REPETITION"
            export REPETITION=$i
            export OUTPUT_FILENAME="${TIMESTAMP}_${EXPERIMENT_NAME}_${MODEL##*/}_max_concurrency_${MAX_CONCURRENCY}_repetition_${REPETITION}.json"

            ./bench.sh
            
            # Take a breath
            sleep 5
        done
    done

    # Stop server and wait for GPU cleanup
    echo "→ Stopping server..."
    pkill vllm || true

    # Wait for GPU memory to be released
    until nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | awk '{exit !($1 < 1000)}'; do
        echo "→ …Freeing memory"
        sleep 5
    done
    echo "→ GPU ready to go!"
done