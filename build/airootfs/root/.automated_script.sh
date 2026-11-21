#!/usr/bin/env bash
# Preserve Archiso's script= behavior, but do not silently skip the VENOM
# live setup if the kernel command line parameter is absent or unusable.
# shellcheck disable=SC2206
script_cmdline() {
    local param
    for param in $(</proc/cmdline); do
        case "${param}" in
            script=*) echo "${param#*=}"; return 0 ;;
        esac
    done
}

serial_marker() {
    printf '%s\\n' "$1" >/dev/ttyS0 2>/dev/null || true
}

automated_script() {
    local script
    script="$(script_cmdline)"

    if [[ -z "${script}" || ! -x "${script}" ]]; then
        serial_marker VENOM_SCRIPT_PARAM_FALLBACK
        script="/root/venom-live-setup"
    fi

    if [[ ! -x "${script}" ]]; then
        serial_marker VENOM_LIVE_SCRIPT_NOT_EXECUTABLE
        printf '[VENOM] Live setup ausente ou sem permissão: %s\\n' "${script}" >&2
        return 1
    fi

    if [[ ! -x /tmp/startup_script ]]; then
        cp "${script}" /tmp/startup_script
        chmod +x /tmp/startup_script
        serial_marker VENOM_STARTUP_SCRIPT_LAUNCHING
        /tmp/startup_script
    fi
}

if [[ "$(tty 2>/dev/null || true)" == "/dev/tty1" ]]; then
    automated_script
fi
