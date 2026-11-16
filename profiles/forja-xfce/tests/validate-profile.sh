#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROFILE="$ROOT/profiles/forja-xfce"
PACKAGES="$PROFILE/packages.x86_64"

required=(
  "$PROFILE/profiledef.sh"
  "$PROFILE/prepare.sh"
  "$PROFILE/prepare-forja.sh"
  "$PROFILE/run_before_squashfs.sh"
  "$PROFILE/apply-forja-live.sh"
  "$PROFILE/README.md"
  "$ROOT/desktops/xfce/install-branding.sh"
  "$ROOT/desktops/xfce/apply-forja-layout.sh"
  "$ROOT/desktops/xfce/panel-default.xml"
)
for file in "${required[@]}"; do
  [[ -f "$file" ]] || { echo "FALHA: arquivo ausente: $file" >&2; exit 1; }
done

bash -n "$PROFILE/profiledef.sh"
bash -n "$PROFILE/prepare.sh"
bash -n "$PROFILE/prepare-forja.sh"
bash -n "$PROFILE/run_before_squashfs.sh"
bash -n "$PROFILE/apply-forja-live.sh"
bash -n "$ROOT/desktops/xfce/install-branding.sh"
bash -n "$ROOT/desktops/xfce/apply-forja-layout.sh"

if grep -Eiq 'manjaro|mhwd|pacman-mirrors' "$PACKAGES"; then
  echo "FALHA: pacote ou ferramenta exclusiva do fluxo Manjaro encontrada." >&2
  exit 1
fi

duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES" | awk '{print $1}' | sort | uniq -d)"
[[ -z "$duplicates" ]] || { echo "FALHA: pacotes duplicados: $duplicates" >&2; exit 1; }

for package in base arch-install-scripts mkinitcpio-archiso mkinitcpio-nfs-utils syslinux dracut eos-dracut linux xfce4 lightdm firefox papirus-icon-theme bibata-cursor-theme reflector curl; do
  grep -Fxq "$package" "$PACKAGES" || {
    echo "FALHA: pacote obrigatório ausente: $package" >&2
    exit 1
  }
done

# The preparation script must reject incomplete upstream checkouts instead of
# silently producing a profile without BIOS/UEFI boot assets or build hooks.
grep -Fq 'for required in profiledef.sh prepare.sh run_before_squashfs.sh pacman.conf' "$PROFILE/prepare-forja.sh"
grep -Fq 'for required_dir in airootfs efiboot syslinux' "$PROFILE/prepare-forja.sh"
grep -Fq 'cp -a "$UPSTREAM_ROOT/efiboot" "$TARGET/"' "$PROFILE/prepare-forja.sh"
grep -Fq 'cp -a "$UPSTREAM_ROOT/syslinux" "$TARGET/"' "$PROFILE/prepare-forja.sh"

echo "Validação estática do perfil Forja XFCE/EndeavourOS concluída (sem compilar ISO)."
