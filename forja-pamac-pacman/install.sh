#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Execute como root."; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESTDIR="${DESTDIR:-}"
target() { printf "%s%s" "$DESTDIR" "$1"; }
. /etc/os-release
[[ "${ID:-}" == manjaro ]] || { echo "Forja Store é exclusiva da base Manjaro."; exit 1; }
ICON="$ROOT/icons/forja-store.svg"
install -d "$(target /usr/lib/forja)" "$(target /usr/bin)" \
  "$(target /usr/share/icons/hicolor/scalable/apps)" \
  "$(target /usr/share/icons/hicolor/scalable/status)" \
  "$(target /etc/xdg/autostart)" "$(target /usr/share/applications)" \
  "$(target /etc/systemd/system/multi-user.target.wants)"
install -m 755 "$ROOT/src/forja-store" "$(target /usr/lib/forja/forja-store)"
install -m 755 "$ROOT/src/forja-update-indicator" "$(target /usr/lib/forja/forja-update-indicator)"
install -m 755 "$ROOT/src/forja-pacman-transaction" "$(target /usr/lib/forja/forja-pacman-transaction)"
install -m 755 "$ROOT/src/forja-pkexec-sudo" "$(target /usr/lib/forja/forja-pkexec-sudo)"
install -m 755 "$ROOT/bin/forja-store" "$(target /usr/bin/forja-store)"
install -m 755 "$ROOT/bin/forja-update-indicator" "$(target /usr/bin/forja-update-indicator)"
install -m 644 "$ICON" "$(target "/usr/share/icons/hicolor/scalable/apps/$(basename "$ICON")")"
install -m 644 "$ROOT/icons/forja-update-available.svg" "$(target /usr/share/icons/hicolor/scalable/status/forja-update-available.svg)"
install -m 644 "$ROOT/icons/forja-update-current.svg" "$(target /usr/share/icons/hicolor/scalable/status/forja-update-current.svg)"
install -m 644 "$ROOT/icons/forja-update-error.svg" "$(target /usr/share/icons/hicolor/scalable/status/forja-update-error.svg)"
install -m 644 "$ROOT/forja-update-indicator.desktop" "$(target /etc/xdg/autostart/forja-update-indicator.desktop)"
install -m 644 "$ROOT/forja-software.desktop" "$(target /usr/share/applications/forja-software.desktop)"
cat > "$(target /etc/systemd/system/forja-flatpak-setup.service)" <<'UNIT'
[Unit]
Description=Configure Flathub for Forja OS
Wants=network-online.target
After=network-online.target
ConditionPathExists=/usr/bin/flatpak

[Service]
Type=oneshot
ExecStart=/usr/bin/flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
ln -sfn ../forja-flatpak-setup.service "$(target /etc/systemd/system/multi-user.target.wants/forja-flatpak-setup.service)"
cat > "$(target /etc/systemd/system/forja-icon-cache.service)" <<'UNIT'
[Unit]
Description=Refresh Forja OS application and status icons
Before=display-manager.service
ConditionPathExists=/usr/share/icons/hicolor/index.theme
ConditionPathExists=/usr/bin/gtk-update-icon-cache

[Service]
Type=oneshot
ExecStart=/usr/bin/gtk-update-icon-cache -f /usr/share/icons/hicolor
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
ln -sfn ../forja-icon-cache.service "$(target /etc/systemd/system/multi-user.target.wants/forja-icon-cache.service)"
if [[ -z "$DESTDIR" ]]; then
  systemctl daemon-reload
  systemctl enable --now forja-flatpak-setup.service
  systemctl enable --now forja-icon-cache.service
fi
echo "Forja Store, indicador, yay/AUR e configuração inicial do Flathub instalados."
