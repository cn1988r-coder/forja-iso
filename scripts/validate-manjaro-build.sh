#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/manjaro/venom-mate"
command -v buildiso >/dev/null || { echo "buildiso não encontrado; execute em um sistema Manjaro preparado." >&2; exit 127; }
command -v sudo >/dev/null || { echo "sudo não encontrado." >&2; exit 127; }
"$ROOT/scripts/prepare-manjaro-profile.sh"
sudo buildiso -i
PROFILE_ROOT="/usr/share/manjaro-tools/iso-profiles"
[[ -d "$PROFILE_ROOT/manjaro" ]] || { echo "Árvore oficial de perfis Manjaro não encontrada." >&2; exit 1; }
sudo rm -rf "$PROFILE_ROOT/manjaro/venom-mate"
sudo cp -a "$PROFILE" "$PROFILE_ROOT/manjaro/venom-mate"
cd "$PROFILE_ROOT"
sudo buildiso -p venom-mate -b stable -k linux618 -x
if find /var/cache/manjaro-tools/iso -type f -name '*.iso' -print -quit | grep -q .; then
  echo "ERRO: buildiso -x não deveria gerar ISO." >&2
  exit 1
fi
echo "Resolução de pacotes Stable concluída com kernel linux618 LTS. Nenhuma ISO foi gerada."
