#!/usr/bin/env bash
set -Eeuo pipefail
# Build the profile's local packages only; this script never invokes mkarchiso.
PROFILE_DIR="$(cd -- "$(dirname -- "\${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$PROFILE_DIR/mkarchiso" "$PROFILE_DIR/run_before_squashfs.sh"
command -v makepkg >/dev/null 2>&1 || { echo "Erro: makepkg não encontrado." >&2; exit 1; }
command -v sudo >/dev/null 2>&1 || { echo "Erro: sudo é necessário para instalar a dependência local durante a preparação." >&2; exit 1; }
SKEL_DIR="$PROFILE_DIR/airootfs/root/endeavouros-skel-liveuser"
[[ -d "$SKEL_DIR" ]] || { echo "Erro: pacote endeavouros-skel-liveuser não encontrado." >&2; exit 1; }
(cd "$SKEL_DIR" && makepkg --syncdeps --noconfirm -f)

DOCKBARX_DIR="$PROFILE_DIR/forja-packages/dockbarx"
PLUGIN_DIR="$PROFILE_DIR/forja-packages/xfce4-dockbarx-plugin"
for required in "$DOCKBARX_DIR/PKGBUILD" "$DOCKBARX_DIR/dockbarx.install" "$PLUGIN_DIR/PKGBUILD"; do
  [[ -s "$required" ]] || { echo "Erro: receita DockbarX ausente: $required" >&2; exit 1; }
done
(cd "$DOCKBARX_DIR" && makepkg --clean --syncdeps --noconfirm -f)
shopt -s nullglob
dockbarx_packages=("$DOCKBARX_DIR"/dockbarx-*.pkg.tar.zst)
(( \${#dockbarx_packages[@]} == 1 )) || { echo "Erro: esperado exatamente um pacote DockbarX." >&2; exit 1; }
# The plugin depends on dockbarx. Install this just-built package as a temporary
# build-host dependency; the same package is staged for the target live rootfs.
sudo pacman -U --noconfirm --asdeps "\${dockbarx_packages[0]}"
(cd "$PLUGIN_DIR" && makepkg --clean --syncdeps --noconfirm -f)
plugin_packages=("$PLUGIN_DIR"/xfce4-dockbarx-plugin-*.pkg.tar.zst)
(( \${#plugin_packages[@]} == 1 )) || { echo "Erro: esperado exatamente um pacote do plugin DockbarX." >&2; exit 1; }

SHELLY_DIR="$PROFILE_DIR/forja-desktop-assets/shelly"
[[ -f "$SHELLY_DIR/PKGBUILD-bin" ]] || { echo "Erro: PKGBUILD do Shelly não encontrado." >&2; exit 1; }
(cd "$SHELLY_DIR" && makepkg --config /etc/makepkg.conf --syncdeps --noconfirm -f -p PKGBUILD-bin)
shelly_packages=("$SHELLY_DIR"/shelly-*.pkg.tar.zst)
(( \${#shelly_packages[@]} >= 2 )) || { echo "Erro: os dois pacotes Shelly não foram gerados." >&2; exit 1; }
install -d "$PROFILE_DIR/airootfs/root/packages"
cp -f "\${dockbarx_packages[@]}" "\${plugin_packages[@]}" "\${shelly_packages[@]}" "$PROFILE_DIR/airootfs/root/packages/"
shopt -u nullglob
echo "Preparação Forja concluída: DockbarX, plugin XFCE e Shelly preparados."
echo "Os pacotes locais serão instalados pelo hook EndeavourOS antes da criação do SquashFS."
echo "Nenhuma ISO foi compilada."
