#!/usr/bin/env bash
set -Eeuo pipefail

command -v xfconf-query >/dev/null 2>&1 || exit 0
command -v xfce4-panel >/dev/null 2>&1 || exit 0

# Forja XFCE visual identity: Adwaita-inspired dark GTK, neutral Papirus and Bibata.
GTK_THEME="adw-gtk3-dark"
ICON_THEME="Papirus-Dark"
CURSOR_THEME="Bibata-Modern-Ice"
PANEL_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/xfce4/panel"
DOCKLIKE_CONFIG="$PANEL_CONFIG_DIR/docklike-2.rc"
DOCKLIKE_CSS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/xfce4-docklike-plugin"

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
set_prop xsettings /Gtk/FontName string "Cantarell 10"

# Keep Papirus folders neutral instead of introducing accent colors.
if command -v papirus-folders >/dev/null 2>&1; then
  papirus-folders -C grey --theme "$ICON_THEME" >/dev/null 2>&1 || true
fi

# GTK 4 and libadwaita applications use the desktop dark preference.
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" >/dev/null 2>&1 || true
fi

mkdir -p "$PANEL_CONFIG_DIR"
cat > "$DOCKLIKE_CONFIG" <<'DOCKLIKE'
[user]
showPreviews=false
pinned=thunar;firefox;
indicatorStyle=1
inactiveIndicatorStyle=1
indicatorOrientation=1
indicatorColorFromTheme=false
indicatorColor=rgb(232,232,232)
forceIconSize=false
keyComboActive=false
keyAloneActive=false
inactiveColor=rgb(145,145,145)
showWindowCount=false
DOCKLIKE

mkdir -p "$DOCKLIKE_CSS_DIR"
cat > "$DOCKLIKE_CSS_DIR/gtk.css" <<'DOCKLIKE_CSS'
/* Forja Docklike: compact neutral indicators and restrained hover states. */
#docklike-plugin { background-color: transparent; }
.group { border-radius: 9px; padding: 3px; }
.hover_group { background-color: rgba(255,255,255,0.08); }
.menu {
  background-color: #242424;
  color: #f2f2f2;
  border: 1px solid #454545;
  border-radius: 10px;
}
.menu_item { color: #e8e8e8; }
.hover_menu_item { background-color: rgba(255,255,255,0.09); }
DOCKLIKE_CSS

# Bottom panel with Whisker, Docklike, tray and system controls.
xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 >/dev/null 2>&1 || true
set_prop xfce4-panel /panels/panel-1/position string 'p=8;x=0;y=0'
set_prop xfce4-panel /panels/panel-1/length uint 100
set_prop xfce4-panel /panels/panel-1/length-adjust bool true
set_prop xfce4-panel /panels/panel-1/size uint 42
set_prop xfce4-panel /panels/panel-1/nrows uint 1
set_prop xfce4-panel /panels/panel-1/autohide-behavior uint 0
set_prop xfce4-panel /panels/panel-1/position-locked bool true
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -a \
  -t int -s 1 -t int -s 2 -t int -s 7 -t int -s 9 -t int -s 4 \
  -t int -s 3 -t int -s 6 -t int -s 10 -t int -s 5 -t int -s 8 >/dev/null 2>&1 || true
set_prop xfce4-panel /plugins/plugin-1 string whiskermenu
set_prop xfce4-panel /plugins/plugin-2 string docklike
set_prop xfce4-panel /plugins/plugin-3 string pulseaudio
set_prop xfce4-panel /plugins/plugin-4 string systray
set_prop xfce4-panel /plugins/plugin-5 string clock
set_prop xfce4-panel /plugins/plugin-6 string power-manager-plugin
set_prop xfce4-panel /plugins/plugin-7 string separator
set_prop xfce4-panel /plugins/plugin-7/expand bool true
set_prop xfce4-panel /plugins/plugin-7/style uint 0
set_prop xfce4-panel /plugins/plugin-8 string showdesktop
set_prop xfce4-panel /plugins/plugin-9 string notification-plugin
set_prop xfce4-panel /plugins/plugin-10 string xfce4-clipman-plugin
set_prop xfce4-panel /plugins/plugin-1/button-icon string forja
set_prop xfce4-panel /plugins/plugin-1/button-title string "Forja OS"
set_prop xfce4-keyboard-shortcuts /commands/custom/Super_L string xfce4-popup-whiskermenu

xfce4-panel --restart
