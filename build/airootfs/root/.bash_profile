#!/usr/bin/env bash
# Trigger setup as a systemd unit, outside the tty login session scope.
if [[ "$(tty 2>/dev/null || true)" == "/dev/tty1" ]]; then
  printf '%s\n' 'VENOM_AUTOMATED_SCRIPT_DISPATCHED' >/dev/ttyS0 2>/dev/null || true
  systemctl start venom-live-setup.service
fi
