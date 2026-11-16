#!/usr/bin/env bash
set -Eeuo pipefail

# Run this script inside the EndeavourOS ISO airootfs chroot, after the upstream
# live-user preparation has completed.
[[ "$EUID" -eq 0 ]] || { echo "Execute como root dentro do chroot." >&2; exit 1; }
ASSETS="/root/forja-desktop-assets"
[[ -d "$ASSETS" ]] || { echo "Assets Forja não encontrados em $ASSETS." >&2; exit 1; }

# Ensure the XFCE session starts through LightDM in the live environment.
systemctl --root=/ enable lightdm.service
ln -sfn /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target

# Install the Forja defaults into the live image and future user skeleton.
DESTDIR="" "$ASSETS/install-branding.sh"

# Keep the XFCE layout hook available for the live account. The upstream
# EndeavourOS live-user is created before this hook is executed.
install -Dm755 "$ASSETS/apply-forja-layout.sh" /usr/local/bin/forja-apply-xfce-layout
install -d /home/liveuser/.config/autostart
cat > /home/liveuser/.config/autostart/forja-xfce-layout.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Forja XFCE layout
Exec=/usr/local/bin/forja-apply-xfce-layout
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
DESKTOP
chown -R liveuser:liveuser /home/liveuser/.config
