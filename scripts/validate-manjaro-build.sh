#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/manjaro/venom-xfce"
command -v buildiso >/dev/null || { echo "buildiso não encontrado: execute em Manjaro." >&2; exit 127; }
command -v sudo >/dev/null || { echo "sudo não encontrado." >&2; exit 127; }
bash "$ROOT/scripts/test-venom-xfce.sh"
sudo buildiso -i
PROFILE_ROOT="/usr/share/manjaro-tools/iso-profiles"
[[ -d "$PROFILE_ROOT/manjaro" ]] || { echo "Perfis oficiais Manjaro ausentes." >&2; exit 1; }
sudo rm -rf "$PROFILE_ROOT/manjaro/venom-xfce"
sudo cp -a "$PROFILE" "$PROFILE_ROOT/manjaro/venom-xfce"
cd "$PROFILE_ROOT"
sudo buildiso -p venom-xfce -b stable -k linux618 -x
echo "RESOLUÇÃO DE PACOTES XFCE: APROVADA. ISO ainda não construída."
