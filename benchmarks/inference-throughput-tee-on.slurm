#!/bin/bash
#SBATCH --job-name=vLLM-throughput
#SBATCH --partition=TEE-ON
#SBATCH --container-image="docker://vllm/vllm-openai:v0.9.1"
#SBATCH --container-mounts=/shared/models:/app/models # FIXME
#SBATCH --gres=gpu:1
#SBATCH --time=04:00:00
#SBATCH --output=vLLM-throughput-on-%j.out
#SBATCH --error=vLLM-throughput-on-%j.err

# FIXME hf cache

uv pip install --system pandas datasets # According to layer 86
cd /vllm-workspace/benchmarks
python3 benchmark_throughput.py \
  --model NousResearch/Hermes-3-Llama-3.1-8B \
  --dataset-name sonnet \
  --dataset-path ./sonnet.txt \
  --num-prompts 10