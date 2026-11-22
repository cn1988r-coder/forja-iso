#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${VENOM_PROFILE_DIR:-$ROOT/manjaro/venom-mate}"
for overlay in desktop-overlay live-overlay; do
  mkdir -p "$PROFILE/$overlay"
  cp -a "$PROFILE/overlay-common/." "$PROFILE/$overlay/"
done
echo "Overlays VENOM sincronizados para live e instalado."
