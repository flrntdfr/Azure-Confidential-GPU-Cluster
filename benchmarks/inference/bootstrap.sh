#!/bin/bash
# Bootstrap environment for inference benchmarks

# uv
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1
fi

# vLLM
if [ ! -d ".venv" ]; then
  uv venv --prompt vllm --python 3.12
fi
source .venv/bin/activate
uv pip install vllm==0.11.0 huggingface-hub==0.35.3 tqdm==4.67.1

# Get credentials from .env file
set -a
source "../.env"
set +a

#export HF_HOME=$HOME/.cache/huggingface FIXME
export HF_HOME=/dss/dssfs04/pn72ka/pn72ka-dss-0000/di67pif/.cache/huggingface

# HuggingFace
## For now
export HF_TOKEN="${HF_TOKEN}"
## For later
hf auth login --token "${HF_TOKEN}"

for model in \
    google/gemma-3-1b-it \
    meta-llama/Llama-3.1-8B-Instruct \
    mistralai/Mistral-Small-24B-Instruct-2501 \
    Qwen/Qwen3-32B \
    deepseek-ai/DeepSeek-R1-Distill-Qwen-32B \
    deepseek-ai/DeepSeek-R1-Distill-Qwen-14B \
    deepseek-ai/DeepSeek-R1-Distill-Qwen-7B \
    deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B
do
    hf download "$model"
done