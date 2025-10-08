#!/bin/bash
#SBATCH --job-name=medalpaca-singlenode-test-v100x2-lora-bf16-pbs4-run1
#SBATCH --partition=test-v100x2         # Specify partition name
#SBATCH --qos=testing
#SBATCH --nodes=1                     # Single node
#SBATCH --ntasks-per-node=1           # One task per node
#SBATCH --gres=gpu:1                  # GPUs per node
#SBATCH --cpus-per-task=16            # CPUs per task
#SBATCH --mem=0                       # Use entire memory of node
#SBATCH --exclusive                   # Do not share nodes
#SBATCH --time=2:00:00                # Maximum run time
#SBATCH --output=logs/medalpaca-%j.out
#SBATCH --error=logs/medalpaca-%j.err

# Exit on error
set -e

# Print job information
echo "=========================================="
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


# Set HuggingFace cache directory (recommended for large models)
export HF_HOME=$HOME/.cache/huggingface

# Configure distributed training environment
export MASTER_PORT="${MASTER_PORT:-29500}"
export NPROC_PER_NODE="${NPROC_PER_NODE:-$SLURM_GPUS_ON_NODE}"

# Training parameters (can be overridden via command line or environment)
MODEL="${MODEL:-meta-llama/Llama-2-7b-hf}"
DATA_PATH="${DATA_PATH:-./medical_meadow_small.json}"
OUTPUT_DIR="${OUTPUT_DIR:-./output-lrz-hgx-h100-94x4-lora-bf16-pbs4-run1-${SLURM_JOB_ID}}"
PROMPT_TEMPLATE="${PROMPT_TEMPLATE:-./medalpaca/prompt_templates/medalpaca.json}"

TRAIN_IN_8BIT="${TRAIN_IN_8BIT:-False}"
USE_LORA="${USE_LORA:-True}"
FP16="${FP16:-False}"
BF16="${BF16:-True}"

GRADIENT_CHECKPOINTING="${GRADIENT_CHECKPOINTING:-False}"
GLOBAL_BATCH_SIZE="${GLOBAL_BATCH_SIZE:-256}"
PER_DEVICE_BATCH_SIZE="${PER_DEVICE_BATCH_SIZE:-4}"

USE_WANDB="${USE_WANDB:-True}"
WANDB_PROJECT="${WANDB_PROJECT:-medalpaca}"
WANDB_RUN_NAME="${WANDB_RUN_NAME:-medAlpaca-singlenode-lrz-hgx-h100-94x4-lora-bf16-pbs4-run1-${SLURM_JOB_ID}}"
WANDB_TAGS="${WANDB_TAGS:-lrz-hgx-h100-94x4,lora-bf16,pbs4,run1}"
JOB_PARTITION="${JOB_PARTITION:-lrz-hgx-h100-94x4}"
JOB_SUFFIX="${JOB_SUFFIX:-lora-bf16-pbs4-run1}"

echo "=========================================="
echo "Training Configuration"
echo "=========================================="
echo "Master port: $MASTER_PORT"
echo "Processes per node: $NPROC_PER_NODE"
echo "Model: $MODEL"
echo "Data path: $DATA_PATH"
echo "Output directory: $OUTPUT_DIR"
echo "Global batch size: $GLOBAL_BATCH_SIZE"
echo "Per device batch size: $PER_DEVICE_BATCH_SIZE"
echo "=========================================="

# ========================================
# Training Execution
# ========================================

cd $HOME/Azure-Confidential-GPU-Cluster/benchmarks/finetuning/medAlpaca
#mkdir -p /persistent/logs
source .venv/bin/activate

# Set WANDB environment variables
export WANDB_TAGS="$WANDB_TAGS"
export WANDB_NOTES="Partition: ${JOB_PARTITION}, Config: ${JOB_SUFFIX}"

echo "Starting training..."
torchrun --nproc_per_node=$NPROC_PER_NODE --master_port=$MASTER_PORT medalpaca/train.py \
    --model "$MODEL" \
    --data_path "$DATA_PATH" \
    --prompt_template "$PROMPT_TEMPLATE" \
    --output_dir "$OUTPUT_DIR" \
    --train_in_8bit $TRAIN_IN_8BIT \
    --use_lora $USE_LORA \
    --fp16 $FP16 \
    --bf16 $BF16 \
    --gradient_checkpointing $GRADIENT_CHECKPOINTING \
    --global_batch_size $GLOBAL_BATCH_SIZE \
    --per_device_batch_size $PER_DEVICE_BATCH_SIZE \
    --wandb_project "$WANDB_PROJECT" \
    --wandb_run_name "$WANDB_RUN_NAME" \
    --use_wandb $USE_WANDB \
    --wandb_tags "$WANDB_TAGS" \
    --wandb_notes "Partition: ${JOB_PARTITION}, Config: ${JOB_SUFFIX}"

echo "=========================================="
echo "Training completed successfully!"
echo "Output saved to: $OUTPUT_DIR"
echo "=========================================="