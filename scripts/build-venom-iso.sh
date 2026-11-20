#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${ROOT}/work"
EOS_DIR="${WORK}/EndeavourOS-ISO"
PKG_DIR="${WORK}/packages"
EOS_COMMIT="90376d8f52ab19e19073eed33d6f36c46ec7c409"
PKGBUILDS_COMMIT="474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd"
SHELLY_COMMIT="6840658b19d72205c38bd320c1cef6ff3076bc7c"

log() { printf '\n[VENOM] %s\n' "$*"; }
die() { printf '\n[ERRO] %s\n' "$*" >&2; exit 1; }
trap 'die "Falha na linha $LINENO. Consulte a mensagem acima."' ERR

[[ "$(uname -m)" == x86_64 ]] || die "A compilação atual exige x86_64."
[[ -f /etc/arch-release ]] || die "Use EndeavourOS ou Arch Linux com os repositórios EndeavourOS habilitados."
[[ $EUID -ne 0 ]] || die "Execute como usuário normal. O script usa sudo apenas nas etapas necessárias."
command -v git >/dev/null || die "Instale git."
command -v curl >/dev/null || die "Instale curl."
command -v makepkg >/dev/null || die "makepkg não encontrado. Use um host Arch/EndeavourOS."
command -v sudo >/dev/null || die "sudo não encontrado."

mkdir -p "$WORK" "$PKG_DIR"

log "Instalando dependências de compilação"
sudo pacman -S --needed --noconfirm archiso git curl squashfs-tools imagemagick base-devel python
export MAKEFLAGS="-j$(nproc)"

clone_at_commit() {
  local url="$1" dir="$2" commit="$3"
  if [[ ! -d "$dir/.git" ]]; then
    git clone "$url" "$dir"
  fi
  git -C "$dir" fetch --all --tags
  git -C "$dir" checkout --detach "$commit"
  git -C "$dir" reset --hard "$commit"
  git -C "$dir" clean -fdx
}

log "Obtendo framework EndeavourOS fixado em $EOS_COMMIT"
clone_at_commit https://github.com/endeavouros-team/EndeavourOS-ISO.git "$EOS_DIR" "$EOS_COMMIT"

log "Preparando lista fixa de pacotes VENOM OS com MATE, Firefox e aplicativos próprios"
python - "$EOS_DIR/packages.x86_64" "$ROOT/build/packages.mate" <<'PY'
import pathlib, re, sys
target = pathlib.Path(sys.argv[1])
mate = pathlib.Path(sys.argv[2]).read_text()
# Keep MATE and both kernels; remove heavyweight extras not required for the default Live profile.
# Mesa/Nouveau and generic firmware remain. Proprietary NVIDIA drivers can be installed later with Pacman.
remove = re.compile(r'^(endeavouros-(mirrorlist|keyring|branding)|eos-[a-z0-9-]+|ark|bluedevil|breeze.*|dolphin.*|endeavouros-konsole-colors|eos-apps-info|eos-log-tool|eos-packagelist|eos-quickstart|firewall-applet|ffmpegthumbs|gwenview|haruna|kate|kcalc|kde.*|kimageformats|kinfocenter|kio.*|konsole|kscreen|kwallet.*|kwayland.*|okular|partitionmanager|plasma.*|powerdevil|print-manager|reflector-simple|spectacle|sddm|welcome|xdg-desktop-portal-kde|base-devel|nvidia-open|nvidia-utils|nvidia-inst|nvidia-hook|noto-fonts-cjk|noto-fonts-extra|tesseract-data-eng|clonezilla|fsarchiver|gpart|gparted|grsync|hardinfo2|meld|fwupd|b43-fwcutter)$')
lines = []
for line in target.read_text().splitlines():
    item = line.strip()
    if item and not item.startswith('#') and remove.match(item):
        continue
    lines.append(line)
existing = {x.strip() for x in lines}
for line in mate.splitlines():
    item = line.strip()
    if item and not item.startswith('#') and item not in existing:
        lines.append(item)
        existing.add(item)
target.write_text('\n'.join(lines).rstrip() + '\n')
PY

log "Aplicando identidade visual e configurações MATE"
cp -a "$ROOT/build/airootfs/." "$EOS_DIR/airootfs/"
# Install the two manual VENON entry points. Their backend remains disabled until
# the independent VENON repository and package installer are implemented.
chmod 0755 "$EOS_DIR/airootfs/usr/bin/venon-update" "$EOS_DIR/airootfs/usr/bin/venon-upgrade"
chmod 0755 "$EOS_DIR/airootfs/usr/bin/venom-calamares"
# The VENOM live and installed system must use Arch repositories only.
mkdir -p "$EOS_DIR/airootfs/etc"
cat > "$EOS_DIR/airootfs/etc/pacman.conf" <<'PACMANCONF'
[options]
Architecture = auto
Color
VerbosePkgLists
ParallelDownloads = 5
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
PACMANCONF
# Ship the build host's Arch Linux mirrorlist into the live and installed image.
# The final system must never inherit EndeavourOS mirrors.
[[ -s /etc/pacman.d/mirrorlist ]] || die "Mirrorlist oficial do Arch Linux não encontrada no ambiente de compilação."
if grep -Eiq 'endeavouros' /etc/pacman.d/mirrorlist; then
  die "A mirrorlist do ambiente contém servidores EndeavourOS; use uma mirrorlist Arch Linux."
