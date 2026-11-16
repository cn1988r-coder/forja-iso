#!/usr/bin/env bash
set -Eeuo pipefail

PROFILE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$PROFILE_DIR/../.." && pwd)"
UPSTREAM_ROOT="${ENDEAVOUROS_ISO_DIR:-$PWD}"

[[ -f "$UPSTREAM_ROOT/mkarchiso" ]] || {
  echo "Erro: execute este script na raiz de um clone do EndeavourOS-ISO." >&2
  exit 1
}
for required in profiledef.sh prepare.sh run_before_squashfs.sh pacman.conf; do
  [[ -f "$UPSTREAM_ROOT/$required" ]] || {
    echo "Erro: arquivo obrigatório do construtor EndeavourOS ausente: $required" >&2
    exit 1
  }
done
for required_dir in airootfs efiboot syslinux; do
  [[ -d "$UPSTREAM_ROOT/$required_dir" ]] || {
    echo "Erro: diretório obrigatório do construtor EndeavourOS ausente: $required_dir" >&2
    exit 1
  }
done

# Do not overwrite the upstream source checkout. Prepare a separate Forja profile
# directory so upstream files remain available for comparison and recovery.
TARGET="$UPSTREAM_ROOT/forja-xfce-profile"
if [[ -e "$TARGET" ]]; then
  echo "Erro: $TARGET já existe. Remova ou renomeie manualmente antes de preparar novamente." >&2
  exit 1
fi

mkdir -p "$TARGET"
cp -a "$PROFILE_DIR/." "$TARGET/"
cp -a "$REPO_ROOT/desktops/xfce" "$TARGET/forja-desktop-assets"

# Copy the upstream profile framework files, then replace only the profile-specific
# package list and profile definition with Forja's versions.
cp -a "$UPSTREAM_ROOT/airootfs" "$TARGET/"
cp -a "$UPSTREAM_ROOT/efiboot" "$TARGET/"
cp -a "$UPSTREAM_ROOT/syslinux" "$TARGET/"
cp -a "$UPSTREAM_ROOT/pacman.conf" "$TARGET/"
cp -a "$UPSTREAM_ROOT/mkarchiso" "$TARGET/"
cp -a "$UPSTREAM_ROOT/run_before_squashfs.sh" "$TARGET/run_before_squashfs-upstream.sh"

# The upstream hook assumes EndeavourOS wallpaper/Calamares assets that the
# KDE-oriented prepare.sh normally downloads or installs. Forja supplies its
# own desktop branding, so make those optional upstream assets non-fatal while
# preserving the live-user, keyring, mirror and offline-package stages.
python3 - "$TARGET/run_before_squashfs-upstream.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
old_wallpaper = 'mv "/root/endeavouros-wallpaper.png" "/etc/calamares/files/endeavouros-wallpaper.png"'
new_wallpaper = '''if [[ -f "/root/endeavouros-wallpaper.png" ]]; then
  install -d "/etc/calamares/files"
  mv "/root/endeavouros-wallpaper.png" "/etc/calamares/files/endeavouros-wallpaper.png"
else
  echo "Forja: wallpaper padrão do EndeavourOS ausente; usando identidade visual Forja."
fi'''
old_livewall = 'mv "/root/livewall.png" "/usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png"'
new_livewall = '''if [[ -f "/root/livewall.png" ]]; then
  install -d "/usr/share/endeavouros/backgrounds"
  mv "/root/livewall.png" "/usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png"
fi'''
old_packages = 'pacman -U --noconfirm --needed -- "/root/packages/"*".pkg.tar.zst"'
new_packages = '''shopt -s nullglob
local_packages=(/root/packages/*.pkg.tar.zst)
if (( ${#local_packages[@]} )); then
  pacman -U --noconfirm --needed -- "${local_packages[@]}"
else
  echo "Forja: nenhum pacote local adicional foi preparado."
fi
shopt -u nullglob'''
for old, new in ((old_wallpaper, new_wallpaper), (old_livewall, new_livewall), (old_packages, new_packages)):
    if old not in text:
        raise SystemExit(f"Trecho upstream esperado não encontrado: {old}")
    text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
PY
cp -a "$PROFILE_DIR/apply-forja-live.sh" "$TARGET/airootfs/root/apply-forja-live.sh"
cp -a "$REPO_ROOT/desktops/xfce" "$TARGET/airootfs/root/forja-desktop-assets"
cp -a "$UPSTREAM_ROOT/prepare.sh" "$TARGET/upstream-prepare.sh"
cp -a "$UPSTREAM_ROOT/profiledef.sh" "$TARGET/upstream-profiledef.sh"

chmod +x "$TARGET/prepare-forja.sh" "$TARGET/prepare.sh" "$TARGET/run_before_squashfs.sh" "$TARGET/airootfs/root/apply-forja-live.sh" "$TARGET/airootfs/usr/local/bin/forja-update"
echo "Perfil Forja XFCE preparado em: $TARGET"
echo "A estrutura upstream original não foi alterada."
echo "Próxima etapa: entre em $TARGET e execute ./prepare.sh para preparar os pacotes locais. Isso ainda não compila a ISO."
