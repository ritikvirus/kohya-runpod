#!/usr/bin/env bash
set -euo pipefail
export PATH="/opt/venv/bin:$PATH"
export WORKSPACE="${WORKSPACE:-/workspace}"
export KOHYA_DIR="${KOHYA_DIR:-/opt/kohya_ss}"
export PORT="${PORT:-7860}"

nvidia-smi || true
nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader || true

if [[ "${AUTO_UPDATE:-0}" == "1" ]]; then
  echo "[entrypoint] Updating kohya_ss..."
  git -C "$KOHYA_DIR" pull --ff-only || true
fi

mkdir -p "${WORKSPACE}/SARAHJACKSON/training_data/img" \
         "${WORKSPACE}/SARAHJACKSON/training_data/log" \
         "${WORKSPACE}/SARAHJACKSON/training_data/model" \
         "${WORKSPACE}/kohya_presets" \
         "${KOHYA_DIR}/models" "${KOHYA_DIR}/configs/presets"

# 1) Dynamic presets (Option B)
 /opt/download_presets.sh || true
# 2) Models (HF gated supported via HF_TOKEN)
 /opt/download_models.sh || true

cd "$KOHYA_DIR"
exec python3 kohya_gui.py --listen 0.0.0.0 --server_port "${PORT}" --config "${KOHYA_DIR}/config.toml"