fi
grep -Eq '^Server[[:space:]]*=' /etc/pacman.d/mirrorlist || die "A mirrorlist do Arch Linux não contém servidores ativos."
install -Dm644 /etc/pacman.d/mirrorlist "$EOS_DIR/airootfs/etc/pacman.d/mirrorlist"
# GTK settings belong to the EndeavourOS liveuser skeleton package, not the base airootfs /etc/skel.
# Keeping a second copy here makes pacman reject endeavouros-skel-liveuser with file conflicts.
rm -f "$EOS_DIR/airootfs/etc/skel/.config/gtk-3.0/settings.ini"
rm -f "$EOS_DIR/airootfs/etc/skel/.config/gtk-4.0/settings.ini"
rm -f "$EOS_DIR/airootfs/etc/skel/.icons/default/index.theme"
SKEL="$EOS_DIR/airootfs/root/endeavouros-skel-liveuser/src/etc/skel"
mkdir -p "$SKEL/.config/gtk-3.0" "$SKEL/.config/gtk-4.0" "$SKEL/.icons/default"
cp "$ROOT/build/airootfs/etc/skel/.config/gtk-3.0/settings.ini" "$SKEL/.config/gtk-3.0/settings.ini"
cp "$ROOT/build/airootfs/etc/skel/.config/gtk-4.0/settings.ini" "$SKEL/.config/gtk-4.0/settings.ini"
cp "$ROOT/build/airootfs/etc/skel/.icons/default/index.theme" "$SKEL/.icons/default/index.theme"
rm -rf "$SKEL/.config/kdedefaults" "$SKEL/.config/plasma"* "$SKEL/.local/share/plasma" "$SKEL/.local/share/konsole" "$SKEL/.local/etc/xdg/kdeglobals"
find "$SKEL/.config" -maxdepth 1 -type f \( -name 'balo*' -o -name 'kcm*' -o -name 'kde*' -o -name 'kscreen*' -o -name 'ksmserverrc' -o -name 'ksplashrc' -o -name 'kwalletrc' -o -name 'kxkbrc' -o -name 'plasma*' -o -name 'powerdevilrc' -o -name 'powermanagementprofilesrc' -o -name 'systemsettingsrc' \) -delete
mkdir -p "$EOS_DIR/airootfs/root/packages"

log "Gerando wallpaper gráfico monocromático da VENOM OS"
VENOM_WALLPAPER_SVG="$ROOT/build/airootfs/usr/share/backgrounds/venom/venom-wallpaper.svg"
VENOM_WALLPAPER="$ROOT/build/airootfs/usr/share/backgrounds/venom/venom-wallpaper.png"
mkdir -p "$(dirname "$VENOM_WALLPAPER")" "$EOS_DIR/airootfs/root"
[[ -s "$VENOM_WALLPAPER_SVG" ]] || die "Arte vetorial do wallpaper VENOM não encontrada."
magick -background none "$VENOM_WALLPAPER_SVG" "$VENOM_WALLPAPER"
[[ -s "$VENOM_WALLPAPER" ]] || die "Não foi possível rasterizar o wallpaper gráfico da VENOM OS."
identify -format '%wx%h' "$VENOM_WALLPAPER" | grep -Fxq '1920x1080' || die "Wallpaper VENOM gerado com resolução incorreta."
cp "$VENOM_WALLPAPER" "$EOS_DIR/airootfs/root/livewall.png"
cp "$VENOM_WALLPAPER" "$EOS_DIR/airootfs/root/endeavouros-wallpaper.png"

log "Removendo etapa específica de configuração KDE do prepare.sh"
python - "$EOS_DIR/prepare.sh" <<'PY'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
s = re.sub(r'(?s)# add date to wallpaper.*?a[i]rootfs/root/livewall\.png\n', '# VENOM OS: fundo preto puro, sem data sobreposta.\n', s, count=1)
s = re.sub(r'(?m)^wget -qN .*endeavouros-wallpaper\.png.*\n', '', s)
s = re.sub(r'(?m)^get_pkg "eos-settings-plasma"\s*$', '# KDE settings package intentionally omitted for VENOM OS.', s)
p.write_text(s)
PY

log "Configurando LightDM, removendo sobras KDE e alvo gráfico"
python - "$EOS_DIR/run_before_squashfs.sh" <<'PY'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
old = 'systemctl set-default multi-user.target'
new = 'systemctl enable NetworkManager.service\nsystemctl unmask bluetooth.service\nsystemctl enable bluetooth.service\ntest -x /usr/lib/bluetooth/bluetoothd\ntest -s /usr/lib/systemd/system/bluetooth.service\nsystemctl is-enabled --quiet bluetooth.service\nsystemctl enable lightdm.service\nsystemctl set-default graphical.target\ndconf update'
if old not in s:
    raise SystemExit('Não foi possível localizar o ponto de ativação do alvo multi-user no script upstream.')
