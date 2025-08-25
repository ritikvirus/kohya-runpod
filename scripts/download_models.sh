#!/usr/bin/env bash
set -euo pipefail
KOHYA_DIR="${KOHYA_DIR:-/opt/kohya_ss}"
MODELS_DIR="${KOHYA_DIR}/models"
mkdir -p "${MODELS_DIR}"

IFS=$'\n' read -r -d '' -a URLS < <( { [[ -n "${MODEL_URLS:-}" ]] && printf "%s" "$MODEL_URLS"; } ; printf '\0' )

if [[ "${#URLS[@]}" -eq 0 ]]; then
  echo "[models] No MODEL_URLS set; skipping downloads."
  exit 0
fi

echo "[models] Downloading to ${MODELS_DIR} ..."
for url in "${URLS[@]}"; do
  [[ -z "$url" ]] && continue
  echo "[models] -> $url"
  if [[ -n "${HF_TOKEN:-}" && "$url" =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
    wget --header="Authorization: Bearer ${HF_TOKEN}" -qnc --content-disposition -P "${MODELS_DIR}" "$url"
  else
    wget -qnc --content-disposition -P "${MODELS_DIR}" "$url"
  fi
done
