#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C
DESKTOP="${FORJA_DESKTOP:-mate}"
KERNEL="${FORJA_KERNEL:-lts}"
WORK=/tmp/forja-arch
OUT="${FORJA_OUTPUT:-/forja-output}"
PROFILE="$WORK/profile"
case "$DESKTOP" in xfce|mate|gnome) ;; *) echo "Desktop inválido: $DESKTOP"; exit 2;; esac
case "$KERNEL" in latest) KERNEL_PKG=linux;; lts) KERNEL_PKG=linux-lts;; *) echo "Kernel inválido: $KERNEL"; exit 2;; esac
mkdir -p "$WORK" "$OUT"
echo "== Forja Cloud Builder: Arch Linux / $DESKTOP / $KERNEL =="
# python is required below to build the selected package list.
pacman -Syu --noconfirm
ARCH_BUILD_PACKAGES=(archiso python)
MISSING_ARCH_BUILD_PACKAGES=()
for package in "${ARCH_BUILD_PACKAGES[@]}"; do
  pacman -Si "$package" >/dev/null 2>&1 || MISSING_ARCH_BUILD_PACKAGES+=("$package")
done
if (("${#MISSING_ARCH_BUILD_PACKAGES[@]}")); then
  printf "ERRO: dependências do construtor Arch ausentes: %s\\n" "${MISSING_ARCH_BUILD_PACKAGES[*]}" >&2
  exit 10
fi
pacman -S --needed --noconfirm "${ARCH_BUILD_PACKAGES[@]}"
rm -f "$WORK/shelly-http.pid"
SHELLY_HTTP_PID=""
cleanup_shelly_http() {
  local pid="${SHELLY_HTTP_PID:-}"
  if [[ -z "$pid" && -s "$WORK/shelly-http.pid" ]]; then
    pid="$(cat "$WORK/shelly-http.pid")"
  fi
  if [[ "$pid" =~ ^[0-9]+$ ]]; then
    kill "$pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup_shelly_http EXIT
bash /forja-ci/build-shelly.sh "$WORK"
SHELLY_HTTP_PID="$(cat "$WORK/shelly-http.pid")"
kill -0 "$SHELLY_HTTP_PID"
rm -rf "$PROFILE"
cp -a /usr/share/archiso/configs/releng "$PROFILE"
cat >> "$PROFILE/pacman.conf" <<'REPO'

[forja-shelly]
SigLevel = Optional TrustAll
Server = http://127.0.0.1:8765/$repo/$arch
REPO
python - "$PROFILE/packages.x86_64" "$DESKTOP" "$KERNEL_PKG" "$WORK/shelly-pacman.conf" <<'PY'
import subprocess, sys
from pathlib import Path

path, desktop, kernel, pacman_conf = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]

