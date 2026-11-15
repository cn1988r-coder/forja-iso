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
  "$(target /etc/xdg/autostart)" "$(target /usr/share/applications)" "$(target /usr/share/doc/forja-store)" \
  "$(target /etc/systemd/system/multi-user.target.wants)"

BUILD_DIR="${FORJA_PAMAC_BUILD_DIR:-}"
[[ -n "$BUILD_DIR" && -x "$BUILD_DIR/bin/forja-store" && -f "$BUILD_DIR/lib/libpamac-gtk.so" ]] || {
  echo "Binário Forja Store do Pamac não compilado. Execute build-pamac.sh antes de instalar." >&2
  exit 1
}
[[ -f "$BUILD_DIR/share/pamac-11.7.5-forja-source.tar.gz" ]] || {
  echo "Fontes correspondentes do Pamac não encontradas no diretório de compilação." >&2
  exit 1
}
for file in forja_store_core.py forja-update-indicator forja-pacman-transaction forja-pkexec-sudo; do
  [[ -f "$ROOT/src/$file" ]] || { echo "Arquivo obrigatório ausente: $ROOT/src/$file" >&2; exit 1; }
done
install -m 755 "$BUILD_DIR/bin/forja-store" "$(target /usr/lib/forja/forja-store)"
install -m 755 "$BUILD_DIR/lib/libpamac-gtk.so" "$(target /usr/lib/forja/libpamac-gtk.so)"
install -m 644 "$BUILD_DIR/share/pamac-11.7.5-forja-source.tar.gz" "$(target /usr/share/doc/forja-store/pamac-11.7.5-forja-source.tar.gz)"
install -m 644 "$BUILD_DIR/share/build-info.txt" "$(target /usr/share/doc/forja-store/build-info.txt)"
install -m 644 "$ROOT/src/forja_store_core.py" "$(target /usr/lib/forja/forja_store_core.py)"
install -m 755 "$ROOT/src/forja-update-indicator" "$(target /usr/lib/forja/forja-update-indicator)"
install -m 755 "$ROOT/src/forja-pacman-transaction" "$(target /usr/lib/forja/forja-pacman-transaction)"
install -m 755 "$ROOT/src/forja-pkexec-sudo" "$(target /usr/bin/forja-pkexec-sudo)"
install -m 755 "$ROOT/bin/forja-store" "$(target /usr/bin/forja-store)"
install -m 755 "$ROOT/bin/forja-update-indicator" "$(target /usr/bin/forja-update-indicator)"
install -m 644 "$ROOT/icons/forja-store.svg" "$(target /usr/share/icons/hicolor/scalable/apps/forja-store.svg)"
for state in available current error; do
  install -m 644 "$ROOT/icons/forja-update-$state.svg" "$(target /usr/share/icons/hicolor/scalable/status/forja-update-$state.svg)"
done
install -m 644 "$ROOT/forja-update-indicator.desktop" "$(target /etc/xdg/autostart/forja-update-indicator.desktop)"
install -m 644 "$ROOT/forja-software.desktop" "$(target /usr/share/applications/forja-software.desktop)"
printf '[Desktop Entry]\nType=Application\nName=Pamac Manager (hidden)\nHidden=true\n' > "$(target /usr/share/applications/org.manjaro.pamac.manager.desktop)"

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
