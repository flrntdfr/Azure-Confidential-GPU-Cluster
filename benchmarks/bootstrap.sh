#!/usr/bin/env bash
# Bootstrap base dependencies for benchmarks

set -euo pipefail

echo "Configuring HuggingFace and Weights & Biases…"
# Get credentials from .env file
set -a
source ".env"
set +a
# Configure HuggingFace token
mkdir -p "${HOME}/.huggingface"
echo "${HF_TOKEN}" > "${HOME}/.huggingface/token"
chmod 600 "${HOME}/.huggingface/token"
# Configure Weights & Biases credentials in .netrc
cat > "${HOME}/.netrc" <<EOF
machine api.wandb.ai
  login user
  password ${WANDB_TOKEN}
EOF
chmod 600 "${HOME}/.netrc"
echo "Installin uv…"
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1

echo "Bootstrap complete."
exit 0