s = s.replace(old, new, 1)
kde_root_theme = 'echo "---> setup theming for root user --->"\ncp -a "/root/root-theme" "/root/.config"\nrm -R "/root/root-theme"\n'
if kde_root_theme not in s:
    raise SystemExit('Não foi possível localizar o bloco de tema KDE do usuário root.')
s = s.replace(kde_root_theme, '')
motd_marker = 'echo "---> Add builddate to motd --->"'
if motd_marker not in s:
    raise SystemExit('Não foi possível localizar a etapa do motd.')
s = s.replace(motd_marker, 'printf "VENOM OS\\nBase Arch Linux\\n" > "/usr/lib/venom-release"\n' + motd_marker, 1)
calamares_install_pattern = re.compile(
    r'(?m)^(?P<indent>[ \t]*)pacman[ \t]+-U[ \t]+--noconfirm(?:[ \t]+--needed)?[ \t]+--[ \t]+"/root/packages/"\*"\.pkg\.tar\.zst"[ \t]*\n'
)
calamares_patch = """if [[ ! -r /etc/calamares/settings_offline.conf || ! -r /etc/calamares/settings_online.conf ]]; then
  echo "Calamares VENOM online/offline settings are missing." >&2
  exit 1
fi
if ! pacman -Qql calamares 2>/dev/null | grep -Fxq '/usr/bin/calamares'; then
  echo "O pacote Calamares instalado não registra /usr/bin/calamares." >&2
  pacman -Q calamares >&2 || true
  exit 1
fi
if [[ ! -x /usr/bin/calamares || ! -x /usr/bin/venom-calamares ]]; then
  echo "Calamares executable is missing or not executable: /usr/bin/calamares" >&2
  ls -l /usr/bin/calamares /usr/bin/venom-calamares >&2 || true
  exit 1
fi
if ! command -v pacstrap >/dev/null 2>&1; then
  echo "Arch pacstrap is missing from the Live environment." >&2
  exit 1
fi
if [[ ! -s /etc/pacman.conf || ! -s /etc/pacman.d/mirrorlist ]] || ! grep -Eq '^Server[[:space:]]*=' /etc/pacman.d/mirrorlist; then
  echo "The Live environment does not have an active official Arch mirrorlist." >&2
  exit 1
fi
# Verify the actual installed session integration, not merely package names.
check_session_applet() {
  local desktop_file="$1" executable="$2"
  [[ -s "$desktop_file" ]] || {
    echo "MATE session autostart file is missing: $desktop_file" >&2
    exit 1
  }
  command -v "$executable" >/dev/null 2>&1 || {
    echo "MATE session applet executable is missing: $executable" >&2
    exit 1
  }
  grep -Eq "^Exec=([^[:space:]]*/)?${executable}([[:space:]]|$)" "$desktop_file" || {
    echo "MATE session autostart does not launch $executable: $desktop_file" >&2
    exit 1
  }
}
# Replace upstream autostart entries with explicit MATE-only launchers.
# This avoids relying on desktop-environment filters shipped by package defaults.
install -d -m 0755 /etc/xdg/autostart
cat > /etc/xdg/autostart/nm-applet.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Network Manager Applet
Exec=/usr/bin/nm-applet
OnlyShowIn=MATE;
X-MATE-Autostart-enabled=true
NoDisplay=true
DESKTOP
cat > /etc/xdg/autostart/blueman.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Blueman Applet
Exec=/usr/bin/blueman-applet
OnlyShowIn=MATE;
X-MATE-Autostart-enabled=true
NoDisplay=true
DESKTOP

# Install a deterministic MATE panel layout after the desktop packages are installed.
# The top panel contains a real separator, the notification area (network/Bluetooth
# tray icons), the native MATE volume applet, and the clock.
install -d -m 0755 /usr/share/mate-panel/layouts
cat > /usr/share/mate-panel/layouts/default.layout <<'LAYOUT'
[Toplevel top]
expand=true
orientation=top
size=28

[Toplevel bottom]
expand=true
orientation=bottom
size=28

[Object menu-bar]
object-type=menu-bar
toplevel-id=top
pack-index=0
locked=true

[Object separator]
object-type=separator
toplevel-id=top
pack-index=1
locked=true

[Object notification-area]
object-type=applet
applet-iid=NotificationAreaAppletFactory::NotificationArea
toplevel-id=top
pack-type=end
pack-index=2
locked=true

[Object volume-control]
object-type=applet
applet-iid=GvcAppletFactory::GvcApplet
toplevel-id=top
pack-type=end
pack-index=1
locked=true

[Object clock]
object-type=applet
applet-iid=ClockAppletFactory::ClockApplet
toplevel-id=top
pack-type=end
pack-index=0
locked=true

[Object show-desktop]
object-type=applet
applet-iid=WnckletFactory::ShowDesktopApplet
toplevel-id=bottom
pack-index=0
locked=true

[Object window-list]
object-type=applet
applet-iid=WnckletFactory::WindowListApplet
toplevel-id=bottom
pack-index=1
locked=true

[Object workspace-switcher]
object-type=applet
applet-iid=WnckletFactory::WorkspaceSwitcherApplet
toplevel-id=bottom
pack-type=end
pack-index=0
locked=true
LAYOUT

chmod 0644 /etc/xdg/autostart/nm-applet.desktop /etc/xdg/autostart/blueman.desktop
# Validate the launchers after writing them, not the upstream files they replace.
check_session_applet /etc/xdg/autostart/nm-applet.desktop nm-applet
check_session_applet /etc/xdg/autostart/blueman.desktop blueman-applet
# Do not let an inherited liveuser dconf database override the system MATE panel layout.
rm -f /home/liveuser/.config/dconf/user

if [[ ! -s /usr/share/mate-panel/layouts/default.layout ]] ||
   ! grep -Fq 'NotificationAreaAppletFactory::NotificationArea' /usr/share/mate-panel/layouts/default.layout ||
   ! grep -Fq '[Object separator]' /usr/share/mate-panel/layouts/default.layout ||
   ! grep -Fq 'GvcAppletFactory::GvcApplet' /usr/share/mate-panel/layouts/default.layout; then
  echo "VENOM MATE panel layout is missing the notification area, separator or native volume applet." >&2
  exit 1
fi
for desktop in nm-applet.desktop blueman.desktop; do
  [[ -s "/etc/xdg/autostart/$desktop" ]] || {
    echo "VENOM MATE applet autostart missing: $desktop" >&2
    exit 1
  }
  grep -Fq 'OnlyShowIn=MATE;' "/etc/xdg/autostart/$desktop" || {
    echo "VENOM MATE applet autostart is not enabled specifically for MATE: $desktop" >&2
    exit 1
  }
done
[[ ! -e /home/liveuser/.config/dconf/user ]] || {
  echo "Inherited liveuser dconf database can override the VENOM MATE panel defaults." >&2
  exit 1
}
# Default layout is seeded through dconf for a fresh liveuser profile.
# Default launcher is the real Arch online installer. Keep a separate offline profile.
cp -a /etc/calamares /etc/calamares-online
install -m 0644 /etc/calamares/settings_online.conf /etc/calamares-online/settings.conf
cp -a /etc/calamares /etc/calamares-offline
install -m 0644 /etc/calamares/settings_offline.conf /etc/calamares-offline/settings.conf
install -m 0644 /etc/calamares/settings_online.conf /etc/calamares/settings.conf
if [[ ! -f /home/liveuser/.local/share/applications/calamares.desktop ]]; then
  echo "Calamares live-session desktop entry is missing: /home/liveuser/.local/share/applications/calamares.desktop" >&2
  exit 1
fi
sed -i \
  -e 's|^Name=Install System$|Name=Install VENOM OS (online)|' \
  -e 's|^Name\[pt_BR\]=Sistema de Instalação$|Name[pt_BR]=Instalar VENOM OS (online)|' \
  -e 's|^GenericName=System Installer$|GenericName=VENOM OS Online Installer|' \
  -e 's|^GenericName\[pt_BR\]=Instalador de Sistema$|GenericName[pt_BR]=Instalador online da VENOM OS|' \
  -e 's|^Comment=Calamares — System Installer$|Comment=Install VENOM OS using official Arch Linux repositories|' \
  -e 's|^Comment\[pt_BR\]=Calamares — Instalador de Sistema$|Comment[pt_BR]=Instala a VENOM OS pelos repositórios oficiais do Arch Linux|' \
  -e 's|^TryExec=eos-welcome$|TryExec=/usr/bin/calamares|' \
  -e 's|^Exec=eos-welcome$|Exec=sh -c "pkexec /usr/bin/venom-calamares -c /etc/calamares-online"|' \
  /home/liveuser/.local/share/applications/calamares.desktop
grep -Fxq 'TryExec=/usr/bin/calamares' /home/liveuser/.local/share/applications/calamares.desktop || {
  echo "Calamares desktop entry has an invalid TryExec value." >&2
  exit 1
}
grep -Fxq 'Name=Install VENOM OS (online)' /home/liveuser/.local/share/applications/calamares.desktop || {
  echo "Calamares online launcher is not branded as VENOM OS." >&2
  exit 1
}
grep -Fxq 'Name[pt_BR]=Instalar VENOM OS (online)' /home/liveuser/.local/share/applications/calamares.desktop || {
  echo "Calamares online launcher has no VENOM OS Portuguese label." >&2
  exit 1
}
grep -Fxq 'Exec=sh -c "pkexec /usr/bin/venom-calamares -c /etc/calamares-online"' /home/liveuser/.local/share/applications/calamares.desktop || {
  echo "Calamares online desktop entry has an invalid Exec value." >&2
  exit 1
}
cat > /home/liveuser/.local/share/applications/venom-installer-offline.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Instalar VENOM OS (offline)
Name[pt_BR]=Instalar VENOM OS (offline)
Comment=Instala a VENOM OS usando a imagem incluída na ISO
Exec=sh -c "pkexec /usr/bin/venom-calamares -c /etc/calamares-offline"
TryExec=/usr/bin/calamares
Icon=calamares
Terminal=false
Categories=System;
DESKTOP
chown liveuser:liveuser /home/liveuser/.local/share/applications/venom-installer-offline.desktop
if [[ ! -f /etc/polkit-1/rules.d/49-venom-calamares.rules ]]; then
  echo "Restricted live-session Polkit rule for Calamares is missing." >&2
  exit 1
fi
grep -Fq 'action.id === "com.github.calamares.calamares.pkexec.run"' /etc/polkit-1/rules.d/49-venom-calamares.rules || {
  echo "Calamares Polkit action ID is not authorized by the live rule." >&2
  exit 1
}
grep -Fq 'subject.user === "liveuser"' /etc/polkit-1/rules.d/49-venom-calamares.rules || {
  echo "Calamares Polkit rule is not restricted to liveuser." >&2
  exit 1
}
"""
calamares_install_matches = list(calamares_install_pattern.finditer(s))
if len(calamares_install_matches) != 1:
    raise SystemExit(
        'Contrato de instalação local do Calamares inválido: '
        f'esperada exatamente 1 ocorrência do comando pacman -U de /root/packages, '
        f'encontradas {len(calamares_install_matches)}. '
        'O script upstream mudou; revisar sua estrutura antes de continuar.'
    )
