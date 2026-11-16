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

if grep -Eiq 'manjaro|mhwd|pacman-mirrors|mkinitcpio' "$PACKAGES"; then
  echo "FALHA: pacote ou ferramenta exclusiva do fluxo Manjaro encontrada." >&2
  exit 1
fi

duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES" | awk '{print $1}' | sort | uniq -d)"
[[ -z "$duplicates" ]] || { echo "FALHA: pacotes duplicados: $duplicates" >&2; exit 1; }

for package in base dracut eos-dracut linux xfce4 lightdm firefox papirus-icon-theme bibata-cursor-theme; do
  grep -Fxq "$package" "$PACKAGES" || {
    echo "FALHA: pacote obrigatório ausente: $package" >&2
    exit 1
  }
done

echo "Validação estática do perfil Forja XFCE/EndeavourOS concluída."
