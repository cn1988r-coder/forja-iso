#!/usr/bin/env bash
set -euo pipefail

# Compile the system dconf database after the profile files have been copied
# into the Archiso root filesystem.
if command -v dconf >/dev/null 2>&1; then
    dconf update
else
    echo "ERROR: dconf is required to compile Forja OS system defaults." >&2
    exit 1
fi
