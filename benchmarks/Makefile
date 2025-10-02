# Florent Dufour
# 2025 - MUC
# Run and submit benchmarks

HF_TOKEN    = hf_xxx
WANDB_TOKEN = xxx

bootstrap-base: ## Bootstrap base dependencies
	mkdir -p ~/.huggingface
	echo "$(HF_TOKEN)" > ~/.huggingface/token
	echo -e "machine api.wandb.ai\n  login user\n  password $(WANDB_TOKEN)" > ~/.netrc
	curl -LsSf https://astral.sh/uv/install.sh | sh

bootstrap-medAlpaca: ## Bootstrap medAlpaca
	cd $HOME
	git clone --depth=1 --branch reproducible https://github.com/flrntdfr/medAlpaca.git
	cd medAlpaca
	uv venv --prompt medAlapaca --python 3.10.8
	source .venv/bin/activate
	uv pip install -r requirements.txt

bootstrap-vllm: ## Bootstrap vllm
	mkdir -p $HOME/vllm && cd $_
	uv venv --prompt vllm --python 3.12
	source .venv/bin/activate
	uv pip install vllm wandb