def available(package):
    info = subprocess.run(
        ["pacman", "--config", pacman_conf, "-Si", package],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    if info.returncode == 0:
        return True
    # Some valid pacman targets are package groups rather than single packages.
    group = subprocess.run(
        ["pacman", "--config", pacman_conf, "-Sgq", package],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    return group.returncode == 0

packages = [x.strip() for x in path.read_text().splitlines() if x.strip() and not x.lstrip().startswith("#")]
packages = [p for p in packages if p not in {"linux", "linux-lts"}]
legacy = {
    "gtk-theme-breath", "galculator-gtk2", "qpdfview", "gconf", "gksu",
    "gnome-icon-theme", "gnome-themes-standard", "appimagelauncher",
    "hexchat", "midori", "pidgin", "sylpheed", "p7zip", "ms-office-online",
    "pulseaudio-ctl", "steam-manjaro", "pamac", "gtk3-print-backends",
    "splix", "pyqt5-common", "gtk-xfce-engine", "xf86-input-keyboard",
    "xf86-input-mouse", "xdg-su", "manjaro-documentation-en", "mlocate",
    "gcc-libs-multilib", "gcc-multilib", "pkg-config", "lib32-flex",
    "lib32-mesa-demos", "xfce4", "xfce4-goodies", "xfce4-terminal",
    "xfce4-power-manager", "xfce4-screensaver", "xfce4-notifyd",
    "xfce4-taskmanager", "thunar", "ristretto", "mousepad", "parole",
    "galculator", "evince", "exo", "garcon", "xfconf", "tumbler",
}
packages = [p for p in packages if p not in legacy and not p.startswith(("nvidia", "lib32-nvidia", "catalyst", "lib32-catalyst"))]
common = ["xorg-server", "networkmanager", "linux-firmware", "materia-gtk-theme", "bibata-cursor-theme", kernel]
optional_common = ["network-manager-applet", "firefox", "archinstall"]
desktop_packages = {
 "xfce": ["xfce4", "xfce4-goodies", "lightdm", "lightdm-gtk-greeter"],
 "mate": [],
 "gnome": ["gnome", "gdm"],
}
if desktop == "mate":
    core = [
        "mate-session-manager", "mate-panel", "mate-control-center",
        "mate-settings-daemon", "marco", "lightdm", "lightdm-gtk-greeter",
        "network-manager-applet", "bluez", "bluez-utils", "blueman",
    ]
    missing = [p for p in core if not available(p)]
    if missing:
        raise SystemExit("Pacotes essenciais MATE/LightDM/rede/Bluetooth ausentes: " + ", ".join(missing))
    desktop_packages["mate"] = core
    fallbacks = [
        ("mate-themes", "adwaita-gtk-theme"),
        ("mate-icon-theme", "adwaita-icon-theme"),
        ("mate-terminal", None),
        ("caja", None),
        ("mate-applets", None),
        ("mate-power-manager", None),
        ("mate-screensaver", None),
        ("mate-notification-daemon", None),
        ("engrampa", "xarchiver"),
        ("atril", "evince"),
        ("eom", None),
        ("pluma", None),
        ("mate-system-monitor", None),
        ("mate-calc", None),
    ]
    for package, fallback in fallbacks:
        if available(package):
            desktop_packages["mate"].append(package)
        elif fallback and available(fallback):
            desktop_packages["mate"].append(fallback)
            print(f"Aviso: {package} ausente; usando utilitário equivalente {fallback}.", file=sys.stderr)
        else:
            print(f"Aviso: utilitário opcional {package} e substituto {fallback or 'não definido'} indisponíveis; ignorado.", file=sys.stderr)

if not available("shelly") or not available("shelly-flatpak-backend"):
    raise SystemExit("Shelly-ALPM não foi publicado no repositório local.")
packages += common + desktop_packages[desktop] + ["shelly", "shelly-flatpak-backend"]
for package in optional_common:
    if available(package):
        packages.append(package)
    else:
        print(f"Aviso: pacote opcional ausente removido da ISO: {package}.", file=sys.stderr)

# Remove entries from the upstream releng package list only when the synchronized
# Arch repositories cannot resolve them. Keep the selected desktop, network,
# kernel and Shelly components mandatory so a missing core dependency is a
# clear preflight error rather than a broken/incomplete ISO.
required = set(common + desktop_packages[desktop] + ["shelly", "shelly-flatpak-backend"])
missing_required = sorted(package for package in required if not available(package))
if missing_required:
    raise SystemExit("Pacotes essenciais ausentes nos repositórios Arch: " + ", ".join(missing_required))

filtered = []
removed = []
for package in dict.fromkeys(packages):
    if available(package):
        filtered.append(package)
    else:
        removed.append(package)
if removed:
    for package in removed:
        print(f"Aviso: pacote ausente removido da ISO: {package}", file=sys.stderr)
path.write_text("\n".join(filtered) + "\n")
print(f"Preflight Arch: {len(filtered)} pacotes mantidos; {len(removed)} ausentes removidos.")
PY
# Bibata como cursor padrão do sistema e de novos usuários.
mkdir -p "$PROFILE/airootfs/usr/share/icons/default" \
         "$PROFILE/airootfs/etc/skel/.config/gtk-3.0" \
         "$PROFILE/airootfs/etc/skel/.config/gtk-4.0"
cat > "$PROFILE/airootfs/usr/share/icons/default/index.theme" <<'CURSOR'
[Icon Theme]
Name=Default
Comment=Forja default cursor
Inherits=Bibata-Modern-Ice
CURSOR
for settings in \
  "$PROFILE/airootfs/etc/gtk-3.0/settings.ini" \
  "$PROFILE/airootfs/etc/gtk-4.0/settings.ini" \
  "$PROFILE/airootfs/etc/skel/.config/gtk-3.0/settings.ini" \
  "$PROFILE/airootfs/etc/skel/.config/gtk-4.0/settings.ini"; do
  mkdir -p "$(dirname "$settings")"
  if [[ -f "$settings" ]]; then
    grep -q '^gtk-cursor-theme-name=' "$settings" && sed -i 's/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Bibata-Modern-Ice/' "$settings" || printf '\ngtk-cursor-theme-name=Bibata-Modern-Ice\n' >> "$settings"
  else
    cat > "$settings" <<'GTK'
[Settings]
gtk-theme-name=Materia-dark
gtk-cursor-theme-name=Bibata-Modern-Ice
GTK
  fi
done
# Tema GTK Materia Dark como padrão em todos os ambientes desta ISO.
mkdir -p "$PROFILE/airootfs/etc/gtk-3.0" "$PROFILE/airootfs/etc/gtk-4.0" \
         "$PROFILE/airootfs/etc/skel/.config/gtk-3.0" \
         "$PROFILE/airootfs/etc/skel/.config/gtk-4.0"
for settings in \
  "$PROFILE/airootfs/etc/gtk-3.0/settings.ini" \
  "$PROFILE/airootfs/etc/gtk-4.0/settings.ini" \
  "$PROFILE/airootfs/etc/skel/.config/gtk-3.0/settings.ini" \
  "$PROFILE/airootfs/etc/skel/.config/gtk-4.0/settings.ini"; do
  cat > "$settings" <<'GTK'
[Settings]
gtk-theme-name=Materia-dark
gtk-cursor-theme-name=Bibata-Modern-Ice
GTK
done
if [[ "$DESKTOP" == gnome || "$DESKTOP" == mate ]]; then
  mkdir -p "$PROFILE/airootfs/etc/dconf/profile" "$PROFILE/airootfs/etc/dconf/db/local.d"
  cat > "$PROFILE/airootfs/etc/dconf/profile/user" <<'DCPROFILE'
user-db:user
system-db:local
DCPROFILE
  if [[ "$DESKTOP" == gnome ]]; then
    cat > "$PROFILE/airootfs/etc/dconf/db/local.d/00-forja-theme" <<'DCCONF'
[org/gnome/desktop/interface]
gtk-theme='Materia-dark'
cursor-theme='Bibata-Modern-Ice'
color-scheme='prefer-dark'
DCCONF
  else
    cat > "$PROFILE/airootfs/etc/dconf/db/local.d/00-forja-theme" <<'DCCONF'
[org/mate/interface]
gtk-theme='Materia-dark'

[org/mate/peripherals-mouse]
cursor-theme='Bibata-Modern-Ice'
DCCONF
  fi
elif [[ "$DESKTOP" == xfce ]]; then
  mkdir -p "$PROFILE/airootfs/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
  cat > "$PROFILE/airootfs/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" <<'XFCONF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Materia-dark"/>
    <property name="CursorThemeName" type="string" value="Bibata-Modern-Ice"/>
  </property>
</channel>
XFCONF
fi
if [[ "$DESKTOP" == gnome || "$DESKTOP" == mate ]]; then
  mkdir -p "$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants"
  cat > "$PROFILE/airootfs/etc/systemd/system/forja-dconf-update.service" <<'UNIT'
[Unit]
Description=Compile Forja system dconf defaults
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/bin/dconf update
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
  ln -sfn /etc/systemd/system/forja-dconf-update.service "$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants/forja-dconf-update.service"
fi

WANTS="$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANTS"
ln -sfn /usr/lib/systemd/system/NetworkManager.service "$WANTS/NetworkManager.service"
if [[ "$DESKTOP" == mate ]]; then
  ln -sfn /usr/lib/systemd/system/bluetooth.service "$WANTS/bluetooth.service"
fi
case "$DESKTOP" in
  xfce|mate) DM=lightdm ;;
  gnome) DM=gdm ;;
