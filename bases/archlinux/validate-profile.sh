#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE="$ROOT/bases/archlinux"
for file in "$PROFILE/profiledef.sh" "$PROFILE/pacman.conf" "$PROFILE/packages.x86_64" "$PROFILE/build-profile.sh" "$PROFILE/airootfs/root/customize_airootfs.sh"; do
  [[ -s "$file" ]] || { echo "Arquivo obrigatório ausente: $file" >&2; exit 1; }
done
bash -n "$PROFILE/profiledef.sh"
bash -n "$PROFILE/build-profile.sh"
bash -n "$PROFILE/airootfs/root/customize_airootfs.sh"
grep -q '^\[core\]' "$PROFILE/pacman.conf"
grep -q '^\[extra\]' "$PROFILE/pacman.conf"
if grep -Eiq 'endeavouros|biglinux|manjaro' "$PROFILE/pacman.conf"; then
  echo "A configuração ativa do Pacman contém repositório de outra distribuição." >&2
  exit 1
fi
grep -q '^lightdm.service$' "$ROOT/desktop/mate/services.enabled"
grep -q '^NetworkManager.service$' "$ROOT/desktop/mate/services.enabled"
grep -q '^mate-panel$' "$ROOT/desktop/mate/packages.x86_64"
grep -q '^lightdm$' "$ROOT/desktop/mate/packages.x86_64"
echo "Validação estrutural do perfil Arch concluída."
