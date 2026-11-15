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
PANEL_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/xfce4/panel"
DOCKLIKE_CONFIG="$PANEL_CONFIG_DIR/docklike-2.rc"

# Aparência exclusiva do XFCE.
xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$GTK_THEME" 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "$ICON_THEME" 2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/CursorThemeName -n -t string -s "$CURSOR_THEME" 2>/dev/null || true

# Docklike no lugar da lista tradicional de janelas.
mkdir -p "$PANEL_CONFIG_DIR"
cat > "$DOCKLIKE_CONFIG" <<'EOF'
[user]
showPreviews=true
pinned=thunar;firefox;
indicatorStyle=1
inactiveIndicatorStyle=1
forceIconSize=false
keyComboActive=false
keyAloneActive=false
inactiveColor=rgb(119,118,123)
EOF

# Painel inferior no estilo Big Community: menu, dock, espaço expansível,
# bandeja, áudio, energia, área de transferência, relógio e mostrar área de trabalho.
xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/position -n -t string -s 'p=8;x=0;y=0'
xfconf-query -c xfce4-panel -p /panels/panel-1/length -n -t int -s 100
xfconf-query -c xfce4-panel -p /panels/panel-1/length-adjust -n -t bool -s true
xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t int -s 40
xfconf-query -c xfce4-panel -p /panels/panel-1/nrows -n -t uint -s 1
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -n -t uint -s 0
xfconf-query -c xfce4-panel -p /panels/panel-1/position-locked -n -t bool -s true
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n -a \
  -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 -t int -s 5 \
  -t int -s 6 -t int -s 7 -t int -s 8 -t int -s 9

xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s whiskermenu
xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s docklike
xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s separator
xfconf-query -c xfce4-panel -p /plugins/plugin-3/expand -n -t bool -s true
xfconf-query -c xfce4-panel -p /plugins/plugin-3/style -n -t uint -s 0
xfconf-query -c xfce4-panel -p /plugins/plugin-4 -n -t string -s systray
xfconf-query -c xfce4-panel -p /plugins/plugin-5 -n -t string -s pulseaudio
xfconf-query -c xfce4-panel -p /plugins/plugin-6 -n -t string -s power-manager-plugin
xfconf-query -c xfce4-panel -p /plugins/plugin-7 -n -t string -s xfce4-clipman-plugin
xfconf-query -c xfce4-panel -p /plugins/plugin-8 -n -t string -s clock
xfconf-query -c xfce4-panel -p /plugins/plugin-9 -n -t string -s showdesktop

# Ícone da Forja no botão Whisker.
if [[ -s "$ICON_FILE" ]]; then
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon -n -t string -s "forja" 2>/dev/null || true
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-title -n -t string -s "Forja" 2>/dev/null || true
fi

# Super abre o Whisker, como no Big Community.
xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Super_L \
  -n -t string -s "xfce4-popup-whiskermenu" 2>/dev/null || true

# Wallpaper Forja em todos os espaços de trabalho/monitores reconhecidos pelo XFCE.
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
