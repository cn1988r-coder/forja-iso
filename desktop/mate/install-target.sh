#!/usr/bin/env bash
set -Eeuo pipefail

# Runs inside the installed target by Archinstall custom_commands.
SOURCE_ROOT="${1:-}"
if [[ "$EUID" -ne 0 || -z "$SOURCE_ROOT" || ! -d "$SOURCE_ROOT/desktop/mate" ]]; then
  echo "Uso interno: install-target.sh /caminho/para/checkout/forja-iso (como root no sistema alvo)" >&2
  exit 2
fi

MATE="$SOURCE_ROOT/desktop/mate"
install -d /etc/skel/.config /usr/local/lib/forja
cp -an "$MATE/skel/.config/." /etc/skel/.config/
install -m 0755 "$MATE/apply-defaults.sh" /usr/local/lib/forja/apply-defaults.sh
install -Dm0755 /dev/stdin /usr/local/bin/forja-apply-defaults <<'LAUNCHER'
#!/usr/bin/env sh
exec /usr/local/lib/forja/apply-defaults.sh
LAUNCHER
install -Dm0644 /dev/stdin /etc/xdg/autostart/forja-apply-defaults.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Forja OS desktop defaults
Exec=/usr/local/bin/forja-apply-defaults
OnlyShowIn=MATE;
NoDisplay=true
DESKTOP

bash "$MATE/install-forja-store.sh" /
bash "$MATE/install-forja-monitor.sh" /
bash "$MATE/install-forja-update-indicator.sh" /
for home in /home/*; do
  [[ -d "$home" ]] || continue
  install -d "$home/.config"
  cp -an /etc/skel/.config/. "$home/.config/"
  chown -R "$(stat -c %U:%G "$home")" "$home/.config"
done
install -Dm0755 "$MATE/forja-luz-noturna/forja-luz-noturna.py" /usr/bin/forja-luz-noturna
install -Dm0644 "$MATE/skel/.config/autostart/forja-luz-noturna.desktop" /etc/xdg/autostart/forja-luz-noturna.desktop
install -Dm0644 "$MATE/wallpapers/forja-mate-wallpaper.svg" /usr/share/backgrounds/forja/forja-mate-wallpaper.svg

install -d /etc/dconf/profile /etc/dconf/db/local.d /etc/X11/xorg.conf.d
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF
cat > /etc/dconf/db/local.d/00-forja-mate <<'EOF'
[org/mate/interface]
gtk-theme='Materia-dark'
icon-theme='Papirus-Dark'
font-name='DejaVu Sans 10'

[org/mate/Marco/general]
compositing-manager=false

[org/mate/desktop/background]
picture-filename='/usr/share/backgrounds/forja/forja-mate-wallpaper.svg'
picture-options='zoom'
color-shading-type='solid'
primary-color='#858585'
secondary-color='#858585'
EOF
dconf update

printf '%s\n' 'pt_BR.UTF-8 UTF-8' 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
printf '%s\n' 'LANG=pt_BR.UTF-8' > /etc/locale.conf
ln -snf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<'EOF'
Section "InputClass"
    Identifier "Forja Brazilian keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "br"
    Option "XkbVariant" "abnt2"
EndSection
EOF

systemctl enable NetworkManager.service bluetooth.service lightdm.service
echo "Personalizações e aplicativos MATE da Forja instalados no sistema de destino."
