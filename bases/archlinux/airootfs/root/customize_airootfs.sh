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
systemctl enable NetworkManager.service bluetooth.service lightdm.service
