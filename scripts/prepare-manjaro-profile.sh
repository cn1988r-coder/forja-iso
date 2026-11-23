#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${VENOM_PROFILE_DIR:-$ROOT/manjaro/venom-mate}"
COMMON="$PROFILE/overlay-common"

[[ -d "$COMMON" ]] || { echo "Overlay comum VENOM ausente: $COMMON" >&2; exit 1; }

# Os três destinos têm funções diferentes no perfil Manjaro:
# root-overlay: sistema instalado; desktop-overlay: ambiente desktop da ISO;
# live-overlay: sessão Live. Os arquivos comuns precisam existir nos três.
for overlay in root-overlay desktop-overlay live-overlay; do
  mkdir -p "$PROFILE/$overlay"
  cp -a "$COMMON/." "$PROFILE/$overlay/"
done

echo "Overlays VENOM sincronizados: root-overlay, desktop-overlay e live-overlay."
