#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
ARCHISO_REF="8e3ead17e1e5cfde503534d23be918b8787d3dd3"
WORK="${1:-$ROOT/.work/archiso}"
OUT="${2:-$ROOT/out}"
PROFILE="$WORK/profile"
UPSTREAM="$WORK/archiso-upstream"

[[ "$EUID" -eq 0 ]] || { echo "Execute como root: sudo $0 [workdir] [outdir]" >&2; exit 1; }
command -v mkarchiso >/dev/null 2>&1 || { echo "Instale archiso no host Arch Linux." >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Instale git." >&2; exit 1; }

rm -rf "$PROFILE" "$UPSTREAM"
install -d "$WORK" "$OUT"
git clone --filter=blob:none https://github.com/archlinux/archiso.git "$UPSTREAM"
git -C "$UPSTREAM" checkout "$ARCHISO_REF"
cp -a "$UPSTREAM/configs/releng" "$PROFILE"

# Use official Archiso boot assets and live-system support, with Forja package set.
cat "$ROOT/bases/archlinux/packages.x86_64" "$ROOT/desktop/mate/packages.x86_64" >> "$PROFILE/packages.x86_64"
sort -u "$PROFILE/packages.x86_64" -o "$PROFILE/packages.x86_64"

sed -i \
  -e 's/^iso_name=.*/iso_name="forja-os"/' \
  -e 's/^iso_label=.*/iso_label="FORJA_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
  -e 's|^iso_publisher=.*|iso_publisher="Forja OS"|g' \
  -e 's|^iso_application=.*|iso_application="Forja OS Arch Linux MATE"|g' \
  "$PROFILE/profiledef.sh"

# Overlay the Forja live root filesystem.
cp -a "$ROOT/bases/archlinux/airootfs/." "$PROFILE/airootfs/"
chmod 0755 "$PROFILE/airootfs/root/customize_airootfs.sh"
cp "$ROOT/bases/archlinux/pacman.conf" "$PROFILE/pacman.conf"
install -d "$PROFILE/airootfs/etc/skel/.config"
cp -a "$ROOT/desktop/mate/skel/.config/." "$PROFILE/airootfs/etc/skel/.config/"
install -Dm755 "$ROOT/desktop/mate/apply-defaults.sh" "$PROFILE/airootfs/usr/local/lib/forja/apply-defaults.sh"
install -Dm755 "$ROOT/desktop/mate/forja-repo/forja-repo" "$PROFILE/airootfs/usr/local/bin/forja-repo"
install -Dm644 "$ROOT/desktop/mate/forja-repo/pacman.conf" "$PROFILE/airootfs/etc/forja/pacman.conf"
install -d "$PROFILE/airootfs/var/lib/forja-repo" "$PROFILE/airootfs/var/cache/forja-repo/pkg"

# Install the native Forja applications directly into the live rootfs.
bash "$ROOT/desktop/mate/install-forja-store.sh" "$PROFILE/airootfs"
bash "$ROOT/desktop/mate/install-forja-monitor.sh" "$PROFILE/airootfs"
bash "$ROOT/desktop/mate/install-forja-update-indicator.sh" "$PROFILE/airootfs"
install -Dm755 "$ROOT/desktop/mate/forja-luz-noturna/forja-luz-noturna.py" "$PROFILE/airootfs/usr/bin/forja-luz-noturna"
install -Dm644 "$ROOT/desktop/mate/skel/.config/autostart/forja-luz-noturna.desktop" "$PROFILE/airootfs/etc/xdg/autostart/forja-luz-noturna.desktop"

# The upstream releng profile supplies boot modes and live system plumbing.
mkarchiso -v -w "$WORK/build" -o "$OUT" "$PROFILE"
echo "ISO gerada em: $OUT"
