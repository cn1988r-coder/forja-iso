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
               mate-panel mate-media polkit mate-polkit papirus-icon-theme; do
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

live_dconf_hash="$(sha256sum "$LIVE_DCONF" | awk '{print $1}')"
installed_dconf_hash="$(sha256sum "$INSTALLED_DCONF" | awk '{print $1}')"
[[ "$live_dconf_hash" == "$installed_dconf_hash" ]] ||
  fail "preferências dconf live e instaladas divergem"

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
grep -Fq 'systemctl start NetworkManager.service' "$LIVE/root/venom-live-setup" ||
  fail "NetworkManager não é iniciado na sessão live"
grep -Fq 'systemctl start bluetooth.service' "$LIVE/root/venom-live-setup" ||
  fail "Bluetooth não é iniciado na sessão live"
grep -Fq 'useradd --create-home --groups wheel,audio,video,storage' \
  "$LIVE/root/venom-live-setup" ||
  fail "usuário live não recebe os grupos necessários para autenticação e dispositivos"

for service in NetworkManager bluetooth; do
  link="$OVERLAY/etc/systemd/system/multi-user.target.wants/$service.service"
  [[ -L "$link" ]] || fail "serviço $service não está habilitado no overlay instalado"
done

require_arch_file() {
  local package="$1"
  local expected_path="$2"

  if ! pacman -Fl "$package" |
       awk -v expected="$expected_path" 'index($0, expected) { found=1 } END { exit !found }'; then
    printf 'Arquivos relacionados encontrados em %s:\n' "$package" >&2
    pacman -Fl "$package" |
      awk 'tolower($0) ~ /gvc|mate-panel|dbus|volume|bluetooth|nm-applet/ { print }' >&2
    fail "arquivo oficial ausente: $package/$expected_path"
  fi
}

if command -v pacman >/dev/null 2>&1; then
  pacman -Fl network-manager-applet >/dev/null 2>&1 ||
    fail "banco de arquivos dos repositórios Arch indisponível; execute pacman -Fy antes da validação"

  # REDE: autostart, executável e ícones de estado Wi-Fi/Ethernet.
  require_arch_file network-manager-applet etc/xdg/autostart/nm-applet.desktop
  require_arch_file network-manager-applet usr/bin/nm-applet
  require_arch_file network-manager-applet usr/share/icons/hicolor/22x22/apps/nm-device-wired.png
  require_arch_file network-manager-applet usr/share/icons/hicolor/22x22/apps/nm-no-connection.png

  # BLUETOOTH: autostart, applet, ícone de bandeja e serviço BlueZ.
  require_arch_file blueman etc/xdg/autostart/blueman.desktop
  require_arch_file blueman usr/bin/blueman-applet
  require_arch_file blueman usr/share/icons/hicolor/22x22/status/blueman-tray.png
  require_arch_file bluez usr/lib/systemd/system/bluetooth.service

  # Agente gráfico de autorização necessário para operações administrativas.
  require_arch_file mate-polkit etc/xdg/autostart/polkit-mate-authentication-agent-1.desktop
  require_arch_file mate-polkit usr/lib/mate-polkit/polkit-mate-authentication-agent-1

  # VOLUME/ÁUDIO: applet MATE, ativação D-Bus, mascaramento do ícone duplicado
  # e ícones de volume fornecidos pelo tema Papirus-Dark selecionado.
  require_arch_file mate-media usr/share/mate-panel/applets/org.mate.applets.GvcApplet.mate-panel-applet
  require_arch_file mate-media usr/share/dbus-1/services/org.mate.panel.applet.GvcAppletFactory.service
  require_arch_file mate-media usr/lib/mate-media/mate-volume-control-applet
  require_arch_file mate-media etc/xdg/autostart/mate-volume-control-status-icon.desktop
  require_arch_file papirus-icon-theme usr/share/icons/Papirus-Dark/22x22/actions/audio-volume-high.svg
  require_arch_file papirus-icon-theme usr/share/icons/Papirus-Dark/22x22/actions/audio-volume-muted.svg

  # Serviços e pilha de áudio dos repositórios oficiais.
  require_arch_file networkmanager usr/lib/systemd/system/NetworkManager.service
  require_arch_file pipewire usr/lib/systemd/user/pipewire.service
  require_arch_file pipewire usr/lib/systemd/user/pipewire.socket
  require_arch_file pipewire-pulse usr/lib/systemd/user/pipewire-pulse.service
  require_arch_file pipewire-pulse usr/lib/systemd/user/pipewire-pulse.socket
  require_arch_file wireplumber usr/lib/systemd/user/wireplumber.service
else
  printf 'AVISO: Pacman ausente; a conferência dos arquivos oficiais foi ignorada.\n'
fi

printf 'OK: REDE: pacote, autostart, executável, ícones, Notification Area e serviço conferidos estaticamente.\n'
printf 'OK: BLUETOOTH: BlueZ, Blueman, autostart, executável, ícone, Notification Area e serviço conferidos estaticamente.\n'
printf 'OK: VOLUME/ÁUDIO: Gvc, ativação D-Bus, PipeWire, WirePlumber, sockets, ícones Papirus e ausência de ícone duplicado conferidos estaticamente.\n'
printf 'OK: AUTORIZAÇÃO GRÁFICA: agente MATE Polkit e grupos do usuário live conferidos estaticamente.\n'
printf 'PENDENTE: comprovar os três indicadores visíveis e funcionais após login e reinicialização em sessão gráfica/VM.\n'