install_match = calamares_install_matches[0]
# Local package installation must not use --needed: the Live image must
# reinstall the exact package payload even if pacman already considers it installed.
s = calamares_install_pattern.sub(
    lambda match: install_match.group('indent')
    + 'pacman -U --noconfirm -- "/root/packages/"*".pkg.tar.zst"\n'
    + "chmod 0755 /usr/bin/venom-calamares\n"
    + calamares_patch,
    s,
    count=1,
)
package_archive_marker = 'rm -rf "/root/packages/"\n'
# Both Calamares modes copy the complete installed filesystem from airootfs.sfs.
# Embedding the already-installed app archives a second time only bloats the ISO.
# Keep the configured Bibata variant and remove the unused variants.
package_archive_copy = 'echo "VENOM apps are already installed in the Live filesystem; removing redundant package archives."\nrm -rf "/root/packages/"\nfor theme in /usr/share/icons/Bibata-*; do [[ -e "$theme" ]] || continue; [[ "${theme##*/}" == "Bibata-Modern-Classic" ]] || rm -rf -- "$theme"; done\n'
if package_archive_marker not in s:
    raise SystemExit('Não foi possível preservar os pacotes próprios VENOM para o instalador online.')
s = s.replace(package_archive_marker, package_archive_copy, 1)
os_marker = 'echo "---> Install locally built packages on ISO (place packages under airootfs/root/packages) --->"'
os_patch = 'sed -i -e \'s/^NAME=.*/NAME="VENOM OS"/\' -e \'s/^PRETTY_NAME=.*/PRETTY_NAME="VENOM OS"/\' -e \'s/^ID=.*/ID=venom/\' -e \'s/^ID_LIKE=.*/ID_LIKE=arch/\' "/etc/os-release"\nif ! grep -q \'^ID_LIKE=\' "/etc/os-release"; then printf \'ID_LIKE=arch\n\' >> "/etc/os-release"; fi\n'
if os_marker not in s:
    raise SystemExit('Não foi possível localizar a etapa de pacotes locais.')
