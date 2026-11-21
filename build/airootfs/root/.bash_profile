#!/usr/bin/env bash
# Start VENOM live setup from Archiso's root login shell on tty1.
if [[ "$(tty 2>/dev/null || true)" == "/dev/tty1" ]]; then
  printf '%s\n' 'VENOM_AUTOMATED_SCRIPT_DISPATCHED' >/dev/ttyS0 2>/dev/null || true
  exec /root/.automated_script.sh
fi
