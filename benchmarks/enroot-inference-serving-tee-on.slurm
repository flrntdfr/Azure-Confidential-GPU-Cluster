#!/bin/bash
#SBATCH --job-name=vLLM-serving
#SBATCH --partition=TEE-ON
#SBATCH --container-image="docker://vllm/vllm-openai:v0.9.1"
#SBATCH --container-mount-home
#SBATCH --ntasks=40
#SBATCH --gres=gpu:1
#SBATCH --time=00:30:00
#SBATCH --output=logs/vLLM-serving-on-%j.out
#SBATCH --error=logs/vLLM-serving-on-%j.err

# Install dependencies
uv pip install --link-mode=copy --system pandas datasets # According to Dockerfile line 86

# Log the environment
python3 /vllm-workspace/collect_env.py

# Start vLLM server in background
vllm serve NousResearch/Hermes-3-Llama-3.1-8B \
  --disable-log-requests \
  --seed 54940 &
SERVER_PID=$!
echo "→ Starting server with PID: $SERVER_PID"
sleep 60
echo "→ The server is warming up..."
sleep 60

# Download dataset
cd /vllm-workspace/benchmarks
if [ ! -f "ShareGPT_V3_unfiltered_cleaned_split.json" ]; then
    wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json
fi

# Run benchmark
python3 benchmark_serving.py \
  --backend vllm \
  --model NousResearch/Hermes-3-Llama-3.1-8B \
  --endpoint /v1/completions \
  --dataset-name sharegpt \
  --dataset-path ShareGPT_V3_unfiltered_cleaned_split.json \
  --num-prompts 10 \
  --seed 54940

# Stop the server
echo "→ Stopping vLLM server (PID: $SERVER_PID)..."
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null
echo "→ Server stopped."