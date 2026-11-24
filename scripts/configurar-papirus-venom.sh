#!/usr/bin/env bash
set -Eeuo pipefail

# VENOM OS XFCE: Papirus Dark com pastas azuis.
# Base Arch Linux. Não instala nem configura temas Kora ou Coral.

if [[ ${EUID} -ne 0 ]]; then
  echo "Execute como root: sudo bash $0"
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
  echo "Este script exige Arch Linux ou derivado com pacman."
  exit 1
fi

pacman -S --needed --noconfirm papirus-icon-theme
command -v papirus-folders >/dev/null 2>&1 || { echo 'Instale papirus-folders-git do AUR antes de aplicar as pastas azuis.' >&2; exit 1; }

install -d -m 0755 /etc/skel/.config/gtk-3.0
install -d -m 0755 /etc/skel/.config/gtk-4.0
install -d -m 0755 /etc/skel/.icons/default
printf '[Settings]\ngtk-icon-theme-name=Papirus-Dark\n' > /etc/skel/.config/gtk-3.0/settings.ini
cp /etc/skel/.config/gtk-3.0/settings.ini /etc/skel/.config/gtk-4.0/settings.ini

cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
</channel>
XML

install -d -m 0755 /etc/systemd/system
cat > /etc/systemd/system/venom-papirus-blue.service <<'UNIT'
[Unit]
Description=Apply Papirus Blue folder icons for VENOM OS
After=local-fs.target
ConditionPathExists=!/var/lib/venom-os/papirus-blue-applied

[Service]
Type=oneshot
ExecStart=/usr/bin/papirus-folders -C blue --theme Papirus-Dark
ExecStartPost=/usr/bin/install -Dm644 /dev/null /var/lib/venom-os/papirus-blue-applied
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT

systemctl enable venom-papirus-blue.service
echo "Papirus Dark + pastas azuis configurado para VENOM OS XFCE."
echo "A configuração padrão será aplicada a novos usuários; reinicie para aplicar o serviço."
