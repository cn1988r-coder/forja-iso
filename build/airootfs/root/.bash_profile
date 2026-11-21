#!/usr/bin/env bash
# Archiso invokes the live setup through the root login shell on tty1.
# The VENOM root account uses Bash, so provide the Bash equivalent of
# Archiso's upstream .zlogin hook.
if [[ "$(tty 2>/dev/null || true)" == "/dev/tty1" ]]; then
  printf '%s\n' 'VENOM_AUTOMATED_SCRIPT_DISPATCHED' >/dev/ttyS0 2>/dev/null || true
  /root/.automated_script.sh
fi
