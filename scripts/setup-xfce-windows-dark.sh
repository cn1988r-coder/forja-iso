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
install -d "$XFCE" "$GTK3" "$GTK4" "$ROOT/etc/xdg/xfce4/panel" \
  "$ROOT/usr/share/backgrounds/venom" "$ROOT/usr/share/icons/hicolor/scalable/apps"

# Keep the existing single-panel geometry and plugin order. Only correct the
# approved Venom menu icon and 24-hour clock presentation.
PANEL="$XFCE/xfce4-panel.xml"
if [[ -f "$PANEL" ]]; then
  sed -i \
    -e 's/value="org.xfce.panel.applicationsmenu"/value="venom-menu"/g' \
    -e 's/value="start-here"/value="venom-menu"/g' \
    -e 's/value="%I:%M %p"/value="%R"/g' \
    "$PANEL"
fi

cat >"$XFCE/xsettings.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="adw-gtk3-dark"/>
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
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Yaru-blue
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=true
gtk-decoration-layout=:minimize,maximize,close
GTK
  cat >"$gtk/gtk.css" <<'CSS'
/* VENOM: graphite, metallic silver and restrained electric blue. */
@define-color venom_bg #090e15;
@define-color venom_surface #111a25;
@define-color venom_surface_hi #192635;
@define-color venom_border #30465d;
@define-color venom_blue #168fff;
@define-color venom_text #dce7f1;
@define-color venom_muted #91a4b8;

window, .background {
  background-color: @venom_bg;
  color: @venom_text;
}
headerbar, .titlebar {
  background: linear-gradient(to bottom, #1a2736, #101720);
  color: #f0f6fc;
  border-bottom: 1px solid alpha(@venom_blue, 0.58);
  box-shadow: none;
  min-height: 34px;
}
headerbar button, .titlebar button {
  border-radius: 6px;
}
button {
  color: @venom_text;
  background: linear-gradient(to bottom, #202d3c, #151e29);
  border: 1px solid @venom_border;
  border-radius: 7px;
  box-shadow: none;
  padding: 5px 10px;
}
button:hover {
  background: #1b3a58;
  border-color: @venom_blue;
  color: #fff;
}
button:checked, button:active {
  background: #12385d;
  border-color: @venom_blue;
}
entry, spinbutton, combobox, .view, textview text {
  background-color: #080d13;
  color: @venom_text;
  border: 1px solid @venom_border;
  border-radius: 6px;
  caret-color: #56c2ff;
}
entry:focus, spinbutton:focus, combobox:focus {
  border-color: @venom_blue;
  box-shadow: 0 0 0 1px alpha(@venom_blue, 0.30);
}
menu, popover, .context-menu, .csd.popup {
  background-color: @venom_surface;
  color: @venom_text;
  border: 1px solid #38536e;
  border-radius: 8px;
}
menuitem:hover, modelbutton:hover {
  background-color: alpha(@venom_blue, 0.22);
  color: #fff;
}
*:selected, selection {
  background-color: #14518a;
  color: #fff;
}
tooltip {
  background-color: #101a26;
  color: #eaf5ff;
  border: 1px solid @venom_blue;
  border-radius: 5px;
}
.sidebar, placessidebar, .navigation-sidebar {
  background-color: #0d141e;
  color: @venom_text;
}
.sidebar row:selected, placessidebar row:selected {
  background-color: alpha(@venom_blue, 0.24);
  border-left: 2px solid @venom_blue;
}
toolbar, .toolbar {
  background: #101823;
  border-bottom: 1px solid alpha(@venom_border, 0.8);
}
scrollbar slider {
  background-color: #40566d;
  border-radius: 8px;
}
scrollbar slider:hover {
  background-color: @venom_blue;
}

/* Whisker menu: dark inner surface, clean search field and blue selection. */
#whiskermenu-window, .whiskermenu,
#whiskermenu-window border, #whiskermenu-window grid {
  background-color: #0c131d;
  color: @venom_text;
}
#whiskermenu-window button {
  background: transparent;
  border: 0;
  border-radius: 7px;
  color: @venom_text;
  padding: 6px;
}
#whiskermenu-window button:hover,
#whiskermenu-window row:hover {
  background-color: alpha(@venom_blue, 0.20);
  color: #fff;
}
#whiskermenu-window entry {
  background-color: #070c12;
  border: 1px solid #38536e;
  border-radius: 7px;
  color: #f2f7fc;
  padding: 8px 10px;
}
#whiskermenu-window entry:focus {
  border-color: @venom_blue;
}
#whiskermenu-window .category-button {
  border-radius: 7px;
}
#whiskermenu-window .category-button:checked {
  background-color: alpha(@venom_blue, 0.24);
  border-left: 2px solid @venom_blue;
}
#whiskermenu-window label {
  color: @venom_text;
}

/* Keep the single bottom panel visually close to the supplied reference. */
#XfcePanelWindow {
  background-color: rgba(5, 9, 15, 0.94);
  border-top: 1px solid rgba(22, 143, 255, 0.62);
}
#XfcePanelWindow button {
  background: transparent;
  border: 0;
  border-radius: 7px;
  box-shadow: none;
  padding: 2px;
}
#XfcePanelWindow button:hover {
  background-color: rgba(22, 143, 255, 0.19);
}
CSS
done

# Docklike is integrated into the existing panel, not a separate floating dock.
cat >"$ROOT/etc/xdg/xfce4/panel/docklike.rc" <<'RC'
[user]
pinned=firefox.desktop;thunar.desktop;
forceIconSize=true
iconSize=32
showPreviews=true
showWindowCount=false
indicatorColorFromTheme=false
indicatorColor=rgb(22,143,255)
inactiveColor=rgb(6,65,143)
RC

# Preserve the existing XFWM behavior and only select the matching window theme.
if [[ -f "$XFCE/xfwm4.xml" ]]; then
  if grep -q 'property name="theme"' "$XFCE/xfwm4.xml"; then
    sed -i 's#<property name="theme" type="string" value="[^"]*"/>#<property name="theme" type="string" value="adw-gtk3-dark"/>#' "$XFCE/xfwm4.xml"
  else
    sed -i 's#<property name="general" type="empty">#<property name="general" type="empty"><property name="theme" type="string" value="adw-gtk3-dark"/>#' "$XFCE/xfwm4.xml"
  fi
else
  cat >"$XFCE/xfwm4.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="adw-gtk3-dark"/>
    <property name="button_layout" type="string" value="|HMC"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="tile_on_move" type="bool" value="true"/>
  </property>
</channel>
XML
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
