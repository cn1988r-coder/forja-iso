#!/usr/bin/env bash
# VENOM OS XFCE visual profile. One approved 40px bottom panel; no second dock.
set -Eeuo pipefail
ROOT=""
while (($#)); do
  case "$1" in
    --root) [[ $# -ge 2 ]] || exit 2; ROOT="$2"; shift 2 ;;
    *) exit 2 ;;
  esac
done
[[ -n "$ROOT" && -d "$ROOT" ]] || exit 2

SKEL="$ROOT/etc/skel"
XFCE="$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml"
GTK3="$SKEL/.config/gtk-3.0"
GTK4="$SKEL/.config/gtk-4.0"
install -d "$XFCE" "$GTK3" "$GTK4" "$SKEL/.config/xfce4-docklike-plugin" "$ROOT/etc/xdg/xfce4/panel" \
  "$ROOT/usr/share/backgrounds/venom" "$ROOT/usr/share/icons/hicolor/scalable/apps"

# Keep one bottom panel. Use a slightly taller panel and preserve the clean icon-only dock.
PANEL="$XFCE/xfce4-panel.xml"
if [[ -f "$PANEL" ]]; then
  sed -i \
    -e 's/value="org.xfce.panel.applicationsmenu"/value="venom-menu"/g' \
    -e 's/value="start-here"/value="venom-menu"/g' \
    -e 's/value="%I:%M %p"/value="%R"/g' \
    -e 's#<property name="size" type="uint" value="40"/>#<property name="size" type="uint" value="46"/>#' \
    "$PANEL"
fi

cat >"$XFCE/xsettings.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Materia-dark"/>
    <property name="IconThemeName" type="string" value="Yaru-blue"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Hinting" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA" type="string" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Noto Sans 10"/>
    <property name="MonospaceFontName" type="string" value="Noto Sans Mono 10"/>
    <property name="CursorThemeName" type="string" value="Bibata-Modern-Ice"/>
    <property name="CursorThemeSize" type="int" value="24"/>
    <property name="DecorationLayout" type="string" value=":minimize,maximize,close"/>
    <property name="DialogsUseHeader" type="bool" value="true"/>
    <property name="MenuImages" type="bool" value="true"/>
    <property name="ButtonImages" type="bool" value="true"/>
  </property>
  <property name="Xfce" type="empty">
    <property name="SyncThemes" type="bool" value="true"/>
  </property>
</channel>
XML

for gtk in "$GTK3" "$GTK4"; do
  cat >"$gtk/settings.ini" <<'GTK'
[Settings]
gtk-theme-name=Materia-dark
gtk-icon-theme-name=Yaru-blue
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=true
gtk-decoration-layout=:minimize,maximize,close
GTK
  cat >"$gtk/gtk.css" <<'CSS'
/* Keep Materia Dark in control of GTK widget styling. */
CSS
done

# Docklike is the single app dock/taskbar: each app keeps one pinned icon and all its windows
# are grouped under that same icon (no separate window buttons).
cat >"$ROOT/etc/xdg/xfce4/panel/docklike.rc" <<'RC'
[user]
pinned=firefox.desktop;thunar.desktop;xfce4-terminal.desktop;
forceIconSize=true
iconSize=30
showPreviews=true
showWindowCount=false
indicatorStyle=1
inactiveIndicatorStyle=5
indicatorOrientation=1
indicatorColorFromTheme=false
indicatorColor=rgb(22,143,255)
inactiveColor=rgb(6,65,143)
RC

# Docklike spacing and button treatment: no tile, square, border or hover frame.
cat >"$SKEL/.config/xfce4-docklike-plugin/gtk.css" <<'CSS'
#docklike-plugin .group,
#docklike-plugin .open_group,
#docklike-plugin .active_group,
#docklike-plugin .hover_group {
  background: transparent;
  background-image: none;
  border: none;
  border-radius: 0;
  box-shadow: none;
}
#docklike-plugin .group {
  padding: 3px 7px;
  margin: 0 4px;
}
CSS

# Preserve the existing XFWM behavior and only select the matching window theme.
if [[ -f "$XFCE/xfwm4.xml" ]]; then
  if grep -q 'property name="theme"' "$XFCE/xfwm4.xml"; then
    sed -i 's#<property name="theme" type="string" value="[^"]*"/>#<property name="theme" type="string" value="Materia-dark"/>#' "$XFCE/xfwm4.xml"
  else
    sed -i 's#<property name="general" type="empty">#<property name="general" type="empty"><property name="theme" type="string" value="Materia-dark"/>#' "$XFCE/xfwm4.xml"
  fi
else
  cat >"$XFCE/xfwm4.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Materia-dark"/>
    <property name="button_layout" type="string" value="|HMC"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="tile_on_move" type="bool" value="true"/>
  </property>
</channel>
XML
fi

