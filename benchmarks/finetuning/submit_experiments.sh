#!/bin/bash

# ========================================
# Experiment Configuration Script
# ========================================
# This script automates the submission of SLURM batch jobs with different
# parameter combinations for fine-tuning experiments on TEE-ON and TEE-OFF partitions.
#
# Usage: ./submit_experiments.sh [--dry-run] [--single-node-only] [--multi-node-only]
#

set -e

# ========================================
# Configuration Tables
# ========================================

# Partition configurations
declare -A PARTITIONS=(
    ["TEE-ON"]="tee-on"
    ["TEE-OFF"]="tee-off"
)

# Training configurations: 8-bit quantization, LoRA, and precision
# Format: "CONFIG_NAME|8BIT|LORA|FP16|BF16|DESCRIPTION"
declare -a TRAINING_CONFIGS=(
    # Full precision configurations
    "full-fp16|False|False|True|False|Full precision FP16"
    "full-bf16|False|False|False|True|Full precision BF16"
    
    # LoRA configurations (without 8-bit)
    "lora-fp16|False|True|True|False|LoRA with FP16"
    "lora-bf16|False|True|False|True|LoRA with BF16"
    
    # 8-bit quantization with LoRA
    "8bit-lora-fp16|True|True|True|False|8-bit quantization with LoRA FP16"
    "8bit-lora-bf16|True|True|False|True|8-bit quantization with LoRA BF16"
    
    # 8-bit quantization without LoRA
    "8bit-fp16|True|False|True|False|8-bit quantization FP16"
    "8bit-bf16|True|False|False|True|8-bit quantization BF16"
)

# ========================================
# Command Line Arguments
# ========================================
DRY_RUN=false
SINGLE_NODE_ONLY=false
MULTI_NODE_ONLY=false
NUM_RUNS=5  # Default number of runs per configuration

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --single-node-only)
            SINGLE_NODE_ONLY=true
            shift
            ;;
        --multi-node-only)
            MULTI_NODE_ONLY=true
            shift
            ;;
        --runs)
            NUM_RUNS=$2
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--single-node-only] [--multi-node-only] [--runs N]"
            exit 1
            ;;
    esac
done

# Validate NUM_RUNS
if ! [[ "$NUM_RUNS" =~ ^[0-9]+$ ]] || [ "$NUM_RUNS" -lt 1 ]; then
    echo "Error: --runs must be a positive integer (got: $NUM_RUNS)"
    exit 1
fi

# ========================================
# Helper Functions
# ========================================

# Function to print formatted table
print_config_table() {
    echo ""
    echo "=========================================="
    echo "Configuration Tables"
    echo "=========================================="
    echo ""
    echo "Partitions:"
    echo "----------------------------------------"
    printf "%-15s | %-20s\n" "Name" "SLURM Partition"
    echo "----------------------------------------"
    for partition in "${!PARTITIONS[@]}"; do
        printf "%-15s | %-20s\n" "$partition" "${PARTITIONS[$partition]}"
    done
    echo ""
    
    echo "Training Configurations:"
    echo "----------------------------------------"
    printf "%-20s | %-5s | %-5s | %-4s | %-4s | %-30s\n" "Config Name" "8BIT" "LoRA" "FP16" "BF16" "Description"
    echo "----------------------------------------"
    for config in "${TRAINING_CONFIGS[@]}"; do
        IFS='|' read -r name bit8 lora fp16 bf16 desc <<< "$config"
        printf "%-20s | %-5s | %-5s | %-4s | %-4s | %-30s\n" "$name" "$bit8" "$lora" "$fp16" "$bf16" "$desc"
    done
    echo ""
    
    echo "Runs per configuration: $NUM_RUNS"
    echo ""
}

# Function to create modified sbatch file
create_modified_sbatch() {
    local template_file=$1
    local partition=$2
    local config_name=$3
    local train_8bit=$4
    local use_lora=$5
    local fp16=$6
    local bf16=$7
    local run_number=$8
    local output_file=$9
    
    # Read template and apply modifications
    cp "$template_file" "$output_file"
    
    # Update partition
    sed -i.bak "s|#SBATCH --partition=<PARTITION>|#SBATCH --partition=$partition|g" "$output_file"
    
    # Update job name to include configuration and run number
    local job_type=$(basename "$template_file" .sbatch)
    sed -i.bak "s|#SBATCH --job-name=.*|#SBATCH --job-name=${job_type}-${partition}-${config_name}-run${run_number}|g" "$output_file"
    
    # Update training parameters
    sed -i.bak "s|TRAIN_IN_8BIT=.*|TRAIN_IN_8BIT=\"${train_8bit}\"|g" "$output_file"
    sed -i.bak "s|USE_LORA=.*|USE_LORA=\"${use_lora}\"|g" "$output_file"
    sed -i.bak "s|FP16=.*|FP16=\"${fp16}\"|g" "$output_file"
    sed -i.bak "s|BF16=.*|BF16=\"${bf16}\"|g" "$output_file"
    
    # Update output directory with run number
    local timestamp=$(date +%Y%m%d_%H%M%S)
    sed -i.bak "s|OUTPUT_DIR=.*|OUTPUT_DIR=\"./output-${partition}-${config_name}-run${run_number}-\${SLURM_JOB_ID}\"|g" "$output_file"
    
    # Update WANDB tags and run name with run number
    sed -i.bak "s|WANDB_TAGS=.*|WANDB_TAGS=\"${partition},${config_name},run${run_number}\"|g" "$output_file"
    sed -i.bak "s|WANDB_RUN_NAME=.*|WANDB_RUN_NAME=\"medAlpaca-${job_type}-${partition}-${config_name}-run${run_number}-\${SLURM_JOB_ID}\"|g" "$output_file"
    sed -i.bak "s|JOB_PARTITION=.*|JOB_PARTITION=\"${partition}\"|g" "$output_file"
    sed -i.bak "s|JOB_SUFFIX=.*|JOB_SUFFIX=\"${config_name}-run${run_number}\"|g" "$output_file"
    
    # Clean up backup files
    rm -f "${output_file}.bak"
}

