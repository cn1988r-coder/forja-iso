#!/usr/bin/env bash
# Start VENOM live setup directly from Archiso's root login shell on tty1.
if [[ "$(tty 2>/dev/null || true)" == "/dev/tty1" ]]; then
  printf '%s\n' 'VENOM_AUTOMATED_SCRIPT_DISPATCHED' >/dev/ttyS0 2>/dev/null || true
  printf '%s\n' 'VENOM_LIVE_SETUP_LAUNCHING' >/dev/ttyS0 2>/dev/null || true
  exec /usr/bin/bash /root/venom-live-setup
fi
