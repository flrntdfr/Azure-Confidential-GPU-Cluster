#!/bin/bash
#SBATCH --job-name=medalpaca-two-nodes-two-gpus-zero2
#SBATCH --partition=lrz-hgx-h100-94x4
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:2
#SBATCH --time=2:00:00
#SBATCH --output=../results/medalpaca-two-nodes-two-gpus-zero2-%j.out
#SBATCH --error=../results/medalpaca-two-nodes-two-gpus-zero2-%j.err

set -eaux

MODEL=Qwen/Qwen2.5-0.5B
PER_DEVICE_TRAIN_BATCH_SIZE=1
MAX_SEQ_LENGTH=128
# Calculate gradient accumulation steps
NUM_GPUS=$((SLURM_JOB_NUM_NODES * 2))
GRADIENT_ACCUMULATION_STEPS=$((GLOBAL_BATCH_SIZE / (NUM_GPUS * PER_DEVICE_BATCH_SIZE)))

OUTPUT_DIR=./output-multinode-${SLURM_JOB_ID}


BF16=True
USE_LORA=False
LOAD_IN_4BIT=False
LOAD_IN_8BIT=False

USE_WANDB=True
WANDB_PROJECT=medalpaca-du4-calibration
WANDB_RUN_NAME="medAlpaca-two-nodes-two-gpus-zero2-${SLURM_JOB_ID}"
TAGS="2nodes,2gpus,$SLURM_JOB_PARTITION"

export HF_HOME=$HOME/.cache/huggingface
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

cd $HOME/Azure-Confidential-GPU-Cluster/benchmarks/finetuning
mkdir -p ./results
source .venv/bin/activate

# Add src to PYTHONPATH
export PYTHONPATH=$PYTHONPATH:$(pwd)/src

# Generate DeepSpeed Hostfile
GPUS_PER_NODE=2
HOSTFILE=./hostfile-${SLURM_JOB_ID}
scontrol show hostnames "$SLURM_JOB_NODELIST" | sed "s/$/ slots=$GPUS_PER_NODE/" > $HOSTFILE

echo "DeepSpeed Hostfile:"
cat $HOSTFILE

DS_CONFIG=src/ds_config_zero2.json

echo "Starting DeepSpeed training..."

deepspeed --hostfile $HOSTFILE src/train.py \
    --model $MODEL \
    --deepspeed $DS_CONFIG \
    --use_lora $USE_LORA \
    --load_in_8bit $LOAD_IN_8BIT \
    --fp16 $FP16 \
    --bf16 $BF16 \
    --per_device_train_batch_size $PER_DEVICE_TRAIN_BATCH_SIZE \
    --gradient_accumulation_steps $GRADIENT_ACCUMULATION_STEPS \
    --use_wandb $USE_WANDB \
    --wandb_project $WANDB_PROJECT \
    --wandb_run_name $WANDB_RUN_NAME \
    --wandb_tags $TAGS
