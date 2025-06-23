#!/bin/bash
#SBATCH --job-name=vLLM-throughput
#SBATCH --partition=TEE-ON
#SBATCH --container-image="docker://vllm/vllm-openai:v0.9.1"
#SBATCH --container-mount-home
#SBATCH --gres=gpu:1
#SBATCH --time=01:00:00
#SBATCH --output=logs/vLLM-throughput-on-%j.out
#SBATCH --error=logs/vLLM-throughput-on-%j.err

# Install dependencies
uv pip install --link-mode=copy --system pandas datasets # According to Dockerfile line 86

# Log the environment
python3 /vllm-workspace/collect_env.py

# Run benchmark
cd /vllm-workspace/benchmarks
python3 benchmark_throughput.py \
  --model NousResearch/Hermes-3-Llama-3.1-8B \
  --dataset-name sonnet \
  --dataset-path ./sonnet.txt \
  --num-prompts 10