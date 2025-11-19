#!/bin/bash
#SBATCH --job-name=medalpaca-singlenode
#SBATCH --partition=test-v100x2 # Specify partition name
#SBATCH --qos=testing
#SBATCH --nodes=1                     # Single node
#SBATCH --ntasks-per-node=1           # One task per node
#SBATCH --gres=gpu:1                  # GPUs per node
#SBATCH --cpus-per-task=16            # CPUs per task
#SBATCH --mem=0                       # Use entire memory of node
#SBATCH --time=1:00:00                # Maximum run time
#SBATCH --output=results/medalpaca-singlenode-%j.out
#SBATCH --error=results/medalpaca-singlenode-%j.err

set -aeux

MODEL=Qwen/Qwen2.5-0.5B
USE_LORA=False
LOAD_IN_4BIT=True
LOAD_IN_8BIT=False
PER_DEVICE_TRAIN_BATCH_SIZE=1
MAX_SEQ_LENGTH=128
USE_WANDB=True
WANDB_PROJECT=medalpaca-du4-calibration
WANDB_RUN_NAME="medAlpaca-singlenode-${SLURM_JOB_ID}"
TAGS="singlenode,$SLURM_JOB_PARTITION"

echo -e "\n=========================================="
echo "SLURM Job Information"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Job name: $SLURM_JOB_NAME"
echo "Partition: $SLURM_JOB_PARTITION"
echo "Node list: $SLURM_NODELIST"
echo "Number of nodes: $SLURM_JOB_NUM_NODES"
echo "GPUs per node: $SLURM_GPUS_ON_NODE"
echo "Tasks per node: $SLURM_NTASKS_PER_NODE"
echo "Working directory: $(pwd)"
echo "=========================================="

# Set HuggingFace cache directory
export HF_HOME=$HOME/.cache/huggingface

# PyTorch
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-40}"

cd $HOME/Azure-Confidential-GPU-Cluster/benchmarks/finetuning
mkdir -p ./results
source .venv/bin/activate

echo -e "\nStarting training..."
python src/train.py \
    --model $MODEL \
    --use_lora $USE_LORA \
    --max_seq_length $MAX_SEQ_LENGTH \
    --per_device_train_batch_size $PER_DEVICE_TRAIN_BATCH_SIZE \
    --load_in_4bit $LOAD_IN_4BIT \
    --load_in_8bit $LOAD_IN_8BIT \
    --use_wandb $USE_WANDB \
    --wandb_project $WANDB_PROJECT \
    --wandb_run_name $WANDB_RUN_NAME \
    --wandb_tags $TAGS \

echo "=========================================="
echo "Training completed successfully!"
echo -e "==========================================\n"