s = s.replace(os_marker, os_patch + os_marker, 1)

# Remove EndeavourOS-only operations from the live-image preparation stage.
s = s.replace('pacman-key --populate archlinux endeavouros', 'pacman-key --populate archlinux')
s = s.replace('cat "/usr/lib/endeavouros-release" >> "/etc/motd"', 'printf "VENOM OS\\nBase Arch Linux\\n" > "/etc/motd"')
s = s.replace('mv "/root/livewall.png" "/usr/share/endeavouros/backgrounds/endeavouros-wallpaper.png"', 'mkdir -p "/usr/share/backgrounds/venom"\nmv "/root/livewall.png" "/usr/share/backgrounds/venom/venom-wallpaper.png"')
s = s.replace('mv "/root/endeavouros-wallpaper.png" "/etc/calamares/files/endeavouros-wallpaper.png"', 'mv "/root/endeavouros-wallpaper.png" "/etc/calamares/files/venom-wallpaper.png"')
s = s.replace('pacman -Sw --noconfirm --cachedir "/usr/share/packages" grub eos-dracut kernel-install-for-dracut os-prober nvidia-open nvidia-hook nvidia-utils nvidia-inst broadcom-wl-dkms', 'true # VENOM installs the complete live image; no EndeavourOS package cache is required.')
s = s.replace('echo "---> get needed packages for offline installs --->"\nmkdir -p "/usr/share/packages"\npacman -Syy\npacman -Sw --noconfirm --cachedir "/usr/share/packages" grub eos-dracut kernel-install-for-dracut os-prober nvidia-open nvidia-hook nvidia-utils nvidia-inst broadcom-wl-dkms', 'echo "---> VENOM OS uses the complete ISO filesystem for both installation modes --->"')
s = s.replace('echo "---> Remove ranked mirrorlist, used for fetching offline packages replacing it with original from package --->"\nmv "/etc/pacman.d/mirrorlist-from-package" "/etc/pacman.d/mirrorlist"', 'echo "---> Arch Linux mirrorlist retained for future updates --->"\nrm -f "/etc/pacman.d/mirrorlist-from-package"')
s = s.replace('systemctl set-default multi-user.target', 'systemctl enable lightdm.service\nsystemctl set-default graphical.target\ndconf update')
s = s.replace('sed -i \'s/EndeavourOS/VENOM OS/g\' "/usr/lib/endeavouros-release"', 'rm -f "/usr/lib/endeavouros-release"; printf "VENOM OS" > "/usr/lib/venom-release"')
p.write_text(s)
PY
rm -rf "$EOS_DIR/airootfs/root/root-theme"