# Function to submit job
submit_job() {
    local sbatch_file=$1
    local partition=$2
    local config_name=$3
    local job_type=$4
    local run_number=$5
    
    echo ""
    echo "----------------------------------------"
    echo "Submitting: $job_type with $config_name on $partition (run $run_number/$NUM_RUNS)"
    echo "File: $sbatch_file"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would submit: sbatch $sbatch_file"
        echo "[DRY RUN] First 20 lines of modified file:"
        head -n 20 "$sbatch_file"
    else
        local job_id=$(sbatch "$sbatch_file" | awk '{print $4}')
        echo "Submitted job ID: $job_id"
        # Store job ID for tracking
        echo "${job_id}|${partition}|${config_name}|${job_type}|run${run_number}|$(date +%Y-%m-%d_%H:%M:%S)" >> job_submissions.log
    fi
}

# ========================================
# Main Execution
# ========================================

# Print configuration tables
print_config_table

# Create temporary directory for modified sbatch files
TEMP_DIR="./temp_sbatch_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEMP_DIR"
mkdir -p logs

# Initialize job submission log
if [ "$DRY_RUN" = false ]; then
    echo "# Job submissions log - $(date)" > job_submissions.log
    echo "# JobID|Partition|Config|JobType|Run|SubmissionTime" >> job_submissions.log
fi

echo ""
echo "=========================================="
echo "Starting Experiment Submissions"
echo "=========================================="
echo "Dry run: $DRY_RUN"
echo "Single node only: $SINGLE_NODE_ONLY"
echo "Multi node only: $MULTI_NODE_ONLY"
echo "Number of runs per config: $NUM_RUNS"
echo "Temp directory: $TEMP_DIR"
echo ""

# Track submission count
SUBMISSION_COUNT=0

# Calculate total expected submissions
TOTAL_CONFIGS=${#TRAINING_CONFIGS[@]}
TOTAL_PARTITIONS=${#PARTITIONS[@]}
TOTAL_JOB_TYPES=0
[ "$MULTI_NODE_ONLY" = false ] && ((TOTAL_JOB_TYPES++))
[ "$SINGLE_NODE_ONLY" = false ] && ((TOTAL_JOB_TYPES++))
TOTAL_EXPECTED=$((TOTAL_CONFIGS * TOTAL_PARTITIONS * TOTAL_JOB_TYPES * NUM_RUNS))

echo "Expected total submissions: $TOTAL_EXPECTED"
echo "  - Partitions: $TOTAL_PARTITIONS"
echo "  - Configs: $TOTAL_CONFIGS"
echo "  - Job types: $TOTAL_JOB_TYPES"
echo "  - Runs per config: $NUM_RUNS"
echo ""

# Iterate over partitions and configurations
for partition_name in "${!PARTITIONS[@]}"; do
    partition="${PARTITIONS[$partition_name]}"
    
    for config in "${TRAINING_CONFIGS[@]}"; do
        IFS='|' read -r config_name train_8bit use_lora fp16 bf16 description <<< "$config"
        
        # Iterate over runs
        for ((run=1; run<=NUM_RUNS; run++)); do
            # Submit single-node jobs
            if [ "$MULTI_NODE_ONLY" = false ]; then
                if [ -f "finetuning-single-node.sbatch" ]; then
                    output_file="${TEMP_DIR}/singlenode-${partition}-${config_name}-run${run}.sbatch"
                    create_modified_sbatch \
                        "finetuning-single-node.sbatch" \
                        "$partition" \
                        "$config_name" \
                        "$train_8bit" \
                        "$use_lora" \
                        "$fp16" \
                        "$bf16" \
                        "$run" \
                        "$output_file"
                    
                    submit_job "$output_file" "$partition" "$config_name" "singlenode" "$run"
                    ((SUBMISSION_COUNT++))
                    
                    # Add delay to avoid overwhelming the scheduler
                    sleep 0.5
                fi
            fi
            
            # Submit multi-node jobs
            if [ "$SINGLE_NODE_ONLY" = false ]; then
                if [ -f "finetuning-multi-node.sbatch" ]; then
                    output_file="${TEMP_DIR}/multinode-${partition}-${config_name}-run${run}.sbatch"
                    create_modified_sbatch \
                        "finetuning-multi-node.sbatch" \
                        "$partition" \
                        "$config_name" \
                        "$train_8bit" \
                        "$use_lora" \
                        "$fp16" \
                        "$bf16" \
                        "$run" \
                        "$output_file"
                    
                    submit_job "$output_file" "$partition" "$config_name" "multinode" "$run"
                    ((SUBMISSION_COUNT++))
                    
                    # Add delay to avoid overwhelming the scheduler
                    sleep 0.5
                fi
            fi
        done
    done
done

echo ""
echo "=========================================="
echo "Submission Summary"
echo "=========================================="
echo "Total jobs submitted: $SUBMISSION_COUNT (expected: $TOTAL_EXPECTED)"
echo "Modified sbatch files saved in: $TEMP_DIR"

if [ "$DRY_RUN" = false ]; then
    echo "Job tracking log: job_submissions.log"
    echo ""
    echo "To check job status, run:"
    echo "  squeue -u \$USER"
    echo ""
    echo "To check job status for this batch:"
    echo "  tail -n $SUBMISSION_COUNT job_submissions.log"
    echo ""
    echo "To cancel all jobs, run:"
    echo "  scancel -u \$USER"
fi

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="

