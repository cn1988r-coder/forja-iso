#!/usr/bin/env bash
set -Eeuo pipefail

# BuildMaker XFCE Dark. Idempotent profile setup for Manjaro/Arch.
if [[ $EUID -ne 0 ]]; then
  echo "Execute: sudo bash $0" >&2
  exit 1
fi

PACKAGES=(
  xfce4 xfce4-goodies xfce4-panel xfce4-session xfce4-settings
  xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-clipman-plugin
  xfce4-notifyd xfce4-power-manager xfce4-taskmanager xfce4-panel-profiles
  xfce4-docklike-plugin thunar thunar-archive-plugin thunar-volman
  lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
  network-manager-applet pavucontrol blueman pipewire-pulse polkit-gnome
  pamac-gtk firefox calamares fastfetch
  materia-gtk-theme papirus-icon-theme bibata-cursor-theme noto-fonts htop
)

command -v pacman >/dev/null 2>&1 || {
  echo "Este perfil requer Manjaro/Arch com pacman." >&2
  exit 2
}
pacman -Syu --needed --noconfirm "${PACKAGES[@]}"

SKEL=/etc/skel
mkdir -p "$SKEL/.config/gtk-3.0" "$SKEL/.config/gtk-4.0" "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml" /etc/lightdm/lightdm.conf.d

cat > "$SKEL/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Materia-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=1
EOF
install -m 0644 "$SKEL/.config/gtk-3.0/settings.ini" "$SKEL/.config/gtk-4.0/settings.ini"

# A complete visual restyle for Whisker: dark floating surface, clear spacing,
# blue selection and legible typography. This changes appearance, not the menu engine.
cat > "$SKEL/.config/gtk-3.0/gtk.css" <<'EOF'
/* BuildMaker application menu */
#whiskermenu-window {
  background-color: #11151c;
  color: #e8edf5;
  border: 1px solid #303b4b;
  border-radius: 12px;
}
#whiskermenu-window > box {
  padding: 10px;
  background-color: #11151c;
}
#whiskermenu-window entry {
  color: #f2f5fa;
  background-color: #1b222d;
  border: 1px solid #354255;
  border-radius: 8px;
  min-height: 34px;
  padding: 4px 10px;
}
#whiskermenu-window entry:focus {
  border-color: #2583ff;
  box-shadow: 0 0 0 1px #2583ff;
}
#whiskermenu-window treeview {
  color: #dce5f2;
  background-color: transparent;
  border-radius: 7px;
}
#whiskermenu-window treeview:hover,
#whiskermenu-window treeview:selected {
  color: #ffffff;
  background-color: #1769d2;
}
#whiskermenu-window button {
  color: #dce5f2;
  background-color: transparent;
  border: 0;
  border-radius: 7px;
  padding: 6px;
}
#whiskermenu-window button:hover {
  color: #ffffff;
  background-color: #202c3d;
}
#whiskermenu-window separator {
  background-color: #2a3544;
}
EOF

cat > /etc/profile.d/buildmaker-dark-theme.sh <<'EOF'
export GTK_THEME=Materia-dark
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=24
EOF
chmod 0644 /etc/profile.d/buildmaker-dark-theme.sh

# XFCE panel: one full-width bottom panel, grouped application buttons.
# xfconf settings are seeded for the live user's default profile.
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" <<'EOF'
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
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.063"/>
        <value type="double" value="0.071"/>
        <value type="double" value="0.086"/>
        <value type="double" value="1.0"/>
      </property>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/><value type="int" value="2"/>
        <value type="int" value="3"/><value type="int" value="4"/>
        <value type="int" value="5"/><value type="int" value="6"/>
        <value type="int" value="7"/><value type="int" value="8"/>
        <value type="int" value="9"/><value type="int" value="10"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu"/>
    <property name="plugin-2" type="string" value="separator"/>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-4" type="string" value="separator"/>
    <property name="plugin-5" type="string" value="systray"/>
    <property name="plugin-6" type="string" value="pulseaudio"/>
    <property name="plugin-7" type="string" value="power-manager-plugin"/>
    <property name="plugin-8" type="string" value="notification-plugin"/>
    <property name="plugin-9" type="string" value="clock"/>
    <property name="plugin-10" type="string" value="showdesktop"/>
  </property>
</channel>
EOF

# Configure Whisker as a branded, compact application launcher, not its stock look.
# The GTK stylesheet above supplies the custom visual identity.
cat > /usr/local/bin/buildmaker-xfce-first-login <<'EOF'
#!/usr/bin/env bash
set -eu
command -v xfconf-query >/dev/null 2>&1 || exit 0
set_prop() {
  local channel="$1" property="$2" type="$3" value="$4"
  xfconf-query -c "$channel" -p "$property" --create -t "$type" -s "$value" >/dev/null 2>&1 || true
}
# Whisker button branding and proportions.
set_prop xfce4-panel /plugins/plugin-1/button-title string "Aplicativos"
set_prop xfce4-panel /plugins/plugin-1/button-icon string "view-app-grid-symbolic"
set_prop xfce4-panel /plugins/plugin-1/show-button-title bool false
set_prop xfce4-panel /plugins/plugin-1/menu-width uint 560
set_prop xfce4-panel /plugins/plugin-1/menu-height uint 520
set_prop xfce4-panel /plugins/plugin-1/item-icon-size uint 2
set_prop xfce4-panel /plugins/plugin-1/category-icon-size uint 2
# One grouped task button per application; disable compositor/effects.
set_prop xfce4-panel /plugins/plugin-3/grouping uint 1
set_prop xfce4-panel /plugins/plugin-3/show-labels bool true
set_prop xfwm4 /general/use_compositing bool false
EOF
chmod 0755 /usr/local/bin/buildmaker-xfce-first-login

mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/buildmaker-xfce-first-login.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=BuildMaker XFCE session setup
Comment=Apply BuildMaker panel and menu preferences
Exec=/usr/local/bin/buildmaker-xfce-first-login
OnlyShowIn=XFCE;
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

cat > /etc/lightdm/lightdm-gtk-greeter.conf <<'EOF'
[greeter]
background=#101216
theme-name=Materia-dark
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

systemctl disable sddm.service 2>/dev/null || true
systemctl enable lightdm.service

# Seed GTK/XFCE defaults for the invoking desktop user, if any.
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
  HOME_DIR="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  if [[ -n "$HOME_DIR" && -d "$HOME_DIR" ]]; then
    mkdir -p "$HOME_DIR/.config"
    cp -a "$SKEL/.config/." "$HOME_DIR/.config/"
    chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.config"
  fi
fi

echo "BuildMaker XFCE Dark configurado. A sessão gráfica ainda precisa ser validada."