log "Aplicando identidade VENOM OS aos menus de inicialização"
python - "$EOS_DIR" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
for rel in ("efiboot", "syslinux"):
    base = root / rel
    for path in base.rglob("*"):
        if not path.is_file():
            continue
        try:
            content = path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        content = content.replace("EndeavourOS", "VENOM OS")
        if path.name == "archiso_head.cfg":
            lines = []
            for line in content.splitlines():
                if line.strip().startswith("MENU BACKGROUND"):
                    continue
                if line.strip().startswith("MENU TITLE"):
                    line = "MENU TITLE VENOM OS"
                if line.strip().startswith("MENU COLOR title"):
                    line = "MENU COLOR title        1;37;40 #ffffffff #00000000 std"
                lines.append(line)
            content = "\n".join(lines).rstrip() + "\n"
        if path.name == "loader.conf":
            content = "default archiso-x86_64-linux.conf\ntimeout 3\nconsole-mode max\neditor no\nauto-entries no\nauto-firmware no\n"
        if path.name.startswith("archiso-x86_64-linux"):
            content = content.rstrip() + " quiet loglevel=3 vt.global_cursor_default=0\n"
        if path.name == "archiso_sys.cfg":
            content = content.replace("TIMEOUT 150", "TIMEOUT 30")
        path.write_text(content)
splash = root / "syslinux" / "splash.png"
if splash.exists():
    splash.unlink()
PY

log "Definindo identificação da ISO"
python - "$EOS_DIR/profiledef.sh" <<'PY'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
s = s.replace('iso_name="EndeavourOS_Triton"', 'iso_name="VENOM-OS-MATE"')
s = s.replace('iso_label="EOS_$(date +%Y%m)"', 'iso_label="VENOM_$(date +%Y%m)"')
s = s.replace('iso_publisher="EndeavourOS <https://endeavouros.com>"', 'iso_publisher="VENOM OS"')
s = s.replace('iso_application="EndeavourOS Live/Rescue CD"', 'iso_application="VENOM OS Live/Install"')
# XZ prioritizes a smaller download; Live decompression and boot may be slower.
s, count = re.subn(
    r"(?m)^airootfs_image_tool_options=.*$",
    "airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-Xdict-size' '100%' '-b' '1M')",
    s,
    count=1,
)
if count != 1:
    raise SystemExit("Não foi possível configurar SquashFS com XZ de alta compressão.")
p.write_text(s)
PY

log "Construindo Calamares upstream com fluxo de instalação VENOM OS"
CALAMARES_SRC="$WORK/calamares-pkg"
mkdir -p "$CALAMARES_SRC"
curl -fsSL "https://raw.githubusercontent.com/endeavouros-team/PKGBUILDS/$PKGBUILDS_COMMIT/calamares/PKGBUILD" -o "$CALAMARES_SRC/PKGBUILD"
[[ -s "$CALAMARES_SRC/PKGBUILD" ]] || die "PKGBUILD original do Calamares não foi baixado."
cp "$ROOT/scripts/patch-calamares.py" "$CALAMARES_SRC/patch-calamares.py"
mkdir -p "$CALAMARES_SRC/branding"
cp -a "$ROOT/build/calamares/branding/venom" "$CALAMARES_SRC/branding/venom"
cp "$ROOT/build/packages.arch" "$CALAMARES_SRC/branding/packages.arch"
cp "$ROOT/build/packages.mate" "$CALAMARES_SRC/branding/packages.mate"
python - "$CALAMARES_SRC/PKGBUILD" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
source = path.read_text()
source = source.replace("-DCMAKE_BUILD_TYPE=Debug", "-DCMAKE_BUILD_TYPE=Release", 1)
# The webview module is explicitly skipped, so Qt WebEngine is not needed at runtime.
source = source.replace(" 'qt6-webengine'", "", 1)
source = source.replace(" 'doxygen'", "", 1)
# Use makepkg's default stripping instead of shipping debug symbols.
source = source.replace("options=(!strip !emptydirs)", "options=(!emptydirs)", 1)
if "qt6-webengine" in source or "options=(!strip" in source or "webview" not in source:
    raise SystemExit("Calamares size profile is inconsistent with its skipped webview module.")
