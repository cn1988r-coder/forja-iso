#!/usr/bin/env bash
set -Eeuo pipefail

# BuildMaker XFCE Dark: install and seed a modern, lightweight XFCE desktop.
if [[ $EUID -ne 0 ]]; then
  echo "Execute: sudo bash $0" >&2
  exit 1
fi
command -v pacman >/dev/null 2>&1 || {
  echo "Este perfil requer Manjaro/Arch com pacman." >&2
  exit 2
}

PACKAGES=(
  xfce4 xfce4-goodies xfce4-panel xfce4-session xfce4-settings
  xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-clipman-plugin
  xfce4-notifyd xfce4-power-manager xfce4-taskmanager xfce4-genmon-plugin
  xfce4-docklike-plugin thunar thunar-archive-plugin thunar-volman
  lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
  network-manager-applet pavucontrol blueman pipewire-pulse polkit-gnome
  pamac-gtk firefox calamares fastfetch
  papirus-icon-theme bibata-cursor-theme noto-fonts htop
  git gtk-engine-murrine gnome-themes-extra sassc
)
pacman -Syu --needed --noconfirm "${PACKAGES[@]}"

SKEL=/etc/skel
CFG="$SKEL/.config"
mkdir -p "$CFG/gtk-3.0" "$CFG/gtk-4.0" "$CFG/xfce4/xfconf/xfce-perchannel-xml" /etc/lightdm/lightdm.conf.d

cat > "$CFG/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Orchis-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=1
EOF
install -m 0644 "$CFG/gtk-3.0/settings.ini" "$CFG/gtk-4.0/settings.ini"

# Modern, restrained styling for the launcher, panel and task buttons.
cat > "$CFG/gtk-3.0/gtk.css" <<'EOF'
/* BuildMaker XFCE Dark */
#whiskermenu-window {
  background: #111720;
  color: #eaf0f8;
  border: 1px solid #344256;
  border-radius: 12px;
}
#whiskermenu-window > box { padding: 10px; background: #111720; }
#whiskermenu-window entry {
  color: #f4f7fb; background: #1b2634;
  border: 1px solid #34465d; border-radius: 8px;
  min-height: 36px; padding: 4px 10px;
}
#whiskermenu-window entry:focus { border-color: #2583ff; }
#whiskermenu-window treeview {
  color: #dce6f3; background: transparent; border-radius: 7px;
}
#whiskermenu-window treeview:hover,
#whiskermenu-window treeview:selected {
  color: #fff; background: #1769d2;
}
#whiskermenu-window button {
  color: #dce6f3; background: transparent;
  border: 0; border-radius: 7px; padding: 7px;
}
#whiskermenu-window button:hover { color: #fff; background: #202e40; }
#whiskermenu-window separator { background: #2c3a4d; }

/* XFCE panel: dark glass-free surface, clear active-app highlight. */
.xfce4-panel, #XfcePanelWindow {
  background-color: #10151d;
  color: #e7edf6;
}
.xfce4-panel button, #XfcePanelWindow button {
  color: #dce5f1;
  border: 0;
  border-radius: 7px;
  background-image: none;
  box-shadow: none;
}
.xfce4-panel button:hover, #XfcePanelWindow button:hover {
  background-color: #202c3b;
}
.xfce4-panel button:checked, #XfcePanelWindow button:checked {
  color: #fff;
  background-color: #1a3556;
  border-bottom: 2px solid #2583ff;
}
EOF

# XFCE panel configuration: exactly one bottom panel, 46 px high.
# Docklike keeps windows from the same application under one task button.
cat > "$CFG/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panels" type="empty">
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="length-adjust" type="bool" value="false"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="46"/>
      <property name="icon-size" type="uint" value="22"/>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.063"/>
        <value type="double" value="0.082"/>
        <value type="double" value="0.114"/>
        <value type="double" value="1.0"/>
      </property>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/><value type="int" value="3"/>
        <value type="int" value="4"/><value type="int" value="5"/>
        <value type="int" value="6"/><value type="int" value="7"/>
        <value type="int" value="8"/><value type="int" value="9"/>
        <value type="int" value="10"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu"/>
    <property name="plugin-3" type="string" value="docklike"/>
    <property name="plugin-4" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-5" type="string" value="systray"/>
    <property name="plugin-6" type="string" value="pulseaudio"/>
    <property name="plugin-7" type="string" value="power-manager-plugin"/>
    <property name="plugin-8" type="string" value="genmon"/>
    <property name="plugin-9" type="string" value="clock"/>
    <property name="plugin-10" type="string" value="showdesktop"/>
  </property>
</channel>
EOF

