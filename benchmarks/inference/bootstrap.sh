#!/bin/bash
# Bootstrap environment for inference benchmarks

# uv
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1
fi

# vLLM
uv venv --prompt vllm --python 3.12
source .venv/bin/activate
uv pip install vllm==0.11.0 huggingface-hub==0.35.3 tqdm==4.67.1

# Get credentials from .env file
set -a
source "../env"
set +a

#export HF_HOME=$HOME/.cache/huggingface FIXME
export HF_HOME=/dss/dsshome1/lxc00/di67pif/dssfs04/.cache/huggingface

# HuggingFace
## For now
export HF_TOKEN="${HF_TOKEN}"
## For later
hf auth login --token "${HF_TOKEN}"

for model in \
    google/gemma-3-1b-it \
    meta-llama/Llama-3.1-8B-Instruct \
    Qwen/Qwen3-32B \
    deepseek-ai/DeepSeek-R1-Distill-Llama-70B
do
    hf download "$model"
done