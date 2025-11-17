#!/bin/bash
# Bootstrap environment for finetuning benchmarks

# uv
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1
fi

# medAlpaca
if [ -d "medAlpaca" ]; then
  cd medAlpaca
  git fetch && git pull
else
  # git clone --depth=1 --branch reproducible https://github.com/flrntdfr/medAlpaca.git
  git clone --depth=1 --branch fastDP https://github.com/flrntdfr/medAlpaca.git # FIXME
  cd medAlpaca
  uv venv --prompt medAlapaca --python 3.10.8
fi

source .venv/bin/activate
uv pip install -r requirements.txt
cd ..

# Get credentials from .env file
pwd
set -a
source "../.env"
set +a

#export HF_HOME=$HOME/.cache/huggingface
export HF_HOME=/dss/dssfs04/pn72ka/pn72ka-dss-0000/di67pif/.cache/huggingface # FIXME

# HuggingFace
## For now
export HF_TOKEN="${HF_TOKEN}"
## For later
hf auth login --token "${HF_TOKEN}"

# Weights and biases
## For now
export WANDB_API_KEY="${WANDB_API_KEY}"
## For later
wandb login "${WANDB_API_KEY}"

# Let's already download the model we will use in the benchmarks
hf download meta-llama/Llama-2-7b-hf