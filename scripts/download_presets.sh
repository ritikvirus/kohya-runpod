#!/usr/bin/env bash
set -euo pipefail
PRESETS_DIR="${PRESETS_DIR:-/workspace/kohya_presets}"
mkdir -p "${PRESETS_DIR}"

if [[ -z "${PRESET_URLS:-}" ]]; then
  echo "[presets] No PRESET_URLS set; skipping."
  exit 0
fi

IFS=$'\n' read -r -d '' -a URLS < <( printf "%s" "$PRESET_URLS"; printf '\0' )
echo "[presets] Target: ${PRESETS_DIR}"
for url in "${URLS[@]}"; do
  [[ -z "$url" ]] && continue
  fname="$(basename "${url%%\?*}")"
  out="${PRESETS_DIR}/${fname}"
  echo "[presets] -> $fname"
  if [[ -n "${GH_TOKEN:-}" && "$url" =~ ^https://raw.githubusercontent.com/ ]]; then
    wget --header="Authorization: Bearer ${GH_TOKEN}" -qO "$out" "$url"
  else
    wget -qO "$out" "$url"
  fi

  var="PRESET_SHA256_${fname//[^A-Za-z0-9]/_}"
  if [[ -n "${!var:-}" ]]; then
    echo "${!var}  ${out}" | sha256sum -c -
  fi

done

echo "[presets] Done."
