#!/bin/bash
set -euo pipefail
# Idempotent session defaults for the live user and installed system.
mkdir -p "$HOME/GNUstep/Library/WindowMaker" "$HOME/.config/tint2" "$HOME/.config/conky" "$HOME/.config/jgmenu" "$HOME/.config/wbar"
WMRC="$HOME/GNUstep/Library/WindowMaker/WMRootMenu"
if [ ! -f "$WMRC" ] && [ -f /etc/skel/GNUstep/Library/WindowMaker/WMRootMenu ]; then
  install -m 0644 /etc/skel/GNUstep/Library/WindowMaker/WMRootMenu "$WMRC"
fi
exit 0
