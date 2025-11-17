#!/bin/bash
#SBATCH --job-name=medalpaca-singlenode
#SBATCH --partition=lrz-hgx-h100-94x4 # Specify partition name
#SBATCH --nodes=1                     # Single node
#SBATCH --ntasks-per-node=1           # One task per node
#SBATCH --gres=gpu:1                  # GPUs per node
#SBATCH --cpus-per-task=40            # CPUs per task
#SBATCH --mem=0                       # Use entire memory of node
#SBATCH --time=1:00:00                # Maximum run time
#SBATCH --output=results/medalpaca-singlenode-%j.out
#SBATCH --error=results/medalpaca-singlenode-%j.err

# Exit on error
set -e

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

# Model and data
MODEL="meta-llama/Llama-2-7b-hf"
DATA_PATH="./medical_meadow_small.json"
OUTPUT_DIR="./lora-alpaca-7b"
PROMPT_TEMPLATE="./medalpaca/prompt_templates/medalpaca.json"

# Training parameters
TRAIN_IN_8BIT="False"
USE_LORA="False"
FP16="False"
BF16="True"
GRADIENT_CHECKPOINTING="False"
GLOBAL_BATCH_SIZE="256"
PER_DEVICE_BATCH_SIZE="4"

# wandb
USE_WANDB="True"
WANDB_PROJECT="medalpaca-BitFit-calibration"
WANDB_RUN_NAME="medAlpaca-singlenode-${SLURM_JOB_ID}"
JOB_PARTITION="$SLURM_JOB_PARTITION"
JOB_SUFFIX="singlenode"
TAGS=("singlenode")
[ "$TRAIN_IN_8BIT" = "True" ] && TAGS+=("8bit")
[ "$USE_LORA" = "True" ] && TAGS+=("lora")
[ "$FP16" = "True" ] && TAGS+=("fp16")
[ "$BF16" = "True" ] && TAGS+=("bf16")
[ "$GRADIENT_CHECKPOINTING" = "True" ] && TAGS+=("gradient_checkpointing")
TAGS+=("gbs-${GLOBAL_BATCH_SIZE}")
TAGS+=("pbs-${PER_DEVICE_BATCH_SIZE}")
TAGS+=("${JOB_PARTITION}")
WANDB_TAGS="${WANDB_TAGS:-$(IFS=,; echo "${TAGS[*]}")}"

echo -e "\n=========================================="
echo "Training Configuration"
echo "=========================================="
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
echo "WANDB tags: $WANDB_TAGS"
echo "=========================================="

cd $HOME/Azure-Confidential-GPU-Cluster/benchmarks/finetuning/medAlpaca
mkdir -p ./results
source .venv/bin/activate

echo -e "\nStarting training..."
python medalpaca/train.py \
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
echo -e "==========================================\n"