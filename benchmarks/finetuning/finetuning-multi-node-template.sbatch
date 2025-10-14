#!/bin/bash
#SBATCH --job-name=medalpaca-multinode
#SBATCH --partition=partition         # Specify partition name
#SBATCH --nodes=2                     # Number of nodes to allocate
#SBATCH --ntasks-per-node=1           # One task per node (torchrun will handle GPU processes)
#SBATCH --gres=gpu:1                  # GPUs per node
#SBATCH --cpus-per-task=40            # CPUs per task
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


# Set HuggingFace cache directory
export HF_HOME=$HOME/.cache/huggingface

# PyTorch
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Configure distributed training environment
export MASTER_ADDR=$(scontrol show hostname $SLURM_NODELIST | head -n 1)
export MASTER_PORT=29500
export WORLD_SIZE=$((SLURM_JOB_NUM_NODES * SLURM_GPUS_ON_NODE))

# Training parameters
MODEL="${MODEL:-meta-llama/Llama-2-7b-hf}"
DATA_PATH="${DATA_PATH:-./medical_meadow_max.json}"
OUTPUT_DIR="${OUTPUT_DIR:-./output-multinode-${SLURM_JOB_ID}}"
PROMPT_TEMPLATE="${PROMPT_TEMPLATE:-./medalpaca/prompt_templates/medalpaca.json}"

TRAIN_IN_8BIT="${TRAIN_IN_8BIT:-True}"
USE_LORA="${USE_LORA:-True}"
FP16="${FP16:-True}"
BF16="${BF16:-False}"

GRADIENT_CHECKPOINTING="${GRADIENT_CHECKPOINTING:-False}"
GLOBAL_BATCH_SIZE="${GLOBAL_BATCH_SIZE:-256}"
PER_DEVICE_BATCH_SIZE="${PER_DEVICE_BATCH_SIZE:-4}"

USE_WANDB="${USE_WANDB:-True}"
WANDB_PROJECT="${WANDB_PROJECT:-medalpaca}"
WANDB_RUN_NAME="${WANDB_RUN_NAME:-medAlpaca-multinode-${SLURM_JOB_ID}}"

echo "=========================================="
echo "Training Configuration"
echo "=========================================="
echo "Master address: $MASTER_ADDR"
echo "Master port: $MASTER_PORT"
echo "World size: $WORLD_SIZE"
echo "Model: $MODEL"
echo "Data path: $DATA_PATH"
echo "Output directory: $OUTPUT_DIR"
echo "Prompt template: $PROMPT_TEMPLATE"
echo "Train in 8bit: $TRAIN_IN_8BIT"
echo "Use LoRA: $USE_LORA"
echo "FP16: $FP16"
echo "BF16: $BF16"
echo "Gradient checkpointing: $GRADIENT_CHECKPOINTING"
echo "Global batch size: $GLOBAL_BATCH_SIZE"
echo "Per device batch size: $PER_DEVICE_BATCH_SIZE"
echo "Use WANDB: $USE_WANDB"
echo "WANDB project: $WANDB_PROJECT"
echo "WANDB run name: $WANDB_RUN_NAME"
echo "=========================================="

# ========================================
# Training Execution
# ========================================

cd $HOME/Azure-Confidential-GPU-Cluster/benchmarks/finetuning/medAlpaca
mkdir -p ./logs
source .venv/bin/activate

export WANDB_TAGS="$WANDB_TAGS"
export WANDB_NOTES="Partition: ${JOB_PARTITION}, Config: ${JOB_SUFFIX}"

# Launch multi-node training using srun + torchrun
# Each node runs torchrun which spawns multiple GPU processes
srun torchrun \
    --nnodes=$SLURM_JOB_NUM_NODES \
    --nproc_per_node=$SLURM_GPUS_ON_NODE \
    --node_rank=$SLURM_NODEID \
    --master_addr=$MASTER_ADDR \
    --master_port=$MASTER_PORT \
    medalpaca/train.py \
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