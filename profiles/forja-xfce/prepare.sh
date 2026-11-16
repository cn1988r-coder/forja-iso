#!/usr/bin/env bash
set -Eeuo pipefail

# Minimal replacement for the upstream KDE-oriented prepare.sh.
# Keep EndeavourOS live-user shell skeleton, but do not download Plasma settings
# or overwrite Forja's wallpaper and desktop assets.
PROFILE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "$PROFILE_DIR/mkarchiso" "$PROFILE_DIR/run_before_squashfs.sh"

SKEL_DIR="$PROFILE_DIR/airootfs/root/endeavouros-skel-liveuser"
if [[ -d "$SKEL_DIR" ]]; then
  command -v makepkg >/dev/null 2>&1 || {
    echo "Erro: makepkg não encontrado. Execute em um sistema Arch/EndeavourOS." >&2
    exit 1
  }
  (
    cd "$SKEL_DIR"
    makepkg --syncdeps --noconfirm -f
  )
else
  echo "Erro: pacote endeavouros-skel-liveuser não encontrado no perfil." >&2
  exit 1
fi

fi

# Build Shelly from the maintained local PKGBUILD and stage both packages for
# EndeavourOS' local-package installation hook.
SHELLY_DIR="$PROFILE_DIR/forja-desktop-assets/shelly"
if [[ -f "$SHELLY_DIR/PKGBUILD-bin" ]]; then
  command -v makepkg >/dev/null 2>&1 || {
    echo "Erro: makepkg não encontrado para preparar Shelly." >&2
    exit 1
  }
  install -d "$PROFILE_DIR/airootfs/root/packages"
  (
    cd "$SHELLY_DIR"
    makepkg --syncdeps --noconfirm -f --config /etc/makepkg.conf
  )
  find "$SHELLY_DIR" -maxdepth 1 -type f -name 'shelly-*.pkg.tar.zst' -exec cp -f {} "$PROFILE_DIR/airootfs/root/packages/" \;
  find "$SHELLY_DIR" -maxdepth 1 -type f -name 'shelly-flatpak-backend-*.pkg.tar.zst' -exec cp -f {} "$PROFILE_DIR/airootfs/root/packages/" \;
else
  echo "Erro: PKGBUILD do Shelly não encontrado em $SHELLY_DIR." >&2
  exit 1
fi

echo "Preparação Forja concluída. Nenhuma ISO foi compilada."
