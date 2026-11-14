#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C
DESKTOP="${FORJA_DESKTOP:-mate}"
KERNEL="${FORJA_KERNEL:-lts}"
WORK=/tmp/forja-manjaro
OUT="${FORJA_OUTPUT:-/forja-output}"
PROFILE_ROOT=/usr/share/manjaro-tools/iso-profiles
CHROOTS="$WORK/chroots"

mkdir -p "$WORK" "$OUT" "$CHROOTS"
PACMAN_CONF=""
pacman_info() {
  if [[ -n "$PACMAN_CONF" ]]; then pacman --config "$PACMAN_CONF" -Si "$1"; else pacman -Si "$1"; fi
}
case "$DESKTOP" in xfce|mate|gnome|kde) ;; *) echo "Desktop invÃ¡lido: $DESKTOP"; exit 2;; esac
case "$KERNEL" in latest|lts) ;; *) echo "Kernel invÃ¡lido: $KERNEL"; exit 2;; esac

echo "== Forja Cloud Builder: Manjaro / $DESKTOP / $KERNEL =="
pacman -Syu --noconfirm
BUILD_TOOLS=(git base-devel make python python-yaml python-jinja python-requests curl jq libxslt docbook2x docbook-xsl squashfs-tools dosfstools libisoburn mtools grub efibootmgr cdrtools rsync wget gawk mhwd)
MISSING_BUILD_TOOLS=()
for package in "${BUILD_TOOLS[@]}"; do
  if ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" >/dev/null 2>&1; then
    MISSING_BUILD_TOOLS+=("$package")
  fi
done
if (("${#MISSING_BUILD_TOOLS[@]}")); then
  printf "ERRO: dependências do construtor Manjaro ausentes: %s\\n" "${MISSING_BUILD_TOOLS[*]}" >&2
  exit 10
fi
pacman -S --needed --noconfirm "${BUILD_TOOLS[@]}"

git clone --depth 1 https://code.manjaro.org/tools/manjaro-tools.git "$WORK/manjaro-tools"
make -C "$WORK/manjaro-tools" SYSCONFDIR=/etc PREFIX=/usr
make -C "$WORK/manjaro-tools" SYSCONFDIR=/etc PREFIX=/usr install_base
make -C "$WORK/manjaro-tools" SYSCONFDIR=/etc PREFIX=/usr install_yaml
make -C "$WORK/manjaro-tools" SYSCONFDIR=/etc PREFIX=/usr install_iso

# Build Shelly from its pinned upstream PKGBUILD and expose it through a local
# HTTP repository consumed by buildiso. The package is compiled on Manjaro so
# its libalpm ABI matches the target system.
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
PACMAN_CONF="$WORK/shelly-pacman.conf"
SHELLY_HTTP_PID="$(cat "$WORK/shelly-http.pid")"
kill -0 "$SHELLY_HTTP_PID"

# Use the current official Forgejo endpoint directly. Older manjaro-tools
# releases still point buildiso -i at the retired gitlab.manjaro.org hostname.
# Retry transient network/server errors with increasing backoff.
rm -rf "$PROFILE_ROOT"
PROFILE_READY=0
PROFILE_REPO="https://code.manjaro.org/profiles/iso-profiles.git"
for attempt in 1 2 3 4 5 6 7 8; do
  echo "Obtendo perfis oficiais: tentativa $attempt/8"
  if git -c http.version=HTTP/1.1 clone --depth 1 --single-branch --branch v17.1 "$PROFILE_REPO" "$PROFILE_ROOT" \
      && [[ -d "$PROFILE_ROOT/manjaro/xfce" && -d "$PROFILE_ROOT/shared" ]]; then
    PROFILE_READY=1
    break
  fi
  rm -rf "$PROFILE_ROOT"
  delay=$((attempt * 15))
  echo "Aviso: clone dos perfis falhou; nova tentativa em ${delay}s."
  sleep "$delay"
done
[[ "$PROFILE_READY" == 1 ]] || {
  echo "ERRO: nÃ£o foi possÃ­vel obter os perfis oficiais do Manjaro no endpoint atual apÃ³s 8 tentativas."
  exit 20
}