# Compact CPU/RAM monitor for the panel, refreshed every 3 seconds.
install -d /usr/local/bin /usr/share/icons/hicolor/scalable/apps /usr/share/themes
cat > /usr/share/icons/hicolor/scalable/apps/buildmaker-v.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="blue" x1="18" y1="12" x2="110" y2="116" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#63b5ff"/>
      <stop offset="0.52" stop-color="#2583ff"/>
      <stop offset="1" stop-color="#0751c8"/>
    </linearGradient>
    <linearGradient id="shine" x1="30" y1="22" x2="98" y2="100" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#ffffff" stop-opacity=".32"/>
      <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <path d="M64 5 122 35v58L64 123 6 93V35Z" fill="#111a27" stroke="#3d526d" stroke-width="3"/>
  <path d="M27 34h19l18 43 18-43h19L71 98H57Z" fill="url(#blue)" stroke="#8bc8ff" stroke-width="2" stroke-linejoin="round"/>
  <path d="M27 34h19l18 43 18-43h19L71 98H57Z" fill="url(#shine)"/>
SVG
# Install the maintained Orchis theme in dark blue, with a compact, solid finish.
if [[ ! -d /tmp/Orchis-theme/.git ]]; then
  rm -rf /tmp/Orchis-theme
  git clone --depth 1 https://github.com/vinceliuice/Orchis-theme.git /tmp/Orchis-theme
fi
/tmp/Orchis-theme/install.sh --dest /usr/share/themes --theme default --color dark --size standard --tweaks black primary submenu --round 8

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
cat > /usr/local/bin/buildmaker-system-monitor <<'EOF'
#!/usr/bin/env bash
set -eu
read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
total1=$((u1+n1+s1+i1+w1+q1+sq1+st1))
idle1=$((i1+w1))
sleep 0.25
read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat
total2=$((u2+n2+s2+i2+w2+q2+sq2+st2))
idle2=$((i2+w2))
dt=$((total2-total1))
di=$((idle2-idle1))
cpu=$(( dt > 0 ? 100-(di*100/dt) : 0 ))
mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
mem=$(( mem_total > 0 ? (mem_total-mem_avail)*100/mem_total : 0 ))
printf 'CPU %s%%  RAM %s%%\n' "$cpu" "$mem"
EOF
chmod 0755 /usr/local/bin/buildmaker-system-monitor

# Apply all first-login settings to the real XFCE session.
cat > /usr/local/bin/buildmaker-xfce-first-login <<'EOF'
#!/usr/bin/env bash
set -eu
command -v xfconf-query >/dev/null 2>&1 || exit 0
set_prop() {
  local channel="$1" property="$2" type="$3" value="$4"
  xfconf-query -c "$channel" -p "$property" --create -t "$type" -s "$value" >/dev/null 2>&1 || true
}
# Branded launcher, comfortable menu size and readable icons.
set_prop xsettings /Net/ThemeName string "Orchis-Dark"
set_prop xfwm4 /general/theme string "Orchis-Dark"
set_prop xfce4-panel /plugins/plugin-1/button-title string "BuildMaker"
set_prop xfce4-panel /plugins/plugin-1/button-icon string "buildmaker-v"
set_prop xfce4-panel /plugins/plugin-1/show-button-title bool false
set_prop xfce4-panel /plugins/plugin-1/menu-width uint 560
set_prop xfce4-panel /plugins/plugin-1/menu-height uint 520
set_prop xfce4-panel /plugins/plugin-1/item-icon-size uint 2
set_prop xfce4-panel /plugins/plugin-1/category-icon-size uint 2
# genmon presents live CPU and RAM figures in the panel.
set_prop xfce4-panel /plugins/plugin-8/command string "/usr/local/bin/buildmaker-system-monitor"
set_prop xfce4-panel /plugins/plugin-8/period uint 3
set_prop xfce4-panel /plugins/plugin-8/use-label bool false
# No compositor, shadows or desktop effects.
set_prop xfwm4 /general/use_compositing bool false
EOF
chmod 0755 /usr/local/bin/buildmaker-xfce-first-login

install -d /etc/xdg/autostart
cat > /etc/xdg/autostart/buildmaker-xfce-first-login.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=BuildMaker XFCE session setup
Comment=Apply BuildMaker desktop preferences
Exec=/usr/local/bin/buildmaker-xfce-first-login
OnlyShowIn=XFCE;
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

cat > /etc/lightdm/lightdm-gtk-greeter.conf <<'EOF'
[greeter]
background=#101216
theme-name=Orchis-Dark
icon-theme-name=Papirus-Dark
cursor-theme-name=Bibata-Modern-Ice
font-name=Noto Sans 10
indicators=~host;~spacer;~clock;~session;~power
EOF
cat > /etc/lightdm/lightdm.conf.d/50-buildmaker.conf <<'EOF'
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=xfce
EOF

cat > /etc/profile.d/buildmaker-dark-theme.sh <<'EOF'
export GTK_THEME=Orchis-Dark
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=24
EOF
chmod 0644 /etc/profile.d/buildmaker-dark-theme.sh

systemctl disable sddm.service 2>/dev/null || true
systemctl enable lightdm.service

# Seed the invoking desktop user's configuration when run through sudo.
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
  HOME_DIR="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  if [[ -n "$HOME_DIR" && -d "$HOME_DIR" ]]; then
    mkdir -p "$HOME_DIR/.config"
    cp -a "$CFG/." "$HOME_DIR/.config/"
    chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.config"
  fi
fi

echo "BuildMaker XFCE Dark instalado. Validar a sessão gráfica e a ISO antes de aprovar o visual."
