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

# Seed built-in presets into persistent folder without overwriting
for f in "${KOHYA_DIR}/configs/presets"/*.json; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  dest="${WORKSPACE}/kohya_presets/${base}"
  if [[ ! -f "$dest" ]]; then
    cp -n "$f" "$dest" || true
  fi
done

# 1) Dynamic presets (Option B)
 /opt/download_presets.sh || true
# 2) Models (HF gated supported via HF_TOKEN)
 /opt/download_models.sh || true

cd "$KOHYA_DIR"
# Warn if no model present
if ! ls "${KOHYA_DIR}/models"/*.safetensors >/dev/null 2>&1; then
  echo "[entrypoint] No .safetensors models found in ${KOHYA_DIR}/models."
  echo "[entrypoint] Set MODEL_URLS (and HF_TOKEN for gated models) to download base models before training."
fi
# Log versions for sanity
"${VENV_DIR:-/opt/venv}"/bin/python - <<'PY'
try:
  import gradio, torch
  print(f"[entrypoint] gradio={gradio.__version__} torch={torch.__version__}")
except Exception as e:
  print("[entrypoint] Version check error:", e)
PY
exec "${VENV_DIR:-/opt/venv}"/bin/python kohya_gui.py --listen 0.0.0.0 --server_port "${PORT}" --config "${KOHYA_DIR}/config.toml"
