#!/usr/bin/env bash
# Start the vLLM server locally with the given parameters

set -euo pipefail

# -----------------------------
# BEGIN VARIABLES

# Model + alias + tokenizer
MODEL="meta-llama/Llama-3.1-8B-Instruct"
TOKENIZER="meta-llama/Llama-3.1-8B-Instruct"

# vLLM serving knobs
MAX_MODEL_LEN=8192
MAX_NUM_SEQS=256
GPU_MEMORY_UTIL=0.90
HOST="127.0.0.1"
PORT="8000"
API_KEY="dummy"   # for OpenAI-compatible auth

# Expectation checks (optional; set to "" to skip)
EXPECT_CC_STATUS="OFF"        # "ON" or "OFF" or "" to skip assertion
EXPECT_DEVTOOLS_MODE="OFF"      # "ON" or "OFF" or "" to skip assertion

# Logging
LOG_DIR="/persistent/logs/vllm/server"
RUN_TAG="$(date -u +%Y%m%dT%H%M%SZ)_${MODEL}"
SERVER_LOG="${LOG_DIR}/${RUN_TAG}.log"
META_JSON="${LOG_DIR}/${RUN_TAG}_run_meta.json"
CC_REPORT="${LOG_DIR}/${RUN_TAG}_cc_report.txt"
PIP_PKGS="${LOG_DIR}/${RUN_TAG}_pip_versions.txt"
ENV_INFO="${LOG_DIR}/${RUN_TAG}_env_info.txt"

# Extra server flags (if you need to add/override)
EXTRA_SERVER_FLAGS="--enable-chunked-prefill --disable-log-requests"

# CPU/tokenizer hygiene
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-8}
export TOKENIZERS_PARALLELISM="false"

# END VARIABLES
# -----------------------------

mkdir -p "${LOG_DIR}"

log() { printf "[%s] %s\n" "$(date -u +%H:%M:%S)" "$*"; }

# ---------- Step 1: Environment pinning & validation ----------
log "Recording NVIDIA driver, CUDA, and GPU inventory…"
{
  echo "===== nvidia-smi ====="
  nvidia-smi || true
  echo
  echo "===== nvidia-smi -L ====="
  nvidia-smi -L || true
  echo
  echo "===== nvcc --version ====="
  nvcc --version || true
} > "${ENV_INFO}" 2>&1

log "Recording Confidential Compute status…"
# On non-CC SKUs this still works but may show OFF.
if nvidia-smi conf-compute -a > "${CC_REPORT}" 2>&1; then
  CC_STATUS=$(awk -F: '/CC status/ {gsub(/ /,"",$2); print $2}' "${CC_REPORT}" | head -n1 || true)
  DEVTOOLS_MODE=$(awk -F: '/DevTools/ {gsub(/ /,"",$2); print $2}' "${CC_REPORT}" | head -n1 || true)
  log "Detected CC status: ${CC_STATUS:-unknown}; DevTools: ${DEVTOOLS_MODE:-unknown}"
else
  CC_STATUS="unknown"
  DEVTOOLS_MODE="unknown"
  log "nvidia-smi conf-compute not available; skipping CC report."
fi

# Optional assertions
if [[ -n "${EXPECT_CC_STATUS}" && "${CC_STATUS}" != "${EXPECT_CC_STATUS}" ]]; then
  echo "FATAL: Expected CC status ${EXPECT_CC_STATUS}, got ${CC_STATUS}. Aborting." >&2
  exit 1
fi
if [[ -n "${EXPECT_DEVTOOLS_MODE}" && "${DEVTOOLS_MODE}" != "${EXPECT_DEVTOOLS_MODE}" ]]; then
  echo "FATAL: Expected CC DevTools ${EXPECT_DEVTOOLS_MODE}, got ${DEVTOOLS_MODE}. Aborting." >&2
  exit 1
fi

log "Recording Python package versions…"
python - <<'PY' | tee "${PIP_PKGS}" >/dev/null
import sys, pkgutil, subprocess, json
def pip_freeze():
    try:
        out = subprocess.check_output([sys.executable, "-m", "pip", "freeze"], text=True)
        print(out.strip())
    except Exception as e:
        print(f"pip freeze failed: {e}")
try:
    import vllm, torch, transformers
    meta = {
        "python": sys.version.split()[0],
        "vllm": getattr(vllm, "__version__", "unknown"),
        "torch": getattr(torch, "__version__", "unknown"),
        "transformers": getattr(transformers, "__version__", "unknown"),
    }
    print("# core versions")
    print(json.dumps(meta))
except Exception as e:
    print(f"# core versions error: {e}")
print("# pip freeze")
pip_freeze()
PY

# ---------- Step 2: Start vLLM server identically across modes ----------
log "Starting vLLM server…"
# Build the exact command string for provenance
SERVER_CMD=$(cat <<EOF
vllm serve ${MODEL} \
  --tokenizer ${TOKENIZER} \
  --max-model-len ${MAX_MODEL_LEN} \
  --max-num-seqs ${MAX_NUM_SEQS} \
  --gpu-memory-utilization ${GPU_MEMORY_UTIL} \
  --api-key ${API_KEY} \
  --host ${HOST} --port ${PORT} \
  ${EXTRA_SERVER_FLAGS}
EOF
)

# Write meta JSON
cat > "${META_JSON}" <<META
{
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "model": "${MODEL}",
  "tokenizer": "${TOKENIZER}",
  "max_model_len": ${MAX_MODEL_LEN},
  "max_num_seqs": ${MAX_NUM_SEQS},
  "gpu_memory_utilization": ${GPU_MEMORY_UTIL},
  "host": "${HOST}",
  "port": ${PORT},
  "api_key_present": true,
  "extra_server_flags": "${EXTRA_SERVER_FLAGS}",
  "env": {
    "OMP_NUM_THREADS": "${OMP_NUM_THREADS}",
    "TOKENIZERS_PARALLELISM": "${TOKENIZERS_PARALLELISM}"
  },
  "cc_status": "${CC_STATUS}",
  "cc_devtools_mode": "${DEVTOOLS_MODE}",
  "env_info_path": "${ENV_INFO}",
  "cc_report_path": "${CC_REPORT}",
  "server_log_path": "${SERVER_LOG}",
  "pip_versions_path": "${PIP_PKGS}",
  "server_command": "$(echo "${SERVER_CMD}" | tr '\n' ' ')"
}
META

# Launch server (daemonized), tee logs
# Tip: replace nohup with systemd or supervisord if you want stronger lifecycle control.
nohup bash -lc "${SERVER_CMD}" > "${SERVER_LOG}" 2>&1 &

PID=$!
log "vLLM server PID: ${PID}"
log "Logs: ${SERVER_LOG}"
log "Meta: ${META_JSON}"
log "CC report: ${CC_REPORT}"

# Optional: quick health probe
sleep 3
curl -s "http://${HOST}:${PORT}/v1/models" || true

log "Done. Keep this shell to manage the process, or 'kill ${PID}' to stop."