case "$DESKTOP" in
  xfce) SOURCE="$PROFILE_ROOT/manjaro/xfce" ;;
  gnome) SOURCE="$PROFILE_ROOT/manjaro/gnome" ;;
  kde) SOURCE="$PROFILE_ROOT/manjaro/kde" ;;
  mate) SOURCE="$PROFILE_ROOT/manjaro/xfce" ;;
esac
test -f "$SOURCE/Packages-Desktop" && test -f "$SOURCE/profile.conf" || {
  echo "ERRO: perfil-base invÃ¡lido: $SOURCE"
  exit 21
}

TARGET="$PROFILE_ROOT/manjaro/forja-$DESKTOP"
rm -rf "$TARGET"
cp -a "$SOURCE" "$TARGET"

# Shelly-ALPM is built locally and served over HTTP to buildiso.
rm -f "$TARGET/user-repos.conf"
cat > "$TARGET/user-repos.conf" <<'REPO'
[forja-shelly]
SigLevel = Optional TrustAll
Server = http://127.0.0.1:8765/$repo/$arch
REPO
printf '\nshelly\nshelly-flatpak-backend\n' >> "$TARGET/Packages-Desktop"

# The XFCE profile is only a base for shared Manjaro boot/installer files.
# Materialize overlays before editing so no shared profile outside this custom
# clone is changed. Remove XFCE-only defaults and force the MATE LightDM session.
for overlay_name in desktop-overlay live-overlay; do
  overlay="$TARGET/$overlay_name"
  if [[ -L "$overlay" ]]; then
    overlay_source="$(readlink -f "$overlay")"
    rm "$overlay"
    cp -a "$overlay_source" "$overlay"
  fi
  if [[ -d "$overlay" ]]; then
    # Só remova componentes XFCE quando o perfil escolhido for MATE.
    # Fazer isso nos outros perfis apagava arquivos do próprio XFCE.
    if [[ "$DESKTOP" == mate ]]; then
      find "$overlay" -depth -iname '*xfce*' -exec rm -rf {} +
      mkdir -p "$overlay/etc/dconf/profile" "$overlay/etc/dconf/db/local.d"
      cat > "$overlay/etc/dconf/profile/user" <<'DCPROFILE'
user-db:user
system-db:local
DCPROFILE
      cat > "$overlay/etc/dconf/db/local.d/00-forja-visual" <<'DCCONF'
[org/mate/interface]
icon-theme='Papirus-Dark'
cursor-theme='Bibata-Modern-Ice'
gtk-theme='Materia-dark'

[org/mate/marco/general]
theme='Materia-dark'
DCCONF
      # Firefox is the system default for HTTP/HTTPS and HTML documents.
      mkdir -p "$overlay/etc/xdg" "$overlay/etc/skel/.config"
      cat > "$overlay/etc/xdg/mimeapps.list" <<'MIMEAPPS'
[Default Applications]
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
text/html=firefox.desktop
application/xhtml+xml=firefox.desktop
MIMEAPPS
      install -Dm644 "$overlay/etc/xdg/mimeapps.list" "$overlay/etc/skel/.config/mimeapps.list"
      mkdir -p "$overlay/usr/share/icons/default"
      cat > "$overlay/usr/share/icons/default/index.theme" <<'CURSOR'
[Icon Theme]
Name=Default
Comment=Default cursor theme for Forja MATE
Inherits=Bibata-Modern-Ice
CURSOR
      # Keep Papirus Dark's built-in default folder icons.
      # No papirus-folders customization package or service is required.
      rm -f "$overlay/etc/systemd/system/forja-papirus-cyan.service"
      rm -f "$overlay/etc/systemd/system/multi-user.target.wants/forja-papirus-cyan.service"
    fi
    # XFCE e MATE usam LightDM. GNOME e KDE mantêm seus próprios
    # gerenciadores (GDM/Plasma Login Manager) e não recebem configuração LightDM.
    if [[ "$DESKTOP" == mate || "$DESKTOP" == xfce ]]; then
      SESSION="$DESKTOP"
      mkdir -p "$overlay/etc/lightdm/lightdm.conf.d"
      cat > "$overlay/etc/lightdm/lightdm.conf.d/50-forja-$DESKTOP.conf" <<LIGHTDM
