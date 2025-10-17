#!/bin/bash
# Bootstrap environment for inference benchmarks

set -euo pipefail

uv venv --prompt vllm --python 3.12
source .venv/bin/activate
uv pip install vllm==0.11.0 huggingface-hub==0.35.3 tqdm==4.67.1

export HF_HOME=$HOME/.cache/huggingface

for model in \
    meta-llama/Llama-3.1-8B-Instruct \
    Qwen/Qwen3-32B \
    deepseek-ai/DeepSeek-R1-Distill-Llama-70B
do
    hf download "$model"
done