#!/usr/bin/env python3
"""
Experiment Submission Script for SLURM Batch Jobs
Generates and submits SLURM batch scripts with different parameter combinations.

Usage: python submit_experiments.py
"""

import os
import subprocess
from datetime import datetime
from pathlib import Path

# ========================================
# CONFIGURATION VARIABLES
# ========================================

# Control flags
DRY_RUN            = True    # If True, only print what would be submitted
SUBMIT_SINGLE_NODE = True    # Submit single-node jobs
SUBMIT_MULTI_NODE  = False   # Submit multi-node jobs
NUM_RUNS           = 5       # Number of runs per configuration

# Output directories
BASE_LOG_DIR = "./logs"                     # Base directory for logs and results
TEMP_SBATCH_DIR_PREFIX = "temp_sbatch"      # Prefix for temporary sbatch files directory
JOB_SUBMISSION_LOG = "job_submissions.log"  # Job submission tracking log

# Template files
SINGLE_NODE_TEMPLATE = "single-node-template.sbatch"
MULTI_NODE_TEMPLATE = "multi-node-template.sbatch"

# Partitions to test
PARTITIONS = {
    "TEE-ON": "tee-on",
    "TEE-OFF": "tee-off"
}

# Training configurations
# Format: (config_name, train_8bit, use_lora, fp16, bf16, description)
TRAINING_CONFIGS = [
    ("fp16", "False", "False", "True", "False", "Full precision FP16"),
    ("bf16", "False", "False", "False", "True", "Full precision BF16"),
    ("lora-fp16", "False", "True", "True", "False", "LoRA with FP16"),
    ("lora-fp16-8bit", "True", "True", "True", "False", "LoRA with FP16 and 8-bit quantization"),
]

# ========================================
# HELPER FUNCTIONS
# ========================================

def create_modified_sbatch(template_file, partition, config_name, train_8bit,
                          use_lora, fp16, bf16, run_number, output_file):
    """Create a modified sbatch file from template with given parameters."""

    # Read template file
    with open(template_file, 'r') as f:
        content = f.read()

    # Determine job type from template filename
    job_type = "singlenode" if "single-node" in template_file else "multinode"

    # Create job name
    job_name = f"medalpaca-{job_type}-{partition}-{config_name}-run{run_number}"

    # Replace partition placeholder
    content = content.replace("#SBATCH --partition=partition",
                             f"#SBATCH --partition={partition}")

    # Replace job name
    content = content.replace(f"#SBATCH --job-name=medalpaca-{job_type}",
                             f"#SBATCH --job-name={job_name}")

    # Replace training parameters
    content = content.replace('TRAIN_IN_8BIT="${TRAIN_IN_8BIT:-True}"',
                             f'TRAIN_IN_8BIT="${{TRAIN_IN_8BIT:-{train_8bit}}}"')
    content = content.replace('USE_LORA="${USE_LORA:-True}"',
                             f'USE_LORA="${{USE_LORA:-{use_lora}}}"')
    content = content.replace('FP16="${FP16:-True}"',
                             f'FP16="${{FP16:-{fp16}}}"')
    content = content.replace('BF16="${BF16:-False}"',
                             f'BF16="${{BF16:-{bf16}}}"')

    # Replace output directory
    output_dir = f"./output-{partition}-{config_name}-run{run_number}-${{SLURM_JOB_ID}}"
    if "singlenode" in job_type:
        content = content.replace('OUTPUT_DIR="${OUTPUT_DIR:-./lora-alpaca-7b}"',
                                 f'OUTPUT_DIR="${{OUTPUT_DIR:-{output_dir}}}"')
    else:
        content = content.replace('OUTPUT_DIR="${OUTPUT_DIR:-./output-multinode-${SLURM_JOB_ID}}"',
                                 f'OUTPUT_DIR="${{OUTPUT_DIR:-{output_dir}}}"')

    # Replace WANDB tags and run name
    wandb_run_name = f"medAlpaca-{job_type}-{partition}-{config_name}-run{run_number}-${{SLURM_JOB_ID}}"
    if "singlenode" in job_type:
        content = content.replace('WANDB_RUN_NAME="${WANDB_RUN_NAME:-medAlpaca-singlenode-${SLURM_JOB_ID}}"',
                                 f'WANDB_RUN_NAME="${{WANDB_RUN_NAME:-{wandb_run_name}}}"')
        content = content.replace('WANDB_TAGS="${WANDB_TAGS:-singlenode}"',
                                 f'WANDB_TAGS="${{WANDB_TAGS:-{partition},{config_name},run{run_number}}}"')
        content = content.replace('JOB_PARTITION="${JOB_PARTITION:-$SLURM_PARTITION}"',
                                 f'JOB_PARTITION="${{JOB_PARTITION:-{partition}}}"')
        content = content.replace('JOB_SUFFIX="${JOB_SUFFIX:-singlenode}"',
                                 f'JOB_SUFFIX="${{JOB_SUFFIX:-{config_name}-run{run_number}}}"')
    else:
        content = content.replace('WANDB_RUN_NAME="${WANDB_RUN_NAME:-medAlpaca-multinode-${SLURM_JOB_ID}}"',
                                 f'WANDB_RUN_NAME="${{WANDB_RUN_NAME:-{wandb_run_name}}}"')

    # Write modified file
    with open(output_file, 'w') as f:
        f.write(content)

    # Make executable
    os.chmod(output_file, 0o755)


