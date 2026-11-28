#!/bin/bash
set -euo pipefail
# Idempotent session defaults for the live user and installed system.
# Window Maker's own dock is used; do not create or initialize Wbar.
mkdir -p "$HOME/GNUstep/Library/WindowMaker" "$HOME/.config/tint2" "$HOME/.config/conky"
WMRC="$HOME/GNUstep/Library/WindowMaker/WMRootMenu"
if [ ! -f "$WMRC" ] && [ -f /etc/skel/GNUstep/Library/WindowMaker/WMRootMenu ]; then
  install -m 0644 /etc/skel/GNUstep/Library/WindowMaker/WMRootMenu "$WMRC"
fi
exit 0
