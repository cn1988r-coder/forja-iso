#!/usr/bin/env bash
set -Eeuo pipefail

[[ "$EUID" -eq 0 ]] || { echo "Execute este instalador com sudo." >&2; exit 1; }
ROOT="$(cd "$(dirname "$0")" && pwd)"
command -v apt-get >/dev/null 2>&1 || { echo "Este instalador requer Ubuntu com APT." >&2; exit 1; }
apt-get update
apt-get install -y python3 python3-apt python3-gi gir1.2-gtk-4.0 gir1.2-gtk-3.0 gir1.2-ayatanaappindicator3-0.1 policykit-1 flatpak
for file in "$ROOT/src/forja-store" "$ROOT/src/forja-apt-transaction" "$ROOT/src/forja-update-indicator"; do
  [[ -f "$file" ]] || { echo "Arquivo ausente: $file" >&2; exit 1; }
done

install -Dm755 "$ROOT/src/forja-store" /usr/bin/forja-store
install -Dm755 "$ROOT/src/forja-apt-transaction" /usr/lib/forja/forja-apt-transaction
install -Dm755 "$ROOT/src/forja-update-indicator" /usr/bin/forja-update-indicator

install -d /usr/share/applications /etc/xdg/autostart
cat > /usr/share/applications/forja-software.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Forja Software
Comment=Aplicativos e atualizações Ubuntu e Flatpak
Exec=forja-store
Icon=system-software-install
Terminal=false
Categories=System;PackageManager;
StartupNotify=true
DESKTOP

cat > /etc/xdg/autostart/forja-update-indicator.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Forja Update Indicator
Comment=Notificações de atualizações Ubuntu e Flatpak
Exec=forja-update-indicator
Icon=software-update-available
Terminal=false
OnlyShowIn=MATE;
X-GNOME-Autostart-enabled=true
DESKTOP

chmod 644 /usr/share/applications/forja-software.desktop /etc/xdg/autostart/forja-update-indicator.desktop
echo "Forja Software instalado. O indicador será iniciado na próxima sessão MATE."
