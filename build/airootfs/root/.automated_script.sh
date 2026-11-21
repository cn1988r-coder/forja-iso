#!/usr/bin/env bash
script_cmdline() {
    local param
    for param in $(</proc/cmdline); do case "${param}" in script=*) echo "${param#*=}"; return 0 ;; esac; done
}
automated_script() {
    local script
    script="$(script_cmdline)"
    if [[ -n "${script}" && ! -x /tmp/startup_script ]]; then
        cp "${script}" /tmp/startup_script
        chmod +x /tmp/startup_script
        /tmp/startup_script
    fi
}
if [[ $(tty) == "/dev/tty1" ]]; then automated_script; fi
