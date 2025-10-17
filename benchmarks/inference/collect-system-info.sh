#!/bin/bash
# Collect comprehensive system information for benchmark documentation
# Run before each benchmark: ./collect-system-info.sh <experiment_name>

EXPERIMENT_NAME=${1:-"unknown"}
OUTPUT_FILE="system_info_${EXPERIMENT_NAME}.txt"

echo "Collecting system information for: ${EXPERIMENT_NAME}"
echo "Output file: ${OUTPUT_FILE}"

{
    echo "======================================"
    echo "SYSTEM INFORMATION FOR GPU BENCHMARK"
    echo "======================================"
    echo ""
    echo "Experiment: ${EXPERIMENT_NAME}"
    echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Hostname: $(hostname)"
    echo ""
    
    echo "=== GPU INFORMATION ==="
    nvidia-smi -L
    echo ""
    
    echo "=== GPU DETAILED INFO ==="
    nvidia-smi --query-gpu=index,name,driver_version,vbios_version,pci.bus_id,compute_cap,memory.total,memory.free \
        --format=csv,noheader
    echo ""
    
    echo "=== GPU CLOCK INFORMATION ==="
    nvidia-smi --query-gpu=index,clocks.gr,clocks.sm,clocks.mem,clocks.max.gr,clocks.max.sm,clocks.max.mem \
        --format=csv
    echo ""
    
    echo "=== GPU POWER INFORMATION ==="
    nvidia-smi --query-gpu=index,power.draw,power.limit,power.default_limit,power.max_limit \
        --format=csv
    echo ""
    
    echo "=== GPU TEMPERATURE ==="
    nvidia-smi --query-gpu=index,temperature.gpu,temperature.memory \
        --format=csv
    echo ""
    
    echo "=== CUDA VERSION ==="
    nvidia-smi | grep "CUDA Version"
    if command -v nvcc &> /dev/null; then
        nvcc --version
    else
        echo "nvcc not available in PATH"
    fi
    echo ""
    
    echo "=== PYTHON ENVIRONMENT ==="
    which python
    python --version
    echo ""
    
    echo "=== PYTORCH VERSION ==="
    python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}'); print(f'cuDNN: {torch.backends.cudnn.version()}'); print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'Device Count: {torch.cuda.device_count()}')" 2>/dev/null || echo "PyTorch not available or error"
    echo ""
    
    echo "=== vLLM VERSION ==="
    python -c "import vllm; print(f'vLLM: {vllm.__version__}')" 2>/dev/null || echo "vLLM not available or error"
    echo ""
    
    echo "=== CPU INFORMATION ==="
    lscpu | grep -E "Model name|Socket|Core|Thread|CPU MHz|CPU max MHz|CPU min MHz"
    echo ""
    
    echo "=== CPU GOVERNOR ==="
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo "Current governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
        echo "Available governors: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo 'N/A')"
    else
        echo "CPU frequency scaling not available or not accessible"
    fi
    echo ""
    
    echo "=== MEMORY INFORMATION ==="
    free -h
    echo ""
    
    echo "=== STORAGE INFORMATION ==="
    df -h | grep -E "Filesystem|/$|/home"
    echo ""
    
    echo "=== OS INFORMATION ==="
    cat /etc/os-release
    echo ""
    uname -a
    echo ""
    
    echo "=== KERNEL VERSION ==="
    uname -r
    echo ""
    
    echo "=== NVIDIA DRIVER ==="
    cat /proc/driver/nvidia/version 2>/dev/null || echo "Not available"
    echo ""
    
    echo "=== RUNNING GPU PROCESSES ==="
    nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv || echo "No GPU processes or query failed"
    echo ""
    
    echo "=== ENVIRONMENT VARIABLES (relevant) ==="
    env | grep -E "CUDA|OMP|PYTORCH|VLLM|LD_LIBRARY" | sort
    echo ""
    
    echo "=== PYTHON PACKAGES (key libraries) ==="
    pip list | grep -iE "torch|vllm|transformers|cuda|flash" || echo "Package list not available"
    echo ""
    
    echo "======================================"
    echo "END OF SYSTEM INFORMATION"
    echo "======================================"
    
} > "$OUTPUT_FILE"

echo "✓ System information saved to: ${OUTPUT_FILE}"
echo ""
echo "Summary:"
echo "--------"
grep "GPU.*:" "$OUTPUT_FILE" || true
python -c "import vllm; print(f'vLLM: {vllm.__version__}')" 2>/dev/null || echo "vLLM version: N/A"
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}')" 2>/dev/null || echo "PyTorch version: N/A"