def submit_job(sbatch_file, partition, config_name, job_type, run_number):
    """Submit a job to SLURM."""

    print(f"\n{'='*50}")
    print(f"Submitting: {job_type} with {config_name} on {partition} (run {run_number}/{NUM_RUNS})")
    print(f"File: {sbatch_file}")

    if DRY_RUN:
        print(f"[DRY RUN] Would submit: sbatch {sbatch_file}")
        print("[DRY RUN] First 20 lines of modified file:")
        with open(sbatch_file, 'r') as f:
            for i, line in enumerate(f):
                if i >= 20:
                    break
                print(line.rstrip())
        return None
    else:
        try:
            result = subprocess.run(['sbatch', sbatch_file],
                                   capture_output=True,
                                   text=True,
                                   check=True)
            # Extract job ID from output (format: "Submitted batch job 12345")
            job_id = result.stdout.strip().split()[-1]
            print(f"Submitted job ID: {job_id}")
            return job_id
        except subprocess.CalledProcessError as e:
            print(f"Error submitting job: {e}")
            print(f"Output: {e.output}")
            return None


def print_config_table():
    """Print configuration summary."""
    print("\n" + "="*60)
    print("Configuration Summary")
    print("="*60)

    print("\nPartitions:")
    print("-" * 40)
    for name, value in PARTITIONS.items():
        print(f"  {name:15s} -> {value}")

    print("\nTraining Configurations:")
    print("-" * 40)
    print(f"{'Config Name':<20} {'8BIT':<6} {'LoRA':<6} {'FP16':<6} {'BF16':<6}")
    print("-" * 40)
    for config_name, train_8bit, use_lora, fp16, bf16, _ in TRAINING_CONFIGS:
        print(f"{config_name:<20} {train_8bit:<6} {use_lora:<6} {fp16:<6} {bf16:<6}")

    print(f"\nRuns per configuration: {NUM_RUNS}")
    print()


# ========================================
# MAIN EXECUTION
# ========================================

