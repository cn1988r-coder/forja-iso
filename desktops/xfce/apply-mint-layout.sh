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

# Atualiza uma propriedade existente ou cria uma nova, sem falhar em instalações limpas.
set_prop() {
  local channel="$1" property="$2" type="$3" value="$4"
  if xfconf-query -c "$channel" -p "$property" -s "$value" >/dev/null 2>&1; then
    return 0
  fi
  xfconf-query -c "$channel" -p "$property" --create -t "$type" -s "$value" 2>/dev/null || true
}

# Aparência exclusiva do XFCE.
set_prop xsettings /Net/ThemeName string "$GTK_THEME"
set_prop xsettings /Net/IconThemeName string "$ICON_THEME"
set_prop xsettings /Gtk/CursorThemeName string "$CURSOR_THEME"

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
set_prop xfce4-panel /panels/panel-1/position string 'p=8;x=0;y=0'
set_prop xfce4-panel /panels/panel-1/length uint 100
set_prop xfce4-panel /panels/panel-1/length-adjust bool true
set_prop xfce4-panel /panels/panel-1/size uint 40
set_prop xfce4-panel /panels/panel-1/nrows uint 1
set_prop xfce4-panel /panels/panel-1/autohide-behavior uint 0
set_prop xfce4-panel /panels/panel-1/position-locked bool true
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n -a \
  -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 -t int -s 5 \
  -t int -s 6 -t int -s 7 -t int -s 8 -t int -s 9

set_prop xfce4-panel /plugins/plugin-1 string whiskermenu
set_prop xfce4-panel /plugins/plugin-2 string docklike
set_prop xfce4-panel /plugins/plugin-3 string separator
set_prop xfce4-panel /plugins/plugin-3/expand bool true
set_prop xfce4-panel /plugins/plugin-3/style uint 0
set_prop xfce4-panel /plugins/plugin-4 string systray
set_prop xfce4-panel /plugins/plugin-5 string pulseaudio
set_prop xfce4-panel /plugins/plugin-6 string power-manager-plugin
set_prop xfce4-panel /plugins/plugin-7 string xfce4-clipman-plugin
set_prop xfce4-panel /plugins/plugin-8 string clock
set_prop xfce4-panel /plugins/plugin-9 string showdesktop

# Ícone da Forja no botão Whisker.
if [[ -s "$ICON_FILE" ]]; then
  set_prop xfce4-panel /plugins/plugin-1/button-icon string forja
  set_prop xfce4-panel /plugins/plugin-1/button-title string Forja
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
    set_prop xfce4-desktop "$prop" string "$WALLPAPER"
  done
fi

xfce4-panel --restart
