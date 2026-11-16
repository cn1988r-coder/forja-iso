#!/usr/bin/env bash
set -Eeuo pipefail

# Build and install the pinned Brisk Menu AUR recipe without running makepkg as root.
SOURCE_ROOT="${1:-}"
[[ "$EUID" -eq 0 && -f "$SOURCE_ROOT/build-support/brisk-menu/PKGBUILD" ]] || {
  echo "Uso interno: $0 /caminho/para/checkout/forja-iso (como root)" >&2
  exit 2
}

builder="forja-pkgbuild"
if ! id "$builder" >/dev/null 2>&1; then
  useradd --system --create-home --shell /usr/bin/nologin "$builder"
fi
work="$(mktemp -d /var/tmp/forja-brisk-menu.XXXXXX)"
trap 'rm -rf "$work"' EXIT
install -m 0644 "$SOURCE_ROOT/build-support/brisk-menu/PKGBUILD" "$work/PKGBUILD"
chown -R "$builder:$builder" "$work"
pacman -S --needed --noconfirm libnotify devtools glib2-devel meson ninja
runuser -u "$builder" -- bash -lc "cd '$work' && makepkg --nodeps --noconfirm --cleanbuild"
package="$(find "$work" -maxdepth 1 -type f -name 'brisk-menu-*.pkg.tar.zst' -print -quit)"
[[ -n "$package" ]] || { echo "O pacote Brisk Menu não foi gerado." >&2; exit 1; }
pacman -U --noconfirm "$package"
