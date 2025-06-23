#!/bin/bash
#SBATCH --job-name=vLLM-serving
#SBATCH --partition=TEE-ON
#SBATCH --container-image="docker://vllm/vllm-openai:v0.9.1"
#SBATCH --container-mounts=/shared/models:/app/models # FIXME
#SBATCH --gres=gpu:1
#SBATCH --time=04:00:00
#SBATCH --output=vLLM-serving-on-%j.out
#SBATCH --error=vLLM-serving-on-%j.err

# FIXME hf cache

vllm serve NousResearch/Hermes-3-Llama-3.1-8B --disable-log-requests

cd /vllm-workspace/benchmarks
wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json

python3 benchmark_serving.py \
  --backend vllm \
  --model NousResearch/Hermes-3-Llama-3.1-8B \
  --endpoint /v1/completions \
  --dataset-name sharegpt \
  --dataset-path ShareGPT_V3_unfiltered_cleaned_split.json \
  --num-prompts 100 \
  --seed 54940

# TODO Stop serving