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

VENV_PY="/opt/venv/bin/python"
if [[ ! -x "$VENV_PY" ]]; then VENV_PY="python3"; fi

echo "[models] Downloading to ${MODELS_DIR} ..."

hf_python_fallback() {
  local url="$1"
  "$VENV_PY" - "$url" "$MODELS_DIR" <<'PY'
import os, re, sys, shutil
from pathlib import Path
try:
    from huggingface_hub import hf_hub_download
except Exception as e:
    print("[models][hf_fallback] huggingface_hub not available:", e)
    sys.exit(2)

url, out_dir = sys.argv[1], sys.argv[2]
m = re.match(r"^https://huggingface\.co/([^/]+)/([^/]+)/resolve/([^/]+)/(.+)$", url)
if not m:
    print("[models][hf_fallback] Unsupported HF URL:", url)
    sys.exit(3)
owner, repo, rev, filename = m.groups()
repo_id = f"{owner}/{repo}"
token = os.environ.get("HF_TOKEN")
try:
    path = hf_hub_download(repo_id=repo_id, filename=filename, revision=rev, token=token)
    dest = Path(out_dir) / Path(filename).name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, dest)
    print(f"[models][hf_fallback] downloaded {dest}")
    sys.exit(0)
except Exception as e:
    print("[models][hf_fallback] download failed:", e)
    sys.exit(4)
PY
}

for url in "${URLS[@]}"; do
  [[ -z "$url" ]] && continue
  echo "[models] -> $url"
  if [[ "$url" =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
    if [[ -n "${HF_TOKEN:-}" ]]; then
      if ! wget --header="Authorization: Bearer ${HF_TOKEN}" -qnc --content-disposition -P "${MODELS_DIR}" "$url"; then
        echo "[models] wget failed; trying huggingface_hub fallback..."
        hf_python_fallback "$url" || true
      fi
    else
      wget -qnc --content-disposition -P "${MODELS_DIR}" "$url" || true
    fi
  else
    wget -qnc --content-disposition -P "${MODELS_DIR}" "$url" || true
  fi
done
