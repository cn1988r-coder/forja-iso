#!/usr/bin/env bash
# VENOM Calypso: XFCE escuro com barra inferior estilo Windows.
set -Eeuo pipefail
ROOT=""
while (($#)); do case "$1" in --root) [[ $# -ge 2 ]] || exit 2; ROOT="$2"; shift 2;; *) exit 2;; esac; done
[[ -n "$ROOT" && -d "$ROOT" ]] || exit 2
S="$ROOT/etc/skel"; X="$S/.config/xfce4/xfconf/xfce-perchannel-xml"
install -d "$X" "$S/.config/gtk-3.0" "$S/.config/gtk-4.0"
cat >"$X/xfce4-panel.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
 <property name="configver" type="int" value="2"/>
 <property name="panels" type="array"><value type="int" value="1"/>
  <property name="dark-mode" type="bool" value="true"/>
  <property name="panel-1" type="empty">
   <property name="position" type="string" value="p=8;x=0;y=0"/>
   <property name="position-locked" type="bool" value="true"/>
   <property name="length" type="uint" value="100"/><property name="length-adjust" type="bool" value="false"/>
   <property name="size" type="uint" value="42"/><property name="mode" type="uint" value="0"/>
   <property name="autohide-behavior" type="uint" value="0"/><property name="background-style" type="uint" value="0"/>
   <property name="plugin-ids" type="array">
    <value type="int" value="1"/><value type="int" value="2"/><value type="int" value="3"/>
    <value type="int" value="6"/><value type="int" value="4"/><value type="int" value="7"/>
    <value type="int" value="8"/><value type="int" value="5"/>
   </property>
  </property>
 </property>
 <property name="plugins" type="empty">
  <property name="plugin-1" type="string" value="whiskermenu"><property name="button-icon" type="string" value="start-here"/><property name="show-button-title" type="bool" value="false"/></property>
  <property name="plugin-2" type="string" value="tasklist"><property name="grouping" type="bool" value="true"/><property name="show-labels" type="bool" value="false"/><property name="flat-buttons" type="bool" value="true"/></property>
  <property name="plugin-3" type="string" value="separator"><property name="expand" type="bool" value="true"/><property name="style" type="uint" value="0"/></property>
  <property name="plugin-4" type="string" value="systray"><property name="icon-size" type="int" value="22"/></property>
  <property name="plugin-5" type="string" value="clock"><property name="mode" type="uint" value="2"/><property name="digital-format" type="string" value="%H:%M  %d/%m/%Y"/><property name="digital-time-font" type="string" value="Noto Sans 9"/></property>
  <property name="plugin-6" type="string" value="pulseaudio"/>
  <property name="plugin-7" type="string" value="power-manager-plugin"/>
  <property name="plugin-8" type="string" value="xfce4-clipman-plugin"/>
 </property>
</channel>
XML
cat >"$X/xsettings.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
 <property name="Net" type="empty"><property name="ThemeName" type="string" value="Adwaita-dark"/><property name="IconThemeName" type="string" value="Papirus-Dark"/></property>
 <property name="Gtk" type="empty"><property name="FontName" type="string" value="Noto Sans 10"/><property name="CursorThemeName" type="string" value="Bibata-Modern-Ice"/><property name="CursorThemeSize" type="int" value="24"/></property>
 <property name="Xfce" type="empty"><property name="SyncThemes" type="bool" value="true"/></property>
</channel>
XML
for gtk in 3.0 4.0; do cat >"$S/.config/gtk-$gtk/settings.ini" <<'GTK'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=true
GTK
done
cat >"$X/xfwm4.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="theme" type="string" value="Default"/><property name="button_layout" type="string" value="|HMC"/><property name="use_compositing" type="bool" value="true"/><property name="snap_to_border" type="bool" value="true"/><property name="snap_to_windows" type="bool" value="true"/><property name="tile_on_move" type="bool" value="true"/></property></channel>
XML
echo "VENOM Calypso aplicado em $ROOT"
