#!/bin/bash
#SBATCH --job-name=medalpaca
#SBATCH --partition=TEE-OFF
#SBATCH --container-image="docker://ghcr.io#flrntdfr/medalpaca:latest"
#SBATCH --container-mounts=/shared/models:/app/models # FIXME HF model instead
#SBATCH --gres=gpu:1
#SBATCH --time=04:00:00
#SBATCH --output=medAlpaca-off-%j.out
#SBATCH --error=medAlpaca-off-%j.err

# FIXME: HF cache

export OMP_NUM_THREADS=40
NPROC_PER_NODE=1
MASTER_PORT=9876

# WANDB
WANDB_PROJECT="medalpaca"
WANDB_RUN_NAME="medAlpaca-off-$SLURM_JOB_ID"

source .venv/bin/activate
torchrun --nproc_per_node=$NPROC_PER_NODE --master_port=$MASTER_PORT medalpaca/train.py \
    --model /app/models/Llama-2-7b-hf \
    --data_path /app/medical_meadow_small.json \
    --prompt_template /app/medalpaca/prompt_templates/medalpaca.json \
    --output_dir /app/models/lora-alpaca-7b \
    --train_in_8bit True \
    --use_lora True\
    --fp16 True \
    --bf16 False \
    --tf32 False \
    --gradient_checkpointing False \
    --global_batch_size 256 \
    --per_device_batch_size 4 \
    --wandb_project ${WANDB_PROJECT} \
    --wandb_run_name ${WANDB_RUN_NAME} \
    --use_wandb True