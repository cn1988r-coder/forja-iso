#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${VENOM_ISO_APPROVED:-}" != "YES" ]]; then
  echo "Compilação bloqueada. Execute somente após aprovação das validações." >&2
  exit 64
fi

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${VENOM_ISO_OUTPUT_DIR:-/var/cache/manjaro-tools/iso}"

# A primeira fase prepara o perfil oficial e constrói as imagens sem gerar ISO.
# A segunda fase usa -z para gerar a ISO a partir dessas imagens já validadas.
"$ROOT/scripts/validate-manjaro-build.sh"

mkdir -p "$OUTPUT_DIR"
if find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit | grep -q .; then
  echo "O diretório de saída precisa estar vazio para evitar misturar ISOs antigas." >&2
  exit 1
fi

cd /usr/share/manjaro-tools/iso-profiles
sudo buildiso -p venom-mate -b stable -k linux618 -z -t "$OUTPUT_DIR"

mapfile -t ISOS < <(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.iso' -print)
if [[ "${#ISOS[@]}" -ne 1 ]]; then
  echo "Esperada exatamente uma ISO nova; encontradas: ${#ISOS[@]}." >&2
  exit 1
fi

sha256sum "${ISOS[0]}" > "$OUTPUT_DIR/SHA256SUMS"
printf 'ISO gerada: %s\n' "${ISOS[0]}"
printf 'Checksum: %s/SHA256SUMS\n' "$OUTPUT_DIR"