# Disable XFCE compositing in the Live and installed profiles. This avoids
# black-screen/session instability with virtual graphics adapters such as
# VirtualBox VMSVGA; window management and the desktop theme remain enabled.
if [[ -f "$XFCE/xfwm4.xml" ]]; then
  if grep -q 'property name="use_compositing"' "$XFCE/xfwm4.xml"; then
    sed -i 's#<property name="use_compositing" type="bool" value="[^"]*"/>#<property name="use_compositing" type="bool" value="false"/>#' "$XFCE/xfwm4.xml"
  else
    sed -i 's#<property name="general" type="empty">#<property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/>#' "$XFCE/xfwm4.xml"
  fi
fi

cat >"$ROOT/usr/share/icons/hicolor/scalable/apps/venom-menu.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
 <defs><linearGradient id="v" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#b7efff"/><stop offset=".5" stop-color="#168bff"/><stop offset="1" stop-color="#0649ad"/></linearGradient><filter id="g"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
 <circle cx="64" cy="64" r="59" fill="#10151d" stroke="#26394e" stroke-width="3"/>
 <path d="M24 32h23l17 51 17-51h23L75 101q-11 17-22 0z" fill="url(#v)" filter="url(#g)"/>
 <path d="M39 42h13l12 36 12-36h13" fill="none" stroke="#e2f8ff" stroke-width="3" stroke-linecap="round"/>
</svg>
SVG

cat >"$ROOT/usr/share/backgrounds/venom/venom-serpent.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="2560" height="1440" viewBox="0 0 2560 1440">
 <defs>
  <radialGradient id="bg"><stop stop-color="#101a27"/><stop offset=".55" stop-color="#070b11"/><stop offset="1" stop-color="#020305"/></radialGradient>
  <linearGradient id="metal" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#f1f6fb"/><stop offset=".22" stop-color="#63778c"/><stop offset=".42" stop-color="#dce7f0"/><stop offset=".67" stop-color="#354b61"/><stop offset="1" stop-color="#b5c5d4"/></linearGradient>
  <linearGradient id="blue"><stop stop-color="#b7efff"/><stop offset=".5" stop-color="#168fff"/><stop offset="1" stop-color="#06418f"/></linearGradient>
  <filter id="glow"><feGaussianBlur stdDeviation="26"/></filter>
 </defs>
 <rect width="2560" height="1440" fill="url(#bg)"/>
 <g fill="none" stroke="#087de0" stroke-width="3" opacity=".17"><path d="M-80 1120C420 850 460 1460 1000 1180S1700 780 2640 1120"/><path d="M-80 1200C400 940 520 1510 1060 1240S1840 860 2640 1200"/><path d="M-80 260C430 540 700-20 1260 230S2020 530 2640 260"/></g>
 <ellipse cx="1280" cy="690" rx="540" ry="430" fill="#087de0" opacity=".17" filter="url(#glow)"/>
 <g transform="translate(1280 680)">
  <path d="M45-350C-220-470-490-300-515-55-545 220-320 400-60 385 190 370 355 190 350-40 345-205 225-330 100-355" fill="none" stroke="#03070c" stroke-width="154" stroke-linecap="round" transform="translate(12 24)"/>
  <path d="M45-350C-220-470-490-300-515-55-545 220-320 400-60 385 190 370 355 190 350-40 345-205 225-330 100-355" fill="none" stroke="url(#metal)" stroke-width="126" stroke-linecap="round"/>
  <path d="M45-350C-220-470-490-300-515-55-545 220-320 400-60 385 190 370 355 190 350-40 345-205 225-330 100-355" fill="none" stroke="#eff8ff" stroke-opacity=".55" stroke-width="7" transform="translate(-8 -10)"/>
  <path d="M100-355C190-430 280-405 330-340 370-290 355-220 305-190 260-165 215-185 180-220l-35-35 45-22 42 26c28-17 30-48 9-70-24-25-60-23-100-5" fill="url(#metal)" stroke="#d9e9f6" stroke-width="8" stroke-linejoin="round"/>
  <path d="M318-245l55 13-30 35-49-18z" fill="#08111c" stroke="url(#blue)" stroke-width="7"/>
  <path d="M326-233l37 8" stroke="#d7f7ff" stroke-width="5" stroke-linecap="round"/>
  <path d="M350-205q34 34 72 48" fill="none" stroke="url(#blue)" stroke-width="8" stroke-linecap="round"/>
  <circle cx="292" cy="-292" r="10" fill="#078cff"/><circle cx="292" cy="-292" r="4" fill="#e8fbff"/>
  <path d="M45-350q-65 20-115 78" fill="none" stroke="#168fff" stroke-width="12" stroke-linecap="round"/>
 </g>
 <text x="1280" y="1245" text-anchor="middle" fill="#dce7f1" font-family="DejaVu Sans,sans-serif" font-size="112" font-weight="700" letter-spacing="22">VENOM</text>
 <text x="1280" y="1310" text-anchor="middle" fill="#168fff" font-family="DejaVu Sans,sans-serif" font-size="26" letter-spacing="12">OPERATING SYSTEM</text>
</svg>
SVG

cat >"$XFCE/xfce4-desktop.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/venom/venom-serpent.svg"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XML

echo "VENOM OS XFCE visual profile staged in $ROOT"