[Seat:*]
user-session=$SESSION
greeter-session=lightdm-gtk-greeter
LIGHTDM
      if [[ -f "$overlay/etc/lightdm/lightdm.conf" ]]; then
        awk -v session="$SESSION" '
          BEGIN { in_seat=0; found=0 }
          /^\[Seat:\*\][[:space:]]*$/ {
            in_seat=1; found=1; print
            print "user-session=" session
            print "greeter-session=lightdm-gtk-greeter"
            next
          }
          /^\[/ { in_seat=0 }
          in_seat && /^[[:space:]]*#?(user-session|greeter-session)=/ { next }
          { print }
          END {
            if (!found) {
              print ""
              print "[Seat:*]"
              print "user-session=" session
              print "greeter-session=lightdm-gtk-greeter"
            }
          }
        ' "$overlay/etc/lightdm/lightdm.conf" > "$overlay/etc/lightdm/lightdm.conf.forja"
        mv "$overlay/etc/lightdm/lightdm.conf.forja" "$overlay/etc/lightdm/lightdm.conf"
      fi
      if [[ -f "$overlay/etc/lightdm/lightdm-gtk-greeter.conf" ]]; then
        sed -i -E 's/^icon-theme-name[[:space:]]*=.*/icon-theme-name = Adwaita/; s/^cursor-theme-name[[:space:]]*=.*/cursor-theme-name = Adwaita/' "$overlay/etc/lightdm/lightdm-gtk-greeter.conf"
      fi
    fi
  fi
done

# The official XFCE profile inherits shared package lists through symlinks.
# Stable repositories may no longer carry some legacy packages from those
# lists. Materialize each list locally and remove only entries that pacman
# confirms are absent from the synchronized stable databases.
for package_list in "$TARGET"/Packages-*; do
  [[ -f "$package_list" ]] || continue
  if [[ -L "$package_list" ]]; then
    resolved_list="$(readlink -f "$package_list")"
    cp "$resolved_list" "$package_list.materialized"
    mv "$package_list.materialized" "$package_list"
  fi
done

# Full package preflight runs after the desktop-specific list is finalized.

if [[ "$DESKTOP" == mate ]]; then
  # Keep MATE as the session. Remove XFCE session components and its branding,
  # but allow selected standalone XFCE utilities as replacements for missing
  # optional MATE applications.
  awk 'BEGIN{IGNORECASE=1}
    /^[[:space:]]*#/ || /^[[:space:]]*$/ {print;next}
    {
      p=$1
      if(p ~ /^>/ && NF > 1) p=$2
      if(p ~ /^(xfce4|xfce4-[^ ]*|exo|garcon|xfconf|thunar|thunar-[^ ]*|tumbler|menulibre|mugshot|ristretto|mousepad|parole|orage|catfish|xfburn|xfdesktop[^ ]*|xfwm4[^ ]*|galculator|evince|manjaro-xfce-settings|manjaro-xfce-minimal-settings|snapd|snapd-glib|pamac-snap-plugin|gnome-software-snap)$/) next
      print
    }' "$TARGET/Packages-Desktop" > "$TARGET/Packages-Desktop.new"
  mv "$TARGET/Packages-Desktop.new" "$TARGET/Packages-Desktop"

  cat >> "$TARGET/Packages-Desktop" <<'PKGS'

# Forja MATE core and login/session stack
mate-session-manager
mate-panel
mate-control-center
mate-settings-daemon
marco
lightdm
lightdm-gtk-greeter
network-manager-applet
bluez
bluez-utils
blueman
papirus-icon-theme
manjaro-wallpapers-18.0
dconf
bibata-cursor-theme
materia-gtk-theme
firefox
PKGS

  MATE_CORE_PACKAGES=(
    systemd grub efibootmgr mkinitcpio calamares linux-firmware
    manjaro-release manjaro-keyring manjaro-system pacman-mirrors mhwd mhwd-db
    networkmanager mate-session-manager mate-panel mate-control-center
    mate-settings-daemon marco lightdm lightdm-gtk-greeter firefox
    network-manager-applet bluez bluez-utils blueman
    papirus-icon-theme manjaro-wallpapers-18.0 dconf
    bibata-cursor-theme materia-gtk-theme
  )
  MATE_MISSING_CORE=()
  for package in "${MATE_CORE_PACKAGES[@]}"; do
    if ! pacman_info "$package" >/dev/null 2>&1; then
      MATE_MISSING_CORE+=("$package")
    fi
  done
  if (("${#MATE_MISSING_CORE[@]}")); then
    printf 'ERRO: componentes essenciais do MATE/LightDM/rede/Bluetooth ausentes: %s\n' "${MATE_MISSING_CORE[*]}" >&2
    exit 22
  fi

  # package:fallback. The fallback is a single utility, not the XFCE desktop.
  MATE_OPTIONAL_PAIRS=(
    mate-themes:adwaita-gtk-theme
    mate-icon-theme:adwaita-icon-theme
    adwaita-icon-theme:
    adwaita-cursors:
    mate-terminal:xfce4-terminal
    caja:thunar
    mate-applets:
    mate-power-manager:xfce4-power-manager
    mate-screensaver:xfce4-screensaver
    mate-notification-daemon:xfce4-notifyd
    engrampa:xarchiver
    atril:evince
    eom:ristretto
    pluma:mousepad
    mate-system-monitor:xfce4-taskmanager
    mate-calc:galculator
  )
  for pair in "${MATE_OPTIONAL_PAIRS[@]}"; do
    package="${pair%%:*}"
    fallback="${pair#*:}"
    if pacman_info "$package" >/dev/null 2>&1; then
      printf '%s\n' "$package" >> "$TARGET/Packages-Desktop"
    elif [[ -n "$fallback" ]] && pacman_info "$fallback" >/dev/null 2>&1; then
      printf '%s\n' "$fallback" >> "$TARGET/Packages-Desktop"
      echo "Aviso: $package ausente; usando utilitÃ¡rio equivalente $fallback."
    else
      echo "Aviso: $package e seu substituto ${fallback:-nÃ£o definido} nÃ£o estÃ£o disponÃ­veis; utilitÃ¡rio opcional ignorado."
    fi
  done
  for package in papirus-icon-theme manjaro-wallpapers-18.0 dconf materia-gtk-theme; do
    if ! pacman_info "$package" >/dev/null 2>&1; then
      echo "ERRO: pacote visual oficial nÃ£o disponÃ­vel no Manjaro: $package" >&2
      exit 23
    fi
  done
  if ! pacman --config "$PACMAN_CONF" -Si bibata-cursor-theme >/dev/null 2>&1; then
    echo "ERRO: pacote visual AUR não publicado no repositório local: bibata-cursor-theme" >&2
    exit 24
  fi
  echo "Preflight do nÃºcleo MATE, rede, Bluetooth e temas visuais aprovado."
fi

# Resolve every package list used by the selected profile, including the
# shared files reached through >systemd, >extra, >multilib, and >manjaro.
# Manjaro package-list syntax permits ">repo package" on one line; checking
# only the first token silently skips those package names (the previous bug).
declare -A FILTERED_PACKAGE_LISTS=()
while IFS= read -r -d '' package_list; do
  resolved_list="$(readlink -f "$package_list")"
  [[ -n "$resolved_list" && -f "$resolved_list" ]] || continue
  [[ -z "${FILTERED_PACKAGE_LISTS[$resolved_list]:-}" ]] || continue
  FILTERED_PACKAGE_LISTS["$resolved_list"]=1
  filtered_list="$resolved_list.forja-filtered"
  : > "$filtered_list"
  while IFS= read -r line || [[ -n "$line" ]]; do
    read -r -a fields <<< "$line"
    if [[ -z "${fields[0]:-}" || "${fields[0]}" == \#* ]]; then
      printf '%s\n' "$line" >> "$filtered_list"
      continue
    fi
    # >extra, >basic, >multilib e >x86_64 são seletores do perfil Manjaro,
    # não nomes de repositórios. Pode haver vários antes do pacote.
    package=""
    for token in "${fields[@]}"; do
      [[ "$token" == \#* ]] && break
      [[ "$token" == \>* ]] && continue
      package="$token"
      break
    done
    if [[ -z "$package" || "$package" == KERNEL || "$package" == KERNEL-* ]]; then
      printf '%s\n' "$line" >> "$filtered_list"
    elif pacman_info "$package" >/dev/null 2>&1; then
      printf '%s\n' "$line" >> "$filtered_list"
    else
      echo "Aviso: pacote ausente removido: $package (lista $resolved_list)" >&2
      printf '# Forja: pacote ausente removido: %s\n' "$package" >> "$filtered_list"
    fi
  done < "$resolved_list"
  mv "$filtered_list" "$resolved_list"
done < <(find -L "$PROFILE_ROOT/shared" "$TARGET" -type f -name 'Packages-*' -print0 | sort -zu)


# Componentes fundamentais da instalação e do ambiente selecionado não podem
# ser removidos como opcionais: a ausência deles deve parar a ISO com clareza.
BASE_CORE_PACKAGES=(systemd grub efibootmgr mkinitcpio calamares linux-firmware manjaro-release manjaro-keyring manjaro-system pacman-mirrors mhwd mhwd-db networkmanager)
case "$DESKTOP" in
  xfce) DESKTOP_CORE_PACKAGES=(xfce4-panel xfce4-session xfce4-settings xfdesktop xfwm4 lightdm lightdm-gtk-greeter) ;;
  gnome) DESKTOP_CORE_PACKAGES=(gnome-shell gdm gnome-control-center nautilus) ;;
  kde) DESKTOP_CORE_PACKAGES=(sddm plasma-desktop plasma-workspace kwin) ;;
  mate) DESKTOP_CORE_PACKAGES=(mate-session-manager mate-panel mate-control-center mate-settings-daemon marco lightdm lightdm-gtk-greeter firefox) ;;
esac
MISSING_CORE_PACKAGES=()
for package in "${BASE_CORE_PACKAGES[@]}" "${DESKTOP_CORE_PACKAGES[@]}"; do
  if ! pacman_info "$package" >/dev/null 2>&1; then
    MISSING_CORE_PACKAGES+=("$package")
  fi
done
if (("${#MISSING_CORE_PACKAGES[@]}")); then
  printf "ERRO: componentes essenciais ausentes para Manjaro/%s: %s\\n" "$DESKTOP" "${MISSING_CORE_PACKAGES[*]}" >&2
  exit 25
fi
echo "Preflight de componentes essenciais Manjaro/$DESKTOP aprovado."

case "$DESKTOP" in
  xfce|mate) DM=lightdm ;;
  gnome) DM=gdm ;;
  # O perfil Manjaro estável v17.1 usa SDDM; manter o gerenciador
  # de login fornecido pelo próprio perfil oficial.
  kde) DM=sddm ;;
