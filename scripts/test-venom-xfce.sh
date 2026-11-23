#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/manjaro/venom-xfce"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
for f in profile.conf Packages-Desktop Packages-Live Packages-Root Packages-Mhwd; do
  [[ -e "$PROFILE/$f" ]] || fail "arquivo ausente: $f"
done
for f in Packages-Live Packages-Root Packages-Mhwd; do
  [[ -L "$PROFILE/$f" ]] || fail "$f precisa apontar para shared oficial"
done
for pkg in xfce4-session xfce4-panel xfwm4 xfdesktop thunar xfce4-whiskermenu-plugin lightdm lightdm-gtk-greeter pamac-gtk; do
  grep -Fxq "$pkg" "$PROFILE/Packages-Desktop" || fail "pacote obrigatório ausente: $pkg"
done
if grep -Eiq 'mate-panel|mate-session|marco|caja|brisk-menu|venom-mate' "$PROFILE/Packages-Desktop" "$PROFILE/profile.conf"; then
  fail "pacote/configuração MATE encontrado no perfil XFCE"
fi
grep -Fq 'displaymanager="lightdm"' "$PROFILE/profile.conf" || fail "LightDM não definido"
[[ -s "$PROFILE/desktop-overlay/etc/lightdm/lightdm-gtk-greeter.conf" ]] || fail "greeter LightDM ausente"
[[ -s "$PROFILE/desktop-overlay/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" ]] || fail "configuração visual XFCE ausente"
grep -Fq 'Materia-dark' "$PROFILE/desktop-overlay/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" || fail "tema escuro não configurado"
grep -Fq 'Papirus-Dark' "$PROFILE/desktop-overlay/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" || fail "ícones não configurados"
bash -n "$ROOT/scripts/test-venom-xfce.sh" "$ROOT/scripts/validate-manjaro-build.sh" "$ROOT/scripts/build-manjaro-iso.sh"
printf 'TESTE ESTRUTURAL XFCE: APROVADO\n'
