#!/usr/bin/env bash
set -Eeuo pipefail

# BuildMaker LXQt Dark: install and apply the complete lightweight desktop profile.
# Safe to run repeatedly. Intended for Manjaro/Arch-based images.
if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo bash $0" >&2
  exit 1
fi

PACKAGES=(
  lxqt lxqt-panel lxqt-runner lxqt-session lxqt-config lxqt-about
  lxqt-powermanagement lxqt-policykit lxqt-notificationd lxqt-sudo
  lxqt-archiver openbox pcmanfm-qt qterminal
  lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
  network-manager-applet pavucontrol-qt blueman pipewire-pulse polkit-gnome
  pamac-gtk firefox calamares fastfetch
  materia-gtk-theme papirus-icon-theme bibata-cursor-theme kvantum qt5ct qt6ct
)

if command -v pacman >/dev/null 2>&1; then
  pacman -Sy --needed --noconfirm "${PACKAGES[@]}"
else
  echo "This profile currently targets Manjaro/Arch (pacman)." >&2
  exit 2
fi

ROOT=/etc/skel
mkdir -p "$ROOT/.config/gtk-3.0" "$ROOT/.config/gtk-4.0" "$ROOT/.config/lxqt" \
  "$ROOT/.config/openbox" "$ROOT/.config/qt5ct" "$ROOT/.config/qt6ct" \
  "$ROOT/.config/Kvantum" "$ROOT/.config/qterminal.org"

cat > "$ROOT/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Materia-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=1
EOF
install -m 0644 "$ROOT/.config/gtk-3.0/settings.ini" "$ROOT/.config/gtk-4.0/settings.ini"

cat > "$ROOT/.config/lxqt/session.conf" <<'EOF'
[Session]
window_manager=openbox
lock_command=loginctl lock-session
quit לח
EOF
# LXQt session environment: force consistent dark Qt and GTK appearance.
cat > /etc/profile.d/buildmaker-dark-theme.sh <<'EOF'
export GTK_THEME=Materia-dark
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=24
EOF
chmod 0644 /etc/profile.d/buildmaker-dark-theme.sh

cat > "$ROOT/.config/qt5ct/qt5ct.conf" <<'EOF'
[Appearance]
style=kvantum
icon_theme=Papirus-Dark
standard_dialogs=default
[Fonts]
fixed=@Variant(\0\0\0\x10\0\0\0\0\0\0\0\0\0\0\0\0)
general=Noto Sans,10,-1,5,50,0,0,0,0,0
EOF
install -m 0644 "$ROOT/.config/qt5ct/qt5ct.conf" "$ROOT/.config/qt6ct/qt6ct.conf"

cat > "$ROOT/.config/Kvantum/kvantum.kvconfig" <<'EOF'
[General]
theme=MateriaDark
EOF

cat > "$ROOT/.config/openbox/rc.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance><strength>10</strength><screen_edge_strength>20</screen_edge_strength></resistance>
  <focus><focusNew>yes</focusNew><followMouse>no</followMouse><raiseOnFocus>no</raiseOnFocus></focus>
  <placement><policy>Smart</policy><center>yes</center></placement>
  <theme><name>Materia-dark</name><titleLayout>NLIMC</titleLayout><keepBorder>yes</keepBorder><animateIconify>no</animateIconify></theme>
  <desktops><number>4</number><firstdesk>1</firstdesk><names><name>Workspace 1</name><name>Workspace 2</name><name>Workspace 3</name><name>Workspace 4</name></names></desktops>
  <keyboard><keybind key="W-space"><action name="Execute"><command>lxqt-runner</command></action></keybind><keybind key="W-e"><action name="Execute"><command>pcmanfm-qt</command></action></keybind><keybind key="W-t"><action name="Execute"><command>qterminal</command></action></keybind></keyboard>
</openbox_config>
EOF

# Set LightDM GTK Greeter as the only display manager; never enable SDDM.
mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm-gtk-greeter.conf <<'EOF'
[ greeter ]
background=#101216
theme-name=Materia-dark
icon-theme-name=Papirus-Dark
cursor-theme-name=Bibata-Modern-Ice
font-name=Noto Sans 10
indicators=~host;~spacer;~clock;~session;~power
EOF
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-buildmaker.conf <<'EOF'
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=lxqt
EOF

# Ensure the graphical login starts LightDM and not SDDM.
systemctl disable sddm.service 2>/dev/null || true
systemctl enable lightdm.service

# Seed current rootless user's defaults too, when run from a live session.
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
  HOME_DIR="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  if [[ -n "$HOME_DIR" && -d "$HOME_DIR" ]]; then
    mkdir -p "$HOME_DIR/.config"
    cp -a "$ROOT/.config/." "$HOME_DIR/.config/"
    chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.config"
  fi
fi

echo "BuildMaker LXQt Dark installed. Log out and select the LXQt session."
