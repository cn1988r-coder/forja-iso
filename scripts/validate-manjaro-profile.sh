#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/manjaro/venom-mate"
fail() { echo "FALHA: $*" >&2; exit 1; }
for f in profile.conf Packages-Desktop Packages-Root Packages-Live Packages-Mhwd; do
  [[ -e "$PROFILE/$f" ]] || fail "arquivo ausente: $f"
done
for pkg in mate-panel network-manager-applet blueman manjaro-pipewire pamac-gtk; do
  grep -Fxq "$pkg" "$PROFILE/Packages-Desktop" || fail "pacote ausente: $pkg"
done
for item in Packages-Live Packages-Root Packages-Mhwd; do
  [[ -L "$PROFILE/$item" ]] || fail "$item não é symlink"
done
[[ "$(readlink "$PROFILE/Packages-Live")" == "../../shared/Packages-Live" ]] || fail "Packages-Live não aponta para a lista oficial"
[[ "$(readlink "$PROFILE/Packages-Root")" == "../../shared/Packages-Root" ]] || fail "Packages-Root não aponta para a lista oficial"
[[ "$(readlink "$PROFILE/Packages-Mhwd")" == "../../shared/Packages-Mhwd" ]] || fail "Packages-Mhwd não aponta para a lista oficial"
grep -Fq 'displaymanager="lightdm"' "$PROFILE/profile.conf" || fail "LightDM ausente"
grep -Fq 'efi_boot_loader="grub"' "$PROFILE/profile.conf" || fail "GRUB UEFI ausente"
bash -n "$ROOT/scripts/prepare-manjaro-profile.sh"
python3 -m py_compile "$PROFILE/overlay-common/usr/local/bin/venom-menu"
if grep -RniE 'archlinux|geo\.mirror\.pkgbuild\.com|mkarchiso|archiso' "$PROFILE"; then
  fail "referência Arch encontrada no perfil Manjaro"
fi
echo "Validação estrutural e estática: APROVADA."
echo "Resolução de pacotes, Calamares, boot e instalação ainda precisam de ambiente Manjaro/VM."
