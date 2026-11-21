#!/usr/bin/env bash
# This dispatcher is invoked only by root's tty1 login profile.
# Do not re-check the controlling TTY here: serial-console routing can make
# "tty" report a different device even though getty@tty1 started this login.
set -Eeuo pipefail

serial_marker() {
    printf '%s\\n' "$1" >/dev/ttyS0 2>/dev/null || true
}

script_cmdline() {
    local token
    local -a cmdline
    read -r -a cmdline </proc/cmdline
    for token in "${cmdline[@]}"; do
        case "$token" in
            script=*) printf '%s\\n' "${token#script=}"; return 0 ;;
        esac
    done
    return 1
}

script="$(script_cmdline || true)"
if [[ -z "$script" || ! -x "$script" ]]; then
    serial_marker VENOM_SCRIPT_PARAM_FALLBACK
    script=/root/venom-live-setup
fi
if [[ ! -x "$script" ]]; then
    serial_marker VENOM_LIVE_SCRIPT_NOT_EXECUTABLE
    printf '[VENOM] Live setup ausente ou sem permissão: %s\\n' "$script" >&2
    exit 1
fi

serial_marker VENOM_STARTUP_SCRIPT_LAUNCHING
exec "$script"
