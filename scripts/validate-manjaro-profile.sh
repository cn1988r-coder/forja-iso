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
for path in etc/locale.conf etc/locale.gen etc/vconsole.conf etc/X11/xorg.conf.d/00-keyboard.conf etc/dconf/profile/user etc/dconf/db/local.d/00-venom etc/systemd/system/venom-dconf-update.service usr/share/backgrounds/venom/venom-wallpaper.svg usr/share/mate-panel/layouts/venom.layout usr/local/bin/venom-mate-first-login usr/share/icons/VENOM/index.theme usr/share/icons/VENOM/scalable/places/start-here-symbolic.svg; do
  [[ -f "$PROFILE/overlay-common/$path" ]] || fail "overlay ausente: $path"
done
LAYOUT="$PROFILE/overlay-common/usr/share/mate-panel/layouts/venom.layout"
grep -Fq 'applet-iid=BriskMenuFactory::BriskMenu' "$LAYOUT" || fail "Brisk Menu ausente do painel superior"
grep -Fq 'launcher-location=/usr/share/applications/venom-pamac.desktop' "$LAYOUT" || fail "atalho Pamac ausente do painel superior"
grep -Fq 'applet-iid=ClockAppletFactory::ClockApplet' "$LAYOUT" || fail "relógio ausente do painel superior"
[[ -f "$PROFILE/overlay-common/usr/share/applications/venom-pamac.desktop" ]] || fail "lançador Pamac ausente"
grep -Fxq "Exec=pamac-manager" "$PROFILE/overlay-common/usr/share/applications/venom-pamac.desktop" || fail "atalho Pamac sem comando de inicialização esperado"
grep -Fxq "Terminal=false" "$PROFILE/overlay-common/usr/share/applications/venom-pamac.desktop" || fail "atalho Pamac configurado para abrir em terminal"
CLOCK="$PROFILE/overlay-common/etc/dconf/db/local.d/00-venom"
WALLPAPER="/usr/share/backgrounds/venom/venom-wallpaper.svg"
WALLPAPER_FILE="$PROFILE/overlay-common$WALLPAPER"
[[ -s "$WALLPAPER_FILE" ]] || fail "wallpaper VENOM ausente ou vazio"
grep -Fq '<svg ' "$WALLPAPER_FILE" || fail "wallpaper VENOM não parece ser um SVG válido"
grep -Fq "[org/mate/desktop/background]" "$CLOCK" || fail "seção de papel de parede MATE ausente"
grep -Fq "picture-filename='$WALLPAPER'" "$CLOCK" || fail "MATE não aponta para o wallpaper VENOM"
grep -Fq "picture-options='zoom'" "$CLOCK" || fail "modo de exibição do wallpaper MATE ausente"
grep -Fq "set_setting org.mate.background picture-filename \"'$WALLPAPER'\"" "$PROFILE/overlay-common/usr/local/bin/venom-mate-first-login" || fail "primeiro login não aplica o wallpaper VENOM"
grep -Fq "set_setting org.mate.background picture-options \"'zoom'\"" "$PROFILE/overlay-common/usr/local/bin/venom-mate-first-login" || fail "primeiro login não configura o enquadramento do wallpaper"
grep -Fq "system-db:local" "$PROFILE/overlay-common/etc/dconf/profile/user" || fail "perfil dconf não carrega a base local"
grep -Fq "ExecStart=/usr/bin/dconf update" "$PROFILE/overlay-common/etc/systemd/system/venom-dconf-update.service" || fail "serviço não compila a base dconf"
grep -Fq "Before=display-manager.service" "$PROFILE/overlay-common/etc/systemd/system/venom-dconf-update.service" || fail "dconf não é atualizado antes do gerenciador gráfico"
grep -Fxq "dconf" "$PROFILE/Packages-Desktop" || fail "pacote dconf ausente"
grep -Fq "[org/mate/panel/objects/venom-top-clock/prefs]" "$CLOCK" || fail "preferências do relógio ausentes"
grep -Fq "custom-format='%d/%m/%Y  %H:%M'" "$CLOCK" || fail "data deve aparecer antes da hora no formato DD/MM/AAAA HH:MM"
grep -Fq '[Toplevel top]' "$LAYOUT" || fail "painel superior ausente"
grep -Fq '[Toplevel bottom]' "$LAYOUT" || fail "painel inferior ausente"
grep -Fq "icon-theme='VENOM'" "$PROFILE/overlay-common/etc/dconf/db/local.d/00-venom" || fail "tema de ícones VENOM ausente"
grep -Fq 'group-windows' "$PROFILE/overlay-common/etc/dconf/db/local.d/00-venom" || fail "agrupamento de janelas ausente"
[[ -f "$PROFILE/root-overlay/etc/dconf/db/local.d/00-venom" ]] || fail "root-overlay do sistema instalado não preparado"
[[ -f "$PROFILE/desktop-overlay/etc/dconf/db/local.d/00-venom" ]] || fail "desktop-overlay não preparado"
[[ -f "$PROFILE/live-overlay/etc/dconf/db/local.d/00-venom" ]] || fail "overlay live não preparado"
for overlay in root-overlay desktop-overlay live-overlay; do
  cmp -s "$PROFILE/overlay-common/etc/dconf/db/local.d/00-venom" "$PROFILE/$overlay/etc/dconf/db/local.d/00-venom" || fail "preferências MATE divergentes no overlay $overlay"
  [[ -s "$PROFILE/$overlay$WALLPAPER" ]] || fail "wallpaper VENOM não foi copiado para $overlay"
  cmp -s "$WALLPAPER_FILE" "$PROFILE/$overlay$WALLPAPER" || fail "wallpaper VENOM divergente no overlay $overlay"
  cmp -s "$PROFILE/overlay-common/usr/share/mate-panel/layouts/venom.layout" "$PROFILE/$overlay/usr/share/mate-panel/layouts/venom.layout" || fail "layout MATE divergente no overlay $overlay"
  grep -Fq "custom-format='%d/%m/%Y  %H:%M'" "$PROFILE/$overlay/etc/dconf/db/local.d/00-venom" || fail "relógio dinâmico incorreto no overlay $overlay"
  grep -Fq "group-windows='always'" "$PROFILE/$overlay/etc/dconf/db/local.d/00-venom" || fail "agrupamento de janelas ausente no overlay $overlay"
done
[[ -f "$PROFILE/live-overlay/etc/skel/.config/autostart/venom-installer.desktop" ]] || fail "autostart Calamares ausente"
if grep -RniE 'archlinux|geo\.mirror\.pkgbuild\.com|mkarchiso|archiso' "$PROFILE"; then fail "referência Arch no perfil Manjaro"; fi
grep -Fq -- '-k linux618' "$ROOT/scripts/validate-manjaro-build.sh" || fail "buildiso não seleciona linux618 LTS"
grep -Fq -- '-k linux618' "$ROOT/scripts/build-manjaro-iso.sh" || fail "build final não seleciona linux618 LTS"
bash -n "$ROOT/scripts/prepare-manjaro-profile.sh" "$ROOT/scripts/validate-manjaro-profile.sh" "$ROOT/scripts/validate-manjaro-build.sh" "$ROOT/scripts/build-manjaro-iso.sh"
echo "Validação estrutural estática: APROVADA."
echo "A resolução de pacotes, a incorporação real na ISO, o boot e a instalação ainda exigem ambiente Manjaro/VM."
