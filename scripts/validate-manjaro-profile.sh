#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${VENOM_PROFILE_DIR:-$ROOT/manjaro/venom-mate}"
fail() { echo "FALHA: $*" >&2; exit 1; }
for f in profile.conf Packages-Desktop Packages-Root Packages-Live Packages-Mhwd; do
  [[ -e "$PROFILE/$f" || -L "$PROFILE/$f" ]] || fail "arquivo ausente: $f"
done
for pkg in mate-panel brisk-menu network-manager-applet blueman manjaro-pipewire pamac-gtk; do
  grep -Fxq "$pkg" "$PROFILE/Packages-Desktop" || fail "pacote ausente: $pkg"
done
for item in Packages-Live Packages-Root Packages-Mhwd; do [[ -L "$PROFILE/$item" ]] || fail "$item não é symlink"; done
[[ "$(readlink "$PROFILE/Packages-Live")" == "../../shared/Packages-Live" ]] || fail "Packages-Live inválido"
[[ "$(readlink "$PROFILE/Packages-Root")" == "../../shared/Packages-Root" ]] || fail "Packages-Root inválido"
[[ "$(readlink "$PROFILE/Packages-Mhwd")" == "../../shared/Packages-Mhwd" ]] || fail "Packages-Mhwd inválido"
grep -Fq 'displaymanager="lightdm"' "$PROFILE/profile.conf" || fail "LightDM ausente"
grep -Fq 'venom-dconf-update' "$PROFILE/profile.conf" || fail "serviço de configuração ausente"
for path in etc/locale.conf etc/locale.gen etc/vconsole.conf etc/X11/xorg.conf.d/00-keyboard.conf etc/dconf/db/local.d/00-venom usr/share/mate-panel/layouts/venom.layout usr/local/bin/venom-mate-first-login usr/share/icons/VENOM/index.theme usr/share/icons/VENOM/scalable/places/start-here-symbolic.svg; do
  [[ -f "$PROFILE/overlay-common/$path" ]] || fail "overlay ausente: $path"
done
LAYOUT="$PROFILE/overlay-common/usr/share/mate-panel/layouts/venom.layout"
grep -Fq 'applet-iid=BriskMenuFactory::BriskMenu' "$LAYOUT" || fail "Brisk Menu ausente do painel superior"
grep -Fq 'launcher-location=/usr/share/applications/venom-pamac.desktop' "$LAYOUT" || fail "atalho Pamac ausente do painel superior"
grep -Fq 'applet-iid=ClockAppletFactory::ClockApplet' "$LAYOUT" || fail "relógio ausente do painel superior"
[[ -f "$PROFILE/overlay-common/usr/share/applications/venom-pamac.desktop" ]] || fail "lançador Pamac ausente"
CLOCK="$PROFILE/overlay-common/etc/dconf/db/local.d/00-venom"
grep -Fq "[org/mate/panel/objects/venom-top-clock/prefs]" "$CLOCK" || fail "preferências do relógio ausentes"
grep -Fq "custom-format='%H:%M  %d/%m/%Y'" "$CLOCK" || fail "data do relógio não está no formato DD/MM/AAAA"
grep -Fq '[Toplevel top]' "$LAYOUT" || fail "painel superior ausente"
grep -Fq '[Toplevel bottom]' "$LAYOUT" || fail "painel inferior ausente"
grep -Fq "icon-theme='VENOM'" "$PROFILE/overlay-common/etc/dconf/db/local.d/00-venom" || fail "tema de ícones VENOM ausente"
grep -Fq 'group-windows' "$PROFILE/overlay-common/etc/dconf/db/local.d/00-venom" || fail "agrupamento de janelas ausente"
[[ -f "$PROFILE/desktop-overlay/etc/dconf/db/local.d/00-venom" ]] || fail "overlay instalado não preparado"
[[ -f "$PROFILE/live-overlay/etc/dconf/db/local.d/00-venom" ]] || fail "overlay live não preparado"
[[ -f "$PROFILE/live-overlay/etc/skel/.config/autostart/venom-installer.desktop" ]] || fail "autostart Calamares ausente"
if grep -RniE 'archlinux|geo\.mirror\.pkgbuild\.com|mkarchiso|archiso' "$PROFILE"; then fail "referência Arch no perfil Manjaro"; fi
grep -Fq -- '-k linux618' "$ROOT/scripts/validate-manjaro-build.sh" || fail "buildiso não seleciona linux618 LTS"
grep -Fq -- '-k linux618' "$ROOT/scripts/build-manjaro-iso.sh" || fail "build final não seleciona linux618 LTS"
bash -n "$ROOT/scripts/prepare-manjaro-profile.sh" "$ROOT/scripts/validate-manjaro-profile.sh" "$ROOT/scripts/validate-manjaro-build.sh" "$ROOT/scripts/build-manjaro-iso.sh"
echo "Validação estrutural estática: APROVADA."
echo "A resolução de brisk-menu no Manjaro Stable, Calamares, boot e instalação exige ambiente Manjaro/VM."
