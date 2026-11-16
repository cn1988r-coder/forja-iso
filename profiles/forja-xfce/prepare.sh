#!/usr/bin/env bash
set -Eeuo pipefail
PROFILE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$PROFILE_DIR/mkarchiso" "$PROFILE_DIR/run_before_squashfs.sh"
command -v makepkg >/dev/null 2>&1 || { echo "Erro: makepkg não encontrado." >&2; exit 1; }
command -v sudo >/dev/null 2>&1 || { echo "Erro: sudo necessário." >&2; exit 1; }
SKEL_DIR="$PROFILE_DIR/airootfs/root/endeavouros-skel-liveuser"
[[ -d "$SKEL_DIR" ]] || { echo "Erro: skeleton ausente." >&2; exit 1; }
(cd "$SKEL_DIR" && makepkg --clean --syncdeps --noconfirm -f)
skel_packages=("$SKEL_DIR"/endeavouros-skel-liveuser-*.pkg.tar.zst)
(( ${#skel_packages[@]} == 1 )) || { echo "Erro: pacote skeleton não foi gerado de forma única." >&2; exit 1; }

DOCKBARX_DIR="$PROFILE_DIR/forja-packages/dockbarx"
PLUGIN_DIR="$PROFILE_DIR/forja-packages/xfce4-dockbarx-plugin"
RECOVERY_DIR="$PROFILE_DIR/forja-packages/forja-recovery"
SNAPSHOTS_DIR="$PROFILE_DIR/forja-packages/forja-snapshots"
for required in "$DOCKBARX_DIR/PKGBUILD" "$DOCKBARX_DIR/dockbarx.install" "$PLUGIN_DIR/PKGBUILD" "$RECOVERY_DIR/PKGBUILD" "$SNAPSHOTS_DIR/PKGBUILD"; do
  [[ -s "$required" ]] || { echo "Erro: receita local ausente: $required" >&2; exit 1; }
done

AUR_DIR="${AUR_DIR:-$HOME/.cache/forja-aur}"
mkdir -p "$AUR_DIR"
if [[ ! -d "$AUR_DIR/grub-btrfs/.git" ]]; then
  git clone https://aur.archlinux.org/grub-btrfs.git "$AUR_DIR/grub-btrfs"
else
  git -C "$AUR_DIR/grub-btrfs" pull --ff-only
fi
(cd "$AUR_DIR/grub-btrfs" && makepkg --clean --syncdeps --noconfirm -f)
grub_btrfs_packages=("$AUR_DIR/grub-btrfs"/grub-btrfs-*.pkg.tar.zst)
(( ${#grub_btrfs_packages[@]} == 1 )) || { echo "Erro: grub-btrfs não foi gerado de forma única." >&2; exit 1; }
sudo pacman -U --noconfirm --asdeps "${grub_btrfs_packages[0]}"

(cd "$DOCKBARX_DIR" && makepkg --clean --syncdeps --noconfirm -f)
shopt -s nullglob
dockbarx_packages=("$DOCKBARX_DIR"/dockbarx-*.pkg.tar.zst)
(( ${#dockbarx_packages[@]} == 1 )) || { echo "Erro: esperado exatamente um pacote DockbarX." >&2; exit 1; }
sudo pacman -U --noconfirm --asdeps "${dockbarx_packages[0]}"
(cd "$PLUGIN_DIR" && makepkg --clean --syncdeps --noconfirm -f)
plugin_packages=("$PLUGIN_DIR"/xfce4-dockbarx-plugin-*.pkg.tar.zst)
(( ${#plugin_packages[@]} == 1 )) || { echo "Erro: esperado exatamente um pacote do plugin DockbarX." >&2; exit 1; }

(cd "$RECOVERY_DIR" && makepkg --clean --syncdeps --noconfirm -f)
recovery_packages=("$RECOVERY_DIR"/forja-recovery-*.pkg.tar.zst)
(( ${#recovery_packages[@]} == 1 )) || { echo "Erro: Forja Recovery não foi gerado." >&2; exit 1; }
(cd "$SNAPSHOTS_DIR" && makepkg --clean --syncdeps --noconfirm -f)
snapshot_packages=("$SNAPSHOTS_DIR"/forja-snapshots-*.pkg.tar.zst)
(( ${#snapshot_packages[@]} == 1 )) || { echo "Erro: Forja Snapshots não foi gerado." >&2; exit 1; }

SHELLY_DIR="$PROFILE_DIR/forja-desktop-assets/shelly"
[[ -f "$SHELLY_DIR/PKGBUILD-bin" ]] || { echo "Erro: PKGBUILD do Shelly ausente." >&2; exit 1; }
(cd "$SHELLY_DIR" && makepkg --config /etc/makepkg.conf --syncdeps --noconfirm -f -p PKGBUILD-bin)
shelly_packages=("$SHELLY_DIR"/shelly-*.pkg.tar.zst)
(( ${#shelly_packages[@]} == 2 )) || { echo "Erro: esperado dois pacotes Shelly." >&2; exit 1; }

install -d "$PROFILE_DIR/airootfs/root/packages"
cp -f "${grub_btrfs_packages[@]}" "${dockbarx_packages[@]}" "${plugin_packages[@]}" "${recovery_packages[@]}" "${snapshot_packages[@]}" "${shelly_packages[@]}" "$PROFILE_DIR/airootfs/root/packages/"
local_packages=("$PROFILE_DIR"/airootfs/root/packages/*.pkg.tar.zst)
(( ${#local_packages[@]} == 7 )) || { echo "Erro: esperados 7 pacotes locais; encontrados ${#local_packages[@]}." >&2; exit 1; }
for package in "${local_packages[@]}"; do
  pacman -Qp "$package" >/dev/null || { echo "Erro: pacote local inválido: $package" >&2; exit 1; }
done
shopt -u nullglob
echo "Preparação Forja concluída: GRUB-Btrfs, DockbarX, plugin XFCE, Recovery, Snapshots e Shelly preparados."
echo "Nenhuma ISO foi compilada."
