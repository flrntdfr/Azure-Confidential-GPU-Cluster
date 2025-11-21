#!/bin/bash
#SBATCH --job-name=medalpaca-1node-1gpu
#SBATCH --partition=lrz-hgx-h100-94x4
#SBATCH --nodes=1                     # Single node
#SBATCH --ntasks-per-node=1           # One task per node
#SBATCH --gres=gpu:1                  # GPUs per node
#SBATCH --time=2:00:00                # Maximum run time
#SBATCH --output=../results/medalpaca-1node-1gpu-%j.out
#SBATCH --error=../results/medalpaca-1node-1gpu-%j.err

set -eaux

MODEL=Qwen/Qwen2.5-0.5B
PER_DEVICE_TRAIN_BATCH_SIZE=1
MAX_SEQ_LENGTH=128
GRADIENT_ACCUMULATION_STEPS=1

BF16=True
USE_LORA=False
LOAD_IN_4BIT=False
LOAD_IN_8BIT=False

USE_WANDB=True
WANDB_PROJECT=medalpaca-du4-calibration
WANDB_RUN_NAME="medAlpaca-1node-1gpu-${SLURM_JOB_ID}"
TAGS="1node,1gpu,$SLURM_JOB_PARTITION"

export CUDA_HOME=$HOME/bin/cuda-12.2
export PATH=$CUDA_HOME/bin:$PATH

export HF_HOME=$HOME/.cache/huggingface
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
    --gradient_accumulation_steps $GRADIENT_ACCUMULATION_STEPS \
    --load_in_4bit $LOAD_IN_4BIT \
    --load_in_8bit $LOAD_IN_8BIT \
    --bf16 $BF16 \
    --use_wandb $USE_WANDB \
    --wandb_project $WANDB_PROJECT \
    --wandb_run_name $WANDB_RUN_NAME \
    --wandb_tags $TAGS \