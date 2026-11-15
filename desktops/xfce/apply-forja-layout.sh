#!/usr/bin/env bash
set -Eeuo pipefail

command -v xfconf-query >/dev/null 2>&1 || exit 0

# Appearance only. The panel layout is provisioned system-wide by
# /etc/xdg/xfce4/panel/default.xml and copied into /etc/skel at image build.
GTK_THEME="adw-gtk3-dark"
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

# GTK 3/4, cursor and window decorations.
set_prop xsettings /Net/ThemeName string "$GTK_THEME"
set_prop xsettings /Net/IconThemeName string "$ICON_THEME"
set_prop xsettings /Gtk/CursorThemeName string "$CURSOR_THEME"
set_prop xsettings /Gtk/CursorThemeSize int 24
set_prop xsettings /Gtk/FontName string "Noto Sans 10"
set_prop xfwm4 /general/theme string "Materia-dark"
set_prop xfwm4 /general/use_compositing bool true

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" >/dev/null 2>&1 || true
fi

# Apply the Forja wallpaper to every configured monitor/workspace.
WALLPAPER="/usr/share/backgrounds/forja-os-xfce.svg"
if [[ -f "$WALLPAPER" ]]; then
  mapfile -t wallpaper_properties < <(
    xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$' || true
  )
  if (("${#wallpaper_properties[@]}")); then
    for property in "${wallpaper_properties[@]}"; do
      xfconf-query -c xfce4-desktop -p "$property" -s "$WALLPAPER" >/dev/null 2>&1 || true
    done
  else
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image \
      --create -t string -s "$WALLPAPER" >/dev/null 2>&1 || true
  fi
fi
