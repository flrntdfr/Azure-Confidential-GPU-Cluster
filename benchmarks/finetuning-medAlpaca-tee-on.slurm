#!/bin/bash
#SBATCH --job-name=medalpaca
#SBATCH --partition=TEE-ON
#SBATCH --container-image="docker://ghcr.io#flrntdfr/medalpaca:latest"
#SBATCH --container-mount-home
#SBATCH --gres=gpu:1
#SBATCH --time=01:00:00
#SBATCH --output=medAlpaca-on-%j.out
#SBATCH --error=medAlpaca-on-%j.err

export OMP_NUM_THREADS=40

# WANDB
WANDB_PROJECT="medalpaca"
WANDB_RUN_NAME="medAlpaca-on-$SLURM_JOB_ID"

# Parameters
NPROC_PER_NODE=1
MASTER_PORT=9876
TRAIN_IN_8BIT=True
USE_LORA=True
FP16=True
BF16=False
TF32=False
GRADIENT_CHECKPOINTING=False
GLOBAL_BATCH_SIZE=256
PER_DEVICE_BATCH_SIZE=4

source .venv/bin/activate
torchrun --nproc_per_node=$NPROC_PER_NODE --master_port=$MASTER_PORT medalpaca/train.py \
    --model meta-llama/Llama-2-7b-hf \
    --data_path /app/medical_meadow_small.json \
    --prompt_template /app/medalpaca/prompt_templates/medalpaca.json \
    --output_dir /app/models/lora-alpaca-7b \
    --train_in_8bit $TRAIN_IN_8BIT \
    --use_lora $USE_LORA \
    --fp16 $FP16 \
    --bf16 $BF16 \
    --tf32 $TF32 \
    --gradient_checkpointing $GRADIENT_CHECKPOINTING \
    --global_batch_size $GLOBAL_BATCH_SIZE \
    --per_device_batch_size $PER_DEVICE_BATCH_SIZE \
    --wandb_project ${WANDB_PROJECT} \
    --wandb_run_name ${WANDB_RUN_NAME} \
    --use_wandb True