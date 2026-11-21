#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE="$ROOT/build/airootfs"
OVERLAY="$ROOT/build/install-overlay"
LIVE_LAYOUT="$LIVE/usr/share/mate-panel/layouts/venom.layout"
INSTALLED_LAYOUT="$OVERLAY/usr/share/mate-panel/layouts/venom.layout"
LIVE_DCONF="$LIVE/etc/dconf/db/local.d/00-venom"
INSTALLED_DCONF="$OVERLAY/etc/dconf/db/local.d/00-venom"
LIVE_VOLUME_AUTOSTART="$LIVE/etc/xdg/autostart/mate-volume-control-status-icon.desktop"
INSTALLED_VOLUME_AUTOSTART="$OVERLAY/etc/xdg/autostart/mate-volume-control-status-icon.desktop"

fail() {
  printf 'FALHA: %s\n' "$*" >&2
  exit 1
}

for package in networkmanager network-manager-applet bluez bluez-utils blueman \
               pipewire pipewire-audio pipewire-alsa pipewire-pulse wireplumber \
               mate-panel mate-media; do
  grep -Fxq "$package" "$ROOT/build/packages.x86_64" ||
    fail "pacote live ausente: $package"
  grep -Fxq "$package" "$ROOT/build/install-packages.x86_64" ||
    fail "pacote do sistema instalado ausente: $package"
done

for file in "$LIVE_LAYOUT" "$INSTALLED_LAYOUT" "$LIVE_DCONF" "$INSTALLED_DCONF" \
            "$LIVE_VOLUME_AUTOSTART" "$INSTALLED_VOLUME_AUTOSTART"; do
  [[ -s "$file" ]] || fail "configuração ausente: $file"
done

live_layout_hash="$(sha256sum "$LIVE_LAYOUT" | awk '{print $1}')"
installed_layout_hash="$(sha256sum "$INSTALLED_LAYOUT" | awk '{print $1}')"
[[ "$live_layout_hash" == "$installed_layout_hash" ]] ||
  fail "layout do painel live e instalado divergem"

for layout in "$LIVE_LAYOUT" "$INSTALLED_LAYOUT"; do
  [[ "$(grep -Fc 'NotificationAreaAppletFactory::NotificationArea' "$layout")" -eq 1 ]] ||
    fail "Notification Area deve existir exatamente uma vez em $layout"
  [[ "$(grep -Fc 'GvcAppletFactory::GvcApplet' "$layout")" -eq 1 ]] ||
    fail "Gvc volume applet deve existir exatamente uma vez em $layout"
done

for dconf_file in "$LIVE_DCONF" "$INSTALLED_DCONF"; do
  grep -Fq "default-layout='venom'" "$dconf_file" ||
    fail "layout VENOM não é o padrão em $dconf_file"
done

for autostart in "$LIVE_VOLUME_AUTOSTART" "$INSTALLED_VOLUME_AUTOSTART"; do
  grep -Fxq 'Hidden=true' "$autostart" ||
    fail "ícone de volume duplicado não foi desativado em $autostart"
done

grep -Fq 'systemctl enable NetworkManager.service bluetooth.service lightdm.service' \
  "$LIVE/root/venom-live-setup" ||
  fail "serviços de rede, Bluetooth e LightDM não são habilitados na sessão live"

for service in NetworkManager bluetooth; do
  link="$OVERLAY/etc/systemd/system/multi-user.target.wants/$service.service"
  [[ -L "$link" ]] || fail "serviço $service não está habilitado no overlay instalado"
done

if command -v pacman >/dev/null 2>&1; then
  if pacman -Fl network-manager-applet >/dev/null 2>&1; then
    pacman -Fl network-manager-applet | grep -Fq 'etc/xdg/autostart/nm-applet.desktop' ||
      fail "pacote oficial não fornece autostart do nm-applet"
    pacman -Fl network-manager-applet | grep -Fq 'usr/bin/nm-applet' ||
      fail "executável nm-applet ausente no pacote oficial"
    pacman -Fl blueman | grep -Fq 'etc/xdg/autostart/blueman.desktop' ||
      fail "pacote oficial não fornece autostart do Blueman"
    pacman -Fl blueman | grep -Fq 'usr/bin/blueman-applet' ||
      fail "executável blueman-applet ausente no pacote oficial"
    pacman -Fl networkmanager | grep -Fq 'usr/lib/systemd/system/NetworkManager.service' ||
      fail "serviço NetworkManager.service ausente no pacote oficial"
    pacman -Fl bluez | grep -Fq 'usr/lib/systemd/system/bluetooth.service' ||
      fail "serviço bluetooth.service ausente no pacote oficial"
    pacman -Fl mate-media | grep -Fq 'usr/share/mate-panel/applets/org.mate.applets.GvcApplet.mate-panel-applet' ||
      fail "pacote oficial não fornece o applet Gvc do painel"
    pacman -Fl mate-media | grep -Fq 'etc/xdg/autostart/mate-volume-control-status-icon.desktop' ||
      fail "arquivo de autostart do ícone de volume não foi localizado para mascaramento"
  else
    printf 'AVISO: banco de arquivos do Pacman indisponível; verificação dos arquivos upstream foi ignorada.\n'
  fi
fi

printf 'OK: REDE: NetworkManager, nm-applet e Notification Area configurados estaticamente.\n'
printf 'OK: BLUETOOTH: BlueZ, Blueman, autostart e serviço configurados estaticamente.\n'
printf 'OK: VOLUME/ÁUDIO: Gvc no painel, PipeWire com áudio e ícone duplicado desativado.\n'
printf 'PENDENTE: comprovar os três indicadores visíveis e funcionais após login e reinicialização em sessão gráfica/VM.\n'
