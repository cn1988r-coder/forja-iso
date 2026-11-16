#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${DESTDIR:-}"

# Idioma padrão do sistema e da sessão Live: português brasileiro.
install -Dm644 /dev/stdin "$DEST/etc/locale.conf" <<'LOCALECONF'
LANG=pt_BR.UTF-8
LANGUAGE=pt_BR:pt:en
LOCALECONF
install -Dm644 /dev/stdin "$DEST/etc/locale.gen" <<'LOCALEGEN'
pt_BR.UTF-8 UTF-8
en_US.UTF-8 UTF-8
LOCALEGEN
# Gere os dados de locale agora, tanto em um DESTDIR quanto no chroot Live.
# Isso garante que pt_BR.UTF-8 exista antes do primeiro login.
command -v localedef >/dev/null 2>&1 || {
  echo "ERRO: localedef é necessário para gerar pt_BR.UTF-8 na imagem." >&2
  exit 1
}
if [[ -n "$DEST" ]]; then
  install -d "$DEST/usr/lib/locale"
  localedef --prefix="$DEST" -i pt_BR -f UTF-8 pt_BR.UTF-8
  localedef --prefix="$DEST" -i en_US -f UTF-8 en_US.UTF-8
else
  localedef -i pt_BR -f UTF-8 pt_BR.UTF-8
  localedef -i en_US -f UTF-8 en_US.UTF-8
fi

install -Dm644 "$ROOT/forja-flame.svg" "$DEST/usr/share/icons/hicolor/scalable/apps/forja.svg"
install -Dm644 "$ROOT/forja-black-wallpaper.svg" "$DEST/usr/share/backgrounds/forja-black.svg"

install -Dm755 "$ROOT/apply-forja-layout.sh" "$DEST/usr/lib/forja/apply-xfce-layout.sh"
install -Dm644 "$ROOT/forja-xfce-appearance.desktop" "$DEST/etc/xdg/autostart/forja-xfce-appearance.desktop"
# Shelly opens with the user's XFCE session; its UI starts its notification service.
install -Dm644 "$ROOT/shelly-autostart.desktop" "$DEST/etc/xdg/autostart/shelly.desktop"
install -Dm644 "$ROOT/forja-gtk.css" "$DEST/etc/skel/.config/gtk-3.0/gtk.css"
# Keep the canonical theme and Whisker defaults available to the login hook.
install -Dm644 "$ROOT/forja-gtk.css" "$DEST/usr/share/forja/forja-gtk.css"
install -Dm644 "$ROOT/forja-whiskermenu.rc" "$DEST/usr/share/forja/forja-whiskermenu.rc"
install -Dm644 "$ROOT/forja-whiskermenu.rc" "$DEST/etc/skel/.config/xfce4/panel/whiskermenu-1.rc"

# A single system-wide bottom panel: Whisker + DockbarX + system tray + clock.
install -Dm644 "$ROOT/panel-default.xml" "$DEST/etc/xdg/xfce4/panel/default.xml"
install -Dm644 "$ROOT/forja-xfce-desktop.xml" "$DEST/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"

# Seed the Forja XFCE defaults for the live account and newly created users.
install -Dm644 "$ROOT/panel-default.xml" \
  "$DEST/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
install -Dm644 "$ROOT/forja-xfce-desktop.xml" \
  "$DEST/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"

if [[ -z "$DEST" ]] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -f /usr/share/icons/hicolor || true
fi
echo "Forja OS XFCE: painel, DockbarX, autostart Shelly, tema visual e Plymouth instalados nos overlays."
