#!/usr/bin/env bash
set -Eeuo pipefail
# Executado pelo usuário da sessão XFCE, sem sudo.
command -v xfconf-query >/dev/null 2>&1 || exit 0
command -v xfce4-panel >/dev/null 2>&1 || exit 0

ICON_THEME="Papirus-Dark"
CURSOR_THEME="Bibata-Modern-Ice"
GTK_THEME="Materia-dark"
ICON_FILE="/usr/share/icons/hicolor/scalable/apps/forja.svg"
WALLPAPER="/usr/share/backgrounds/forja/forja-xfce.svg"

# Aparência exclusiva do XFCE.
xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$GTK_THEME" 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "$ICON_THEME" 2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/CursorThemeName -n -t string -s "$CURSOR_THEME" 2>/dev/null || true

# Painel inferior e botão Whisker com o ícone Forja.
xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/position -n -t string -s 'p=8;x=0;y=0'
xfconf-query -c xfce4-panel -p /panels/panel-1/length -n -t int -s 100
xfconf-query -c xfce4-panel -p /panels/panel-1/length-adjust -n -t bool -s false
xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t int -s 42
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -n -t int -s 0
xfconf-query -c xfce4-panel -p /panels/panel-1/position-locked -n -t bool -s true
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n -a -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 -t int -s 5
xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s whiskermenu
xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s tasklist
xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s systray
xfconf-query -c xfce4-panel -p /plugins/plugin-4 -n -t string -s clock
xfconf-query -c xfce4-panel -p /plugins/plugin-5 -n -t string -s showdesktop
xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-title -n -t string -s "Forja" 2>/dev/null || true

# O nome só é aplicado quando o SVG estiver instalado. Assim não fica ícone quebrado.
if [[ -s "$ICON_FILE" ]]; then
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon -n -t string -s "forja" 2>/dev/null || true
else
  echo "Ícone Forja ainda não instalado; mantendo ícone padrão do Whisker." >&2
fi

# Define o wallpaper em todos os espaços de trabalho/monitores já reconhecidos pelo XFCE.
if [[ -s "$WALLPAPER" ]]; then
  mapfile -t backdrop_props < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/last-image$' || true)
  if (("${#backdrop_props[@]}" == 0)); then
    backdrop_props=("/backdrop/screen0/monitor0/workspace0/last-image")
  fi
  for prop in "${backdrop_props[@]}"; do
    xfconf-query -c xfce4-desktop -p "$prop" -n -t string -s "$WALLPAPER" 2>/dev/null || true
  done
fi

xfce4-panel --restart
