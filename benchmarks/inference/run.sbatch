#!/bin/bash
#SBATCH --job-name=vLLM-experiments
#SBATCH --partition=lrz-hgx-h100-94x4 # Specify partition name
#SBATCH --nodes=4                     # Number of nodes to allocate
#SBATCH --ntasks-per-node=1           # One task per node
#SBATCH --gres=gpu:4                  # Total GPUs needed for all experiments
#SBATCH --cpus-per-task=40            # CPUs per task
#SBATCH --mem=0                       # Use entire memory of node
#SBATCH --time=4:00:00                # Maximum run time
#SBATCH --output=results/all-experiments%j.out
#SBATCH --error=results/all-experiments%j.err

source ./bootstrap.sh

# Run all experiments in parallel
srun --nodes=1 --ntasks=1 --gres=gpu:1 experiment-1.sh &
srun --nodes=1 --ntasks=1 --gres=gpu:1 experiment-2.sh &
srun --nodes=1 --ntasks=1 --gres=gpu:1 experiment-3.sh &
srun --nodes=1 --ntasks=1 --gres=gpu:1 experiment-4.sh &

# Wait for all background jobs to complete
wait