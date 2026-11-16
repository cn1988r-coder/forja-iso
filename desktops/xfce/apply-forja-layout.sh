#!/usr/bin/env bash
set -Eeuo pipefail

command -v xfconf-query >/dev/null 2>&1 || exit 0

# Apply the same Forja menu styling to the actual logged-in account.
# /etc/skel alone is insufficient when the Live user already exists.
FORJA_CONFIG_DIR="$HOME/.config"
install -d "$FORJA_CONFIG_DIR/gtk-3.0" "$FORJA_CONFIG_DIR/xfce4/panel"
if [[ -s /usr/share/forja/forja-gtk.css ]]; then
  install -m644 /usr/share/forja/forja-gtk.css "$FORJA_CONFIG_DIR/gtk-3.0/gtk.css"
fi
if [[ -s /usr/share/forja/forja-whiskermenu.rc ]]; then
  install -m644 /usr/share/forja/forja-whiskermenu.rc "$FORJA_CONFIG_DIR/xfce4/panel/whiskermenu-1.rc"
fi
# Reload the panel so its GTK process reads the new CSS and Whisker settings.
if command -v xfce4-panel >/dev/null 2>&1; then
  xfce4-panel -r >/dev/null 2>&1 || true
fi

# The panel and black background are provisioned before the first login.
# This login hook applies the Forja menu CSS, desktop theme and decorations.
GTK_THEME="Adwaita-dark"
ICON_THEME="Papirus-Dark"
CURSOR_THEME="Bibata-Modern-Classic"

set_prop() {
  local channel="$1" property="$2" type="$3" value="$4"
  if xfconf-query -c "$channel" -p "$property" -s "$value" >/dev/null 2>&1; then
    return 0
  fi
  xfconf-query -c "$channel" -p "$property" --create -t "$type" -s "$value" >/dev/null 2>&1 || {
    printf 'Aviso: propriedade XFCE não aplicada: %s/%s\n' "$channel" "$property" >&2
  }
}

set_prop xsettings /Net/ThemeName string "$GTK_THEME"
set_prop xsettings /Net/IconThemeName string "$ICON_THEME"
set_prop xsettings /Gtk/CursorThemeName string "$CURSOR_THEME"
set_prop xsettings /Gtk/CursorThemeSize int 24
set_prop xsettings /Gtk/FontName string "Noto Sans 10"
set_prop xfwm4 /general/theme string "Adwaita-dark"
set_prop xfwm4 /general/use_compositing bool true

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" >/dev/null 2>&1 || true
fi
