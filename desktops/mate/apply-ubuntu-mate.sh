#!/usr/bin/env bash
# Apply the Forja visual profile to the current Ubuntu MATE user session.
set -Eeuo pipefail

command -v gsettings >/dev/null 2>&1 || exit 0
gsettings set org.mate.interface gtk-theme 'Materia-dark' 2>/dev/null || true
gsettings set org.mate.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
gsettings set org.mate.peripherals-mouse cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
gsettings set org.mate.Marco.general theme 'Materia-dark' 2>/dev/null || true
