#!/usr/bin/env bash
# Executa somente resolução/instalação de pacotes com buildiso -x. Não gera ISO.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/manjaro/venom-mate"
command -v buildiso >/dev/null || { echo "buildiso não encontrado; execute em um sistema Manjaro preparado." >&2; exit 127; }
command -v sudo >/dev/null || { echo "sudo não encontrado." >&2; exit 127; }

"$ROOT/scripts/prepare-manjaro-profile.sh"
sudo buildiso -i
PROFILE_ROOT="/usr/share/manjaro-tools/iso-profiles"
[[ -d "$PROFILE_ROOT/manjaro" ]] || { echo "Árvore oficial de perfis Manjaro não encontrada em $PROFILE_ROOT." >&2; exit 1; }
sudo rm -rf "$PROFILE_ROOT/manjaro/venom-mate"
sudo cp -a "$PROFILE" "$PROFILE_ROOT/manjaro/venom-mate"
cd "$PROFILE_ROOT"
sudo buildiso -p venom-mate -b stable -x
echo "Resolução e instalação dos pacotes concluídas. Nenhuma ISO foi gerada."
