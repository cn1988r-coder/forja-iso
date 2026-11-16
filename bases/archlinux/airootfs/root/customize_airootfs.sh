#!/usr/bin/env bash
set -Eeuo pipefail

# Executed by mkarchiso inside the new live root filesystem after packages install.
install -d /etc/lightdm/lightdm.conf.d /etc/sudoers.d /etc/xdg/autostart /usr/local/bin
cat > /etc/lightdm/lightdm.conf.d/50-forja-autologin.conf <<'EOF'
[Seat:*]
autologin-user=forja
autologin-user-timeout=0
user-session=mate
EOF

for group in wheel audio video storage power; do
  getent group "$group" >/dev/null 2>&1 || groupadd --system "$group"
done

if ! id forja >/dev/null 2>&1; then
  useradd --create-home --groups wheel,audio,video,storage,power --shell /bin/bash forja
  passwd --delete forja
fi
printf '%s\n' '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-forja-live
chmod 0440 /etc/sudoers.d/10-forja-live
install -d -o forja -g forja /home/forja
if [[ -d /etc/skel/.config ]]; then
  cp -a /etc/skel/.config /home/forja/
  chown -R forja:forja /home/forja/.config
fi
cat > /etc/locale.gen <<'EOF'
pt_BR.UTF-8 UTF-8
en_US.UTF-8 UTF-8
EOF
locale-gen
printf '%s\n' 'LANG=pt_BR.UTF-8' > /etc/locale.conf
ln -snf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
install -d /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<'EOF'
Section "InputClass"
    Identifier "Forja Brazilian keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "br"
    Option "XkbVariant" "abnt2"
EndSection
EOF
systemctl enable NetworkManager.service bluetooth.service lightdm.service

# Install the Forja splash after Plymouth and librsvg have been installed.
bash /usr/local/lib/forja/plymouth/install-theme.sh / /usr/share/forja/branding/forja-flame.svg
mkinitcpio -P