source = source.replace("depends=( 'qt6-svg'", "depends=( 'xcb-util-cursor' 'qt6-svg'", 1)
if "xcb-util-cursor" not in source:
    raise SystemExit("Não foi possível adicionar a dependência xcb-util-cursor ao pacote Calamares.")
needle = '    awk -i inplace -v version="${pkgver}" -v release="${release_name}" "$replace_command" "${srcdir}/calamares-${pkgver}/data/eos/branding/endeavouros/branding.desc"\n}'
replacement = needle[:-1] + '    python "$startdir/patch-calamares.py" "${srcdir}/calamares-${pkgver}"\n    awk -i inplace -v version="${pkgver}" -v release="${release_name}" "$replace_command" "${srcdir}/calamares-${pkgver}/data/eos/branding/venom/branding.desc"\n}'
if needle not in source:
    raise SystemExit("Não foi possível inserir a identidade VENOM no prepare() do PKGBUILD.")
path.write_text(source.replace(needle, replacement, 1))
PY
(
  cd "$CALAMARES_SRC"
  makepkg --syncdeps --noconfirm
  CALAMARES_PACKAGE="$(find . -maxdepth 1 -type f -name 'calamares-*.pkg.tar.zst' -print -quit)"
  [[ -n "$CALAMARES_PACKAGE" ]] || { echo "Pacote Calamares não foi criado pelo makepkg." >&2; exit 1; }
  bsdtar -tf "$CALAMARES_PACKAGE" | grep -Fxq 'usr/bin/calamares' || {
    echo "O pacote Calamares gerado não contém usr/bin/calamares." >&2
    bsdtar -tf "$CALAMARES_PACKAGE" | grep -E '(^|/)calamares$' >&2 || true
    exit 1
  }
  bsdtar -xOf "$CALAMARES_PACKAGE" usr/bin/calamares >/dev/null || {
    echo "O executável dentro do pacote Calamares não pôde ser lido." >&2
    exit 1
  }
  cp -v "$CALAMARES_PACKAGE" "$PKG_DIR/"
)

log "Construindo Shelly a partir do código oficial fixado"
SHELLY_SRC="$WORK/Shelly-ALPM"
mkdir -p "$SHELLY_SRC"
curl -fsSL "https://raw.githubusercontent.com/Seafoam-Labs/Shelly-ALPM/$SHELLY_COMMIT/PKGBUILD-git" -o "$SHELLY_SRC/PKGBUILD"
[[ -s "$SHELLY_SRC/PKGBUILD" ]] || die "PKGBUILD do Shelly não foi baixado."
for source_file in \
  shellybuild.conf \
  com.shellyorg.shelly.desktop \
  com.shellyorg.shelly-notifications.desktop \
  shelly-flatpak-integrate; do
  curl -fsSL "https://raw.githubusercontent.com/Seafoam-Labs/Shelly-ALPM/$SHELLY_COMMIT/$source_file" \
    -o "$SHELLY_SRC/$source_file"
  [[ -s "$SHELLY_SRC/$source_file" ]] || die "Arquivo auxiliar do Shelly não foi baixado: $source_file"
done
(
  cd "$SHELLY_SRC"
  sed -i 's/#branch=development/#commit='"$SHELLY_COMMIT"'/' PKGBUILD
  makepkg --syncdeps --noconfirm
  find . -maxdepth 1 -type f -name 'shelly-git-*.pkg.tar.zst' ! -name '*-debug-*' -exec cp -v {} "$PKG_DIR/" \;
)

