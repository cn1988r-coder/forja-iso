#!/usr/bin/env bash
# Execute the Archiso script directly; a stale temporary file must not skip setup.
set -Eeuo pipefail

serial_marker() {
    printf '%s\n' "$1" >/dev/ttyS0 2>/dev/null || true
}

script_cmdline() {
    local token
    local -a cmdline
    read -r -a cmdline </proc/cmdline
    for token in "${cmdline[@]}"; do
        case "$token" in
            script=*) printf '%s\n' "${token#script=}"; return 0 ;;
        esac
    done
    return 1
}

if [[ "$(tty 2>/dev/null || true)" == "/dev/tty1" ]]; then
    script="$(script_cmdline || true)"
    if [[ -z "$script" || ! -x "$script" ]]; then
        serial_marker VENOM_SCRIPT_PARAM_FALLBACK
        script=/root/venom-live-setup
    fi
    if [[ ! -x "$script" ]]; then
        serial_marker VENOM_LIVE_SCRIPT_NOT_EXECUTABLE
        printf '[VENOM] Live setup ausente ou sem permissão: %s\n' "$script" >&2
        exit 1
    fi
    serial_marker VENOM_STARTUP_SCRIPT_LAUNCHING
    exec "$script"
fi