esac
mkdir -p "$PROFILE/airootfs/etc/systemd/system"
ln -sfn "/usr/lib/systemd/system/$DM.service" "$PROFILE/airootfs/etc/systemd/system/display-manager.service"
if [[ "$DESKTOP" == mate ]]; then
  mkdir -p "$PROFILE/airootfs/etc/lightdm/lightdm.conf.d"
  cat > "$PROFILE/airootfs/etc/lightdm/lightdm.conf.d/50-forja-mate.conf" <<'LIGHTDM'
[Seat:*]
user-session=mate
greeter-session=lightdm-gtk-greeter
LIGHTDM
fi
if [[ "${FORJA_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  echo "PREFLIGHT_OK: Arch/$DESKTOP/$KERNEL. ISO build intentionally skipped."
  exit 0
fi

mkarchiso -v -w "$WORK/work" -o "$OUT" "$PROFILE"
ISO="$(find "$OUT" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"
test -n "$ISO" && test -s "$ISO"
SIZE="$(stat -c '%s' "$ISO")"
(( SIZE >= 100000000 )) || { echo "ISO pequena/incompleta: $SIZE bytes"; exit 41; }
sha256sum "$ISO" | tee "$ISO.sha256"
printf 'ISO_FILE=%s\nISO_SIZE=%s\nDESKTOP=%s\nKERNEL=%s\nBASE=Arch Linux\n' "$(basename "$ISO")" "$SIZE" "$DESKTOP" "$KERNEL" > "$OUT/build-info.txt"
echo "BUILD_OK: $ISO"
