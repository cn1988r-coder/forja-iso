#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C
DESKTOP="${FORJA_DESKTOP:-mate}"
KERNEL="${FORJA_KERNEL:-lts}"
WORK=/tmp/forja-arch
OUT="${FORJA_OUTPUT:-/forja-output}"
PROFILE="$WORK/profile"
case "$DESKTOP" in xfce|mate|gnome|kde) ;; *) echo "Desktop inválido: $DESKTOP"; exit 2;; esac
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
bash /forja-ci/build-shelly.sh "$WORK"
SHELLY_HTTP_PID="$(cat "$WORK/shelly-http.pid")"
trap 'kill "$SHELLY_HTTP_PID" >/dev/null 2>&1 || true' EXIT
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
common = ["xorg-server", "networkmanager", "linux-firmware", kernel]
optional_common = ["network-manager-applet", "firefox", "archinstall"]
desktop_packages = {
 "xfce": ["xfce4", "xfce4-goodies", "lightdm", "lightdm-gtk-greeter"],
 "mate": [],
 "gnome": ["gnome", "gdm"],
 "kde": ["plasma", "konsole", "dolphin", "sddm"],
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
        ("mate-terminal", "xfce4-terminal"),
        ("caja", "thunar"),
        ("mate-applets", None),
        ("mate-power-manager", "xfce4-power-manager"),
        ("mate-screensaver", "xfce4-screensaver"),
        ("mate-notification-daemon", "xfce4-notifyd"),
        ("engrampa", "xarchiver"),
        ("atril", "evince"),
        ("eom", "ristretto"),
        ("pluma", "mousepad"),
        ("mate-system-monitor", "xfce4-taskmanager"),
        ("mate-calc", "galculator"),
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
WANTS="$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANTS"
ln -sfn /usr/lib/systemd/system/NetworkManager.service "$WANTS/NetworkManager.service"
if [[ "$DESKTOP" == mate ]]; then
  ln -sfn /usr/lib/systemd/system/bluetooth.service "$WANTS/bluetooth.service"
fi
case "$DESKTOP" in
  xfce|mate) DM=lightdm ;;
  gnome) DM=gdm ;;
  kde) DM=sddm ;;
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