esac
if grep -q '^#\?displaymanager=' "$TARGET/profile.conf"; then
  sed -i "s/^#\?displaymanager=.*/displaymanager=\"$DM\"/" "$TARGET/profile.conf"
else
  printf '\ndisplaymanager="%s"\n' "$DM" >> "$TARGET/profile.conf"
fi

if [[ "$DESKTOP" == mate ]]; then
  # Preserve the upstream service set. Remove Snap services and add only the
  # network/Bluetooth services if the profile does not already enable them.
  sed -i "s/'snapd.apparmor'//g; s/'snapd'//g" "$TARGET/profile.conf"
  if grep -Eq '^enable_systemd=' "$TARGET/profile.conf"; then
    grep -q "'NetworkManager'" "$TARGET/profile.conf" || sed -i "s/^enable_systemd=(/enable_systemd=('NetworkManager' /" "$TARGET/profile.conf"
    grep -q "'bluetooth'" "$TARGET/profile.conf" || sed -i "s/^enable_systemd=(/enable_systemd=('bluetooth' /" "$TARGET/profile.conf"
  else
    printf "\nenable_systemd=('NetworkManager' 'bluetooth')\n" >> "$TARGET/profile.conf"
  fi
  if grep -Eq '^enable_systemd_live=' "$TARGET/profile.conf"; then
    grep -q "'NetworkManager'" "$TARGET/profile.conf" || sed -i "s/^enable_systemd_live=(/enable_systemd_live=('NetworkManager' /" "$TARGET/profile.conf"
    grep -q "'bluetooth'" "$TARGET/profile.conf" || sed -i "s/^enable_systemd_live=(/enable_systemd_live=('bluetooth' /" "$TARGET/profile.conf"
  else
    printf "\nenable_systemd_live=('NetworkManager' 'bluetooth' 'manjaro-live' 'mhwd-live' 'pacman-init' 'mirrors-live')\n" >> "$TARGET/profile.conf"
  fi
