#!/usr/bin/env bash
# This dispatcher is invoked only by root's tty1 login profile.
# Launch the fixed Archiso live setup script directly; avoid fragile cmdline parsing.
set -Eeuo pipefail

serial_marker() {
    printf '%s\n' "$1" >/dev/ttyS0 2>/dev/null || true
}

script=/root/venom-live-setup
if [[ ! -x "$script" ]]; then
    serial_marker VENOM_LIVE_SCRIPT_NOT_EXECUTABLE
    printf '[VENOM] Live setup ausente ou sem permissão: %s\n' "$script" >&2
    exit 1
fi

serial_marker VENOM_STARTUP_SCRIPT_LAUNCHING
exec "$script"
