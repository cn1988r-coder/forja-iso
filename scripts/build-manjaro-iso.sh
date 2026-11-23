#!/usr/bin/env bash
set -Eeuo pipefail
[[ "${VENOM_ISO_APPROVED:-}" == "YES" ]] || { echo "Defina VENOM_ISO_APPROVED=YES após aprovação." >&2; exit 64; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${VENOM_ISO_OUTPUT_DIR:-/var/cache/manjaro-tools/iso}"
bash "$ROOT/scripts/validate-manjaro-build.sh"
mkdir -p "$OUTPUT_DIR"
[[ -z "$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit)" ]] || { echo "Diretório de saída contém ISO antiga." >&2; exit 1; }
cd /usr/share/manjaro-tools/iso-profiles
sudo buildiso -p venom-xfce -b stable -k linux618 -z -t "$OUTPUT_DIR"
mapfile -t ISOS < <(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.iso' -print)
[[ "${#ISOS[@]}" -eq 1 ]] || { echo "Esperada uma ISO, encontradas ${#ISOS[@]}." >&2; exit 1; }
sha256sum "${ISOS[0]}" > "$OUTPUT_DIR/SHA256SUMS"
printf 'ISO: %s\n' "${ISOS[0]}"
