#!/usr/bin/env bash
set -euo pipefail

# Installs the official IPTVnator pacman package into an already prepared
# Arch/EndeavourOS root filesystem. Run as root on the ISO build host.
# Usage: install-iptvnator.sh /path/to/airootfs

ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
    echo "Usage: $0 /path/to/airootfs" >&2
    exit 2
fi
if [[ "$EUID" -ne 0 ]]; then
    echo "Run this installer as root." >&2
    exit 1
fi
command -v arch-chroot >/dev/null 2>&1 || {
    echo "arch-chroot is required (package: arch-install-scripts)." >&2
    exit 1
}

VERSION="0.25.0"
ASSET="iptvnator-${VERSION}-linux-x64.pacman"
URL="https://github.com/4gray/iptvnator/releases/download/v${VERSION}/${ASSET}"
SHA256="292781af3c6ea20aa6ff442735dcb0db6afd4c50def5684416e11174a8d5ece8"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl --fail --location --retry 3 "$URL" --output "$TMP_DIR/$ASSET"
printf '%s  %s\n' "$SHA256" "$TMP_DIR/$ASSET" | sha256sum --check --status || {
    echo "IPTVnator package checksum verification failed." >&2
    exit 1
}

install -d "$ROOT/tmp"
install -m 0644 "$TMP_DIR/$ASSET" "$ROOT/tmp/$ASSET"
arch-chroot "$ROOT" pacman -U --noconfirm "/tmp/$ASSET"
rm -f "$ROOT/tmp/$ASSET"

echo "Installed official IPTVnator $VERSION into $ROOT"
