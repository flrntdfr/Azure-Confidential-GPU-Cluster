#!/bin/bash
#SBATCH --job-name=medalpaca-1node-2gpu-zero2
#SBATCH --partition=test-v100x2
#SBATCH --qos=testing
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=18
#SBATCH --mem=0
#SBATCH --time=2:00:00
#SBATCH --output=../results/medalpaca-1node-2gpu-zero2-%j.out
#SBATCH --error=../results/medalpaca-1node-2gpu-zero2-%j.err

set -ex

MODEL=Qwen/Qwen2.5-0.5B
PER_DEVICE_TRAIN_BATCH_SIZE=1
MAX_SEQ_LENGTH=128
GRADIENT_ACCUMULATION_STEPS=1

BF16=True
USE_LORA=False
LOAD_IN_4BIT=False
LOAD_IN_8BIT=False

# Data Parallelism
DS_CONFIG=src/ds_config_zero2.json

USE_WANDB=True
WANDB_PROJECT=medalpaca-du4-calibration
WANDB_RUN_NAME="medAlpaca-1node-2gpu-zero2-${SLURM_JOB_ID}"
TAGS="1node,2gpus,zero2"

export CUDA_HOME=$HOME/bin/cuda-12.2
export PATH=$CUDA_HOME/bin:$PATH

export HF_HOME=$HOME/.cache/huggingface
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-40}"

cd $HOME/Azure-Confidential-GPU-Cluster/benchmarks/finetuning
mkdir -p ./results
source .venv/bin/activate

echo "Starting DeepSpeed training on Single Node..."

deepspeed src/train.py \
    --model $MODEL \
    --deepspeed $DS_CONFIG \
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
    --wandb_tags $TAGS
