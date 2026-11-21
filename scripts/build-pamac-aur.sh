#!/usr/bin/env bash
set -Eeuo pipefail

# Build the Arch AUR variants of Pamac and its library. No Manjaro repositories
# or Manjaro-built binary packages are used.
WORK="${RUNNER_TEMP:-/tmp}/venom-pamac-build"
REPO=/tmp/venom-aur-repo
mkdir -p "$WORK" "$REPO"

pacman -S --needed --noconfirm sudo
if ! id builder >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash builder
fi
printf 'builder ALL=(root) NOPASSWD: /usr/bin/pacman\n' >/etc/sudoers.d/90-venom-builder
chmod 0440 /etc/sudoers.d/90-venom-builder

build_aur_package() {
  local package="$1"
  local dir="$WORK/$package"
  git clone --depth 1 "https://aur.archlinux.org/$package.git" "$dir"
  chown -R builder:builder "$dir"
  runuser -u builder -- bash -lc "cd '$dir' && makepkg --syncdeps --noconfirm --cleanbuild"
  find "$dir" -maxdepth 1 -type f -name '*.pkg.tar.zst' -exec cp -f {} "$REPO/" \;
}

# libpamac-aur is the Arch AUR library dependency of pamac-aur.
build_aur_package libpamac-aur
pacman -U --noconfirm "$REPO"/libpamac-aur-*.pkg.tar.zst
build_aur_package pamac-aur

shopt -s nullglob
packages=("$REPO"/*.pkg.tar.zst)
(("${#packages[@]}" >= 2)) || { echo "AUR Pamac packages were not produced." >&2; exit 1; }
repo-add "$REPO/venom-aur.db.tar.gz" "${packages[@]}"
test -s "$REPO/venom-aur.db"
test -s "$REPO/venom-aur.files"
