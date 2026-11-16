#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROFILE="$ROOT/profiles/forja-xfce"
PACKAGES="$PROFILE/packages.x86_64"
DOCKBARX="$PROFILE/forja-packages/dockbarx/PKGBUILD"
DOCKBARX_INSTALL="$PROFILE/forja-packages/dockbarx/dockbarx.install"
DOCKBARX_PLUGIN="$PROFILE/forja-packages/xfce4-dockbarx-plugin/PKGBUILD"
PANEL="$ROOT/desktops/xfce/panel-default.xml"
required=("$PROFILE/profiledef.sh" "$PROFILE/prepare.sh" "$PROFILE/prepare-forja.sh" "$PROFILE/run_before_squashfs.sh" "$PROFILE/apply-forja-live.sh" "$PROFILE/README.md" "$DOCKBARX" "$DOCKBARX_INSTALL" "$DOCKBARX_PLUGIN" "$ROOT/desktops/xfce/install-branding.sh" "$ROOT/desktops/xfce/apply-forja-layout.sh" "$PANEL")
for file in "${required[@]}"; do
  [[ -f "$file" ]] || { echo "FALHA: arquivo ausente: $file" >&2; exit 1; }
done
bash -n "$PROFILE/profiledef.sh"
bash -n "$PROFILE/prepare.sh"
bash -n "$PROFILE/prepare-forja.sh"
bash -n "$PROFILE/run_before_squashfs.sh"
bash -n "$PROFILE/apply-forja-live.sh"
bash -n "$ROOT/desktops/xfce/profile.conf"
bash -n "$ROOT/desktops/xfce/install-branding.sh"
bash -n "$ROOT/desktops/xfce/apply-forja-layout.sh"
if grep -Eiq 'manjaro|mhwd|pacman-mirrors' "$PACKAGES"; then
  echo "FALHA: pacote exclusivo do Manjaro encontrado." >&2
  exit 1
fi
duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES" | awk '{print $1}' | sort | uniq -d)"
[[ -z "$duplicates" ]] || { echo "FALHA: pacotes duplicados: $duplicates" >&2; exit 1; }
for package in base xorg-server arch-install-scripts mkinitcpio-archiso mkinitcpio-nfs-utils syslinux dracut eos-dracut linux xfce4 lightdm firefox papirus-icon-theme bibata-cursor-theme reflector curl; do
  grep -Fxq "$package" "$PACKAGES" || { echo "FALHA: pacote obrigatório ausente: $package" >&2; exit 1; }
done
grep -Fq 'value="dockbarx"' "$PANEL"
if grep -Eiq 'docklike|xfce4-docklike-plugin' "$PANEL" "$PACKAGES" "$ROOT/desktops/xfce/packages.arch"; then
  echo "FALHA: referência ativa a Docklike encontrada." >&2
  exit 1
fi
grep -Fq "depends=('dockbarx' 'xfce4-panel')" "$DOCKBARX_PLUGIN"
grep -Fq "sha256sums=('8df37a367d4454c590d29cbaea9f7a3ec09ddf13905943b3becc717241c275da')" "$DOCKBARX"
grep -Fq "sha256sums=('68d106b2446b89b90423cec00f24f999223fd289ad712bb807eb918670b91eec')" "$DOCKBARX_PLUGIN"
if grep -Eiq 'sha256sums=.*SKIP' "$DOCKBARX" "$DOCKBARX_PLUGIN"; then
  echo "FALHA: checksum SKIP não é permitido nas receitas DockbarX." >&2
  exit 1
fi
grep -Fq 'dockbarx-*.pkg.tar.zst' "$PROFILE/prepare.sh"
grep -Fq 'xfce4-dockbarx-plugin-*.pkg.tar.zst' "$PROFILE/prepare.sh"
grep -Fq 'local_packages=(/root/packages/*.pkg.tar.zst)' "$PROFILE/prepare-forja.sh"
grep -Fq 'pacman -U --noconfirm --needed -- "${local_packages[@]}"' "$PROFILE/prepare-forja.sh"
grep -Fq 'for required in profiledef.sh prepare.sh run_before_squashfs.sh pacman.conf' "$PROFILE/prepare-forja.sh"
grep -Fq 'for required_dir in airootfs efiboot syslinux' "$PROFILE/prepare-forja.sh"
grep -Fq 'cp -a "$UPSTREAM_ROOT/efiboot" "$TARGET/"' "$PROFILE/prepare-forja.sh"
grep -Fq 'cp -a "$UPSTREAM_ROOT/syslinux" "$TARGET/"' "$PROFILE/prepare-forja.sh"
echo "Validação estática do perfil Forja XFCE/EndeavourOS concluída (DockbarX; sem ISO)."