def main():
    """Main execution function."""

    # Print configuration
    print_config_table()

    # Create base log directory
    base_log_path = Path(BASE_LOG_DIR)
    base_log_path.mkdir(parents=True, exist_ok=True)

    # Create temporary directory for modified sbatch files
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    temp_dir = base_log_path / f"{TEMP_SBATCH_DIR_PREFIX}_{timestamp}"
    temp_dir.mkdir(exist_ok=True)

    # Initialize job submission log
    log_file = base_log_path / JOB_SUBMISSION_LOG
    if not DRY_RUN:
        with open(log_file, 'w') as f:
            f.write(f"# Job submissions log - {datetime.now()}\n")
            f.write("# JobID|Partition|Config|JobType|Run|SubmissionTime\n")

    print("\n" + "="*60)
    print("Starting Experiment Submissions")
    print("="*60)
    print(f"Dry run: {DRY_RUN}")
    print(f"Submit single node: {SUBMIT_SINGLE_NODE}")
    print(f"Submit multi node: {SUBMIT_MULTI_NODE}")
    print(f"Number of runs per config: {NUM_RUNS}")
    print(f"Temp directory: {temp_dir}")
    print()

    # Calculate total expected submissions
    total_configs = len(TRAINING_CONFIGS)
    total_partitions = len(PARTITIONS)
    total_job_types = sum([SUBMIT_SINGLE_NODE, SUBMIT_MULTI_NODE])
    total_expected = total_configs * total_partitions * total_job_types * NUM_RUNS

    print(f"Expected total submissions: {total_expected}")
    print(f"  - Partitions: {total_partitions}")
    print(f"  - Configs: {total_configs}")
    print(f"  - Job types: {total_job_types}")
    print(f"  - Runs per config: {NUM_RUNS}")
    print()

    # Track submission count
    submission_count = 0

    # Iterate over all combinations
    for partition_name, partition_value in PARTITIONS.items():
        for config_name, train_8bit, use_lora, fp16, bf16, description in TRAINING_CONFIGS:
            for run in range(1, NUM_RUNS + 1):

                # Submit single-node jobs
                if SUBMIT_SINGLE_NODE and Path(SINGLE_NODE_TEMPLATE).exists():
                    output_file = temp_dir / f"singlenode-{partition_value}-{config_name}-run{run}.sbatch"

                    create_modified_sbatch(
                        SINGLE_NODE_TEMPLATE,
                        partition_value,
                        config_name,
                        train_8bit,
                        use_lora,
                        fp16,
                        bf16,
                        run,
                        str(output_file)
                    )

                    job_id = submit_job(str(output_file), partition_value, config_name, "singlenode", run)

                    if job_id and not DRY_RUN:
                        with open(log_file, 'a') as f:
                            timestamp = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
                            f.write(f"{job_id}|{partition_value}|{config_name}|singlenode|run{run}|{timestamp}\n")

                    submission_count += 1

                # Submit multi-node jobs
                if SUBMIT_MULTI_NODE and Path(MULTI_NODE_TEMPLATE).exists():
                    output_file = temp_dir / f"multinode-{partition_value}-{config_name}-run{run}.sbatch"

                    create_modified_sbatch(
                        MULTI_NODE_TEMPLATE,
                        partition_value,
                        config_name,
                        train_8bit,
                        use_lora,
                        fp16,
                        bf16,
                        run,
                        str(output_file)
                    )

                    job_id = submit_job(str(output_file), partition_value, config_name, "multinode", run)

                    if job_id and not DRY_RUN:
                        with open(log_file, 'a') as f:
                            timestamp = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
                            f.write(f"{job_id}|{partition_value}|{config_name}|multinode|run{run}|{timestamp}\n")

                    submission_count += 1

    # Print summary
    print("\n" + "="*60)
    print("Submission Summary")
    print("="*60)
    print(f"Total jobs submitted: {submission_count} (expected: {total_expected})")
    print(f"Base log directory: {base_log_path}")
    print(f"Modified sbatch files saved in: {temp_dir}")

    if not DRY_RUN:
        print(f"Job tracking log: {log_file}")
        print("\nTo check job status, run:")
        print("\nTo check job status for this batch:")
        print("  squeue -u $USER")
        print(f"  tail -n {submission_count} {log_file}")
        print("\nTo cancel all jobs, run:")
        print("  scancel -u $USER")

    print("\n" + "="*60)
    print("Done!")
    print("="*60)


if __name__ == "__main__":
    main()