fi
# Resolve a kernel package present in Manjaro stable. Pick the newest long-term
# release for LTS and the newest stable release for latest, then map to linuxXY.
KERNEL_PKG="$(python - "$KERNEL" <<'PY'
import json, re, subprocess, sys, urllib.request

kind = sys.argv[1]
result = subprocess.run(
    ["pacman", "-Sl"],
    check=True, capture_output=True, text=True
)
available = {}
for line in result.stdout.splitlines():
    fields = line.split()
    if len(fields) < 3 or not re.fullmatch(r"linux[0-9]+", fields[1]):
        continue
    package, version = fields[1], fields[2]
    # Ignore release candidates and other pre-release packages (for example 7.4.0rc2).
    match = re.fullmatch(r"(\d+)\.(\d+)(?:\.(\d+))?-\d+", version)
    if not match:
        continue
    major, minor = int(match.group(1)), int(match.group(2))
    patch = int(match.group(3) or 0)
    if package != "linux" + str(major) + str(minor):
        continue
    available[package] = (major, minor, patch)

if not available:
    raise SystemExit("Nenhum kernel estável foi encontrado nos repositórios Manjaro configurados.")

if kind == "latest":
    # Latest means newest stable kernel package actually published by Manjaro,
    # not an upstream release or release candidate that Manjaro has not adopted.
    package = max(available, key=lambda name: available[name])
else:
    with urllib.request.urlopen("https://www.kernel.org/releases.json", timeout=30) as response:
        data = json.load(response)
    candidates = []
    for release in data["releases"]:
        if release.get("moniker") != "longterm":
            continue
        match = re.match(r"^(\d+)\.(\d+)", release.get("version", ""))
        if not match:
            continue
        major, minor = int(match.group(1)), int(match.group(2))
        candidate = "linux" + str(major) + str(minor)
        if candidate in available:
            candidates.append(((major, minor), candidate))
    if not candidates:
        raise SystemExit("Nenhum kernel LTS do kernel.org está disponível nos repositórios Manjaro configurados.")
    package = max(candidates, key=lambda item: item[0])[1]

check = subprocess.run(
    ["pacman", "-Si", package],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)
if check.returncode:
    raise SystemExit("Kernel Manjaro " + package + " não está disponível nos repositórios configurados.")
print(package)
PY
)"
echo "Kernel selecionado: $KERNEL_PKG"
if [[ "${FORJA_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  echo "PREFLIGHT_OK: Manjaro/$DESKTOP/$KERNEL ($KERNEL_PKG). ISO build intentionally skipped."
  exit 0
fi

cd "$PROFILE_ROOT"
buildiso -f -p "forja-$DESKTOP" -b stable -k "$KERNEL_PKG" -r "$CHROOTS" -t "$OUT" -v

ISO="$(find "$OUT" -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"
test -n "$ISO" && test -s "$ISO" || {
  echo "ERRO: buildiso terminou sem produzir ISO."
  exit 30
}
SIZE="$(stat -c '%s' "$ISO")"
(( SIZE >= 100000000 )) || { echo "ISO pequena/incompleta: $SIZE bytes"; exit 31; }
sha256sum "$ISO" | tee "$ISO.sha256"
printf 'ISO_FILE=%s\nISO_SIZE=%s\nDESKTOP=%s\nKERNEL=%s\nKERNEL_PACKAGE=%s\nBASE=Manjaro\n' "$(basename "$ISO")" "$SIZE" "$DESKTOP" "$KERNEL" "$KERNEL_PKG" > "$OUT/build-info.txt"
echo "BUILD_OK: $ISO"
