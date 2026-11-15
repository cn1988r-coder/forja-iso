#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESTDIR="${DESTDIR:-}"
target() { printf "%s%s" "$DESTDIR" "$1"; }
if [[ -z "$DESTDIR" ]]; then
  . /etc/os-release
  [[ "${ID:-}" == manjaro ]] || { echo "Forja Store é exclusiva da base Manjaro." >&2; exit 1; }
fi

install -d "$(target /usr/lib/forja)" "$(target /usr/bin)" \
  "$(target /usr/share/icons/hicolor/scalable/apps)" \
  "$(target /usr/share/icons/hicolor/scalable/status)" \
  "$(target /etc/xdg/autostart)" "$(target /usr/share/applications)" \
  "$(target /etc/systemd/system/multi-user.target.wants)"

for file in forja-store forja_store_core.py forja-update-indicator forja-pacman-transaction; do
  [[ -f "$ROOT/src/$file" ]] || { echo "Arquivo obrigatório ausente: $ROOT/src/$file" >&2; exit 1; }
done
install -m 755 "$ROOT/src/forja-store" "$(target /usr/lib/forja/forja-store)"
install -m 644 "$ROOT/src/forja_store_core.py" "$(target /usr/lib/forja/forja_store_core.py)"
install -m 755 "$ROOT/src/forja-update-indicator" "$(target /usr/lib/forja/forja-update-indicator)"
install -m 755 "$ROOT/src/forja-pacman-transaction" "$(target /usr/lib/forja/forja-pacman-transaction)"
install -m 755 "$ROOT/bin/forja-store" "$(target /usr/bin/forja-store)"
install -m 755 "$ROOT/bin/forja-update-indicator" "$(target /usr/bin/forja-update-indicator)"
install -m 644 "$ROOT/icons/forja-store.svg" "$(target /usr/share/icons/hicolor/scalable/apps/forja-store.svg)"
for state in available current error; do
  install -m 644 "$ROOT/icons/forja-update-$state.svg" "$(target /usr/share/icons/hicolor/scalable/status/forja-update-$state.svg)"
done
install -m 644 "$ROOT/forja-update-indicator.desktop" "$(target /etc/xdg/autostart/forja-update-indicator.desktop)"
install -m 644 "$ROOT/forja-polkit-agent.desktop" "$(target /etc/xdg/autostart/forja-polkit-agent.desktop)"
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
echo "Forja Store com backend Pamac, catálogo AppStream, indicador XFCE e Flathub instalados."