log "Obtendo o pacote binário oficial do tema Bibata pela receita AUR"
# A variante fonte exige python-clickgen, que não existe nos repositórios oficiais.
# A variante -bin distribui os cursores já gerados e elimina essa dependência de build.
BIBATA_SRC="$WORK/bibata-cursor-theme-bin-aur"
BIBATA_COMMIT="$(git ls-remote https://aur.archlinux.org/bibata-cursor-theme-bin.git HEAD | awk 'NR == 1 { print $1; exit }')"
[[ "$BIBATA_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "Não foi possível localizar uma revisão válida da receita binária AUR do Bibata."
clone_at_commit https://aur.archlinux.org/bibata-cursor-theme-bin.git "$BIBATA_SRC" "$BIBATA_COMMIT"
(
  cd "$BIBATA_SRC"
  makepkg --syncdeps --noconfirm
  find . -maxdepth 1 -name 'bibata-cursor-theme-bin-*.pkg.tar.zst' -exec cp -v {} "$PKG_DIR/" \;
)

log "Construindo IPTVnator a partir da receita AUR"
IPTVNATOR_SRC="$WORK/iptvnator-bin-aur"
IPTVNATOR_COMMIT="$(git ls-remote https://aur.archlinux.org/iptvnator-bin.git HEAD | awk 'NR == 1 { print $1; exit }')"
[[ "$IPTVNATOR_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "Não foi possível localizar uma revisão válida da receita AUR do IPTVnator."
clone_at_commit https://aur.archlinux.org/iptvnator-bin.git "$IPTVNATOR_SRC" "$IPTVNATOR_COMMIT"
(
  cd "$IPTVNATOR_SRC"
  makepkg --syncdeps --noconfirm
  find . -maxdepth 1 -name 'iptvnator-bin-*.pkg.tar.zst' -exec cp -v {} "$PKG_DIR/" \;
)

log "Construindo Ferdium a partir da receita AUR"
FERDIUM_SRC="$WORK/ferdium-aur"
FERDIUM_COMMIT="$(git ls-remote https://aur.archlinux.org/ferdium-bin.git HEAD | awk 'NR == 1 { print $1; exit }')"
[[ "$FERDIUM_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "Não foi possível localizar uma revisão válida da receita AUR do Ferdium."
clone_at_commit https://aur.archlinux.org/ferdium-bin.git "$FERDIUM_SRC" "$FERDIUM_COMMIT"
(
  cd "$FERDIUM_SRC"
  makepkg --syncdeps --noconfirm
  find . -maxdepth 1 -name 'ferdium-bin-*.pkg.tar.zst' -exec cp -v {} "$PKG_DIR/" \;
)

shopt -s nullglob
for package in "$PKG_DIR"/*.pkg.tar.zst; do
  cp -v "$package" "$EOS_DIR/airootfs/root/packages/"
done
shopt -u nullglob

[[ -n "$(find "$EOS_DIR/airootfs/root/packages" -maxdepth 1 -name '*.pkg.tar.zst' -print -quit)" ]] || die "Nenhum pacote local foi preparado."
[[ -f "$EOS_DIR/airootfs/root/packages/$(basename "$(find "$EOS_DIR/airootfs/root/packages" -maxdepth 1 -name 'calamares-*.pkg.tar.zst' -print -quit)")" ]] || die "Pacote Calamares do EndeavourOS não foi gerado."
[[ -f "$EOS_DIR/airootfs/root/packages/$(basename "$(find "$EOS_DIR/airootfs/root/packages" -maxdepth 1 -name 'shelly-git-*.pkg.tar.zst' -print -quit)")" ]] || die "Pacote Shelly não foi gerado."
[[ -f "$EOS_DIR/airootfs/root/packages/$(basename "$(find "$EOS_DIR/airootfs/root/packages" -maxdepth 1 -name 'ferdium-bin-*.pkg.tar.zst' -print -quit)")" ]] || die "Pacote Ferdium não foi gerado."
[[ -f "$EOS_DIR/airootfs/root/packages/$(basename "$(find "$EOS_DIR/airootfs/root/packages" -maxdepth 1 -name 'iptvnator-bin-*.pkg.tar.zst' -print -quit)")" ]] || die "Pacote IPTVnator não foi gerado."
[[ -f "$EOS_DIR/airootfs/root/packages/$(basename "$(find "$EOS_DIR/airootfs/root/packages" -maxdepth 1 -name 'bibata-cursor-theme-bin-*.pkg.tar.zst' -print -quit)")" ]] || die "Pacote Bibata não foi gerado."

log "Preparando framework EndeavourOS"
(
  cd "$EOS_DIR"
  ./prepare.sh
)

# prepare.sh only prepares the airootfs and queues locally built packages.
# Calamares is installed later by run_before_squashfs.sh, so its binary must be
# checked inside that hook, immediately after pacman -U installs the local package.
log "Validando wrapper VENOM do instalador após prepare.sh"
VENOM_LAUNCHER="$EOS_DIR/airootfs/usr/bin/venom-calamares"
[[ -f "$VENOM_LAUNCHER" ]] || die "Wrapper VENOM do Calamares ausente no airootfs: $VENOM_LAUNCHER"
chmod 0755 "$VENOM_LAUNCHER"
[[ -x "$VENOM_LAUNCHER" ]] || die "Wrapper VENOM do Calamares continua sem permissão de execução: $VENOM_LAUNCHER"
log "Wrapper VENOM confirmado; o executável Calamares será validado no hook após a instalação do pacote local."

log "Compilando ISO VENOM OS. Esta etapa pode levar bastante tempo."
(
  cd "$EOS_DIR"
  sudo ./mkarchiso -v .
)

log "Arquivos ISO gerados:"
find "$EOS_DIR/out" -maxdepth 1 -type f -name '*.iso' -printf '%p (%k KiB)\n'
