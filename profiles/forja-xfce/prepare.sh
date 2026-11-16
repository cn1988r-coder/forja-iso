#!/usr/bin/env bash
set -Eeuo pipefail

# Prepare upstream live-user assets without importing KDE/Plasma settings.
PROFILE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "$PROFILE_DIR/mkarchiso" "$PROFILE_DIR/run_before_squashfs.sh"

command -v makepkg >/dev/null 2>&1 || {
  echo "Erro: makepkg não encontrado. Execute em um sistema Arch/EndeavourOS." >&2
  exit 1
}

SKEL_DIR="$PROFILE_DIR/airootfs/root/endeavouros-skel-liveuser"
[[ -d "$SKEL_DIR" ]] || {
  echo "Erro: pacote endeavouros-skel-liveuser não encontrado no perfil." >&2
  exit 1
}
(
  cd "$SKEL_DIR"
  makepkg --syncdeps --noconfirm -f
)

# Build Shelly from the local PKGBUILD and stage its two packages for the
# EndeavourOS local-package installation hook.
SHELLY_DIR="$PROFILE_DIR/forja-desktop-assets/shelly"
[[ -f "$SHELLY_DIR/PKGBUILD-bin" ]] || {
  echo "Erro: PKGBUILD do Shelly não encontrado em $SHELLY_DIR." >&2
  exit 1
}
(
  cd "$SHELLY_DIR"
  makepkg --config /etc/makepkg.conf --syncdeps --noconfirm -f -p PKGBUILD-bin
)
install -d "$PROFILE_DIR/airootfs/root/packages"
shopt -s nullglob
shelly_packages=("$SHELLY_DIR"/shelly-*.pkg.tar.zst)
if (( ${#shelly_packages[@]} < 2 )); then
  echo "Erro: os dois pacotes Shelly não foram gerados." >&2
  exit 1
fi
cp -f "${shelly_packages[@]}" "$PROFILE_DIR/airootfs/root/packages/"
shopt -u nullglob

echo "Preparação Forja concluída. Nenhuma ISO foi compilada."
