#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C
DESKTOP=mate
KERNEL="${FORJA_KERNEL:-lts}"
WORK=/tmp/forja-manjaro
OUT="${FORJA_OUTPUT:-/forja-output}"
PROFILE_ROOT=/usr/share/manjaro-tools/iso-profiles
CHROOTS="$WORK/chroots"

mkdir -p "$WORK" "$OUT" "$CHROOTS"
pacman_info() { pacman -Si "$1"; }
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
  printf "ERRO: dependências do construtor Manjaro ausentes: %s\n" "${MISSING_BUILD_TOOLS[*]}" >&2
  exit 10
fi
pacman -S --needed --noconfirm "${BUILD_TOOLS[@]}"

git clone --depth 1 https://code.manjaro.org/tools/manjaro-tools.git "$WORK/manjaro-tools"
make -C "$WORK/manjaro-tools" SYSCONFDIR=/etc PREFIX=/usr
make -C "$WORK/manjaro-tools" SYSCONFDIR=/etc PREFIX=/usr install_base
make -C "$WORK/manjaro-tools" SYSCONFDIR=/etc PREFIX=/usr install_yaml
make -C "$WORK/manjaro-tools" SYSCONFDIR=/etc PREFIX=/usr install_iso

# Use the current official Forgejo endpoint directly. Older manjaro-tools
# releases still point buildiso -i at the retired gitlab.manjaro.org hostname.
# Retry transient network/server errors with increasing backoff.
rm -rf "$PROFILE_ROOT"
PROFILE_READY=0
PROFILE_REPO="https://code.manjaro.org/profiles/iso-profiles.git"
for attempt in 1 2 3 4 5 6 7 8; do
  echo "Obtendo perfis oficiais: tentativa $attempt/8"
  if git -c http.version=HTTP/1.1 clone --depth 1 --single-branch --branch v17.1 "$PROFILE_REPO" "$PROFILE_ROOT" \
      && [[ -d "$PROFILE_ROOT/shared" ]]; then
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

TARGET="$PROFILE_ROOT/manjaro/forja-$DESKTOP"
BASE_PROFILE="$PROFILE_ROOT/manjaro/mate"
rm -rf "$TARGET"

if [[ "$DESKTOP" == mate ]]; then
  mkdir -p "$TARGET"

  # Primeiro tenta usar o perfil MATE oficial, como no método da Cloud.
  # Algumas versões do iso-profiles podem não publicar mais esse perfil;
  # nesse caso, usa os componentes compartilhados oficiais do Manjaro.
  if [[ -d "$BASE_PROFILE" ]]; then
    echo "Usando perfil oficial como base: manjaro/mate"
    cp -a "$BASE_PROFILE/." "$TARGET/"
  else
    echo "Perfil manjaro/mate não existe nesta revisão; montando perfil MATE a partir de shared."
    mkdir -p "$TARGET/desktop-overlay" "$TARGET/live-overlay"
    cp "$PROFILE_ROOT/shared/Packages-Root" "$TARGET/Packages-Root"
    cp "$PROFILE_ROOT/shared/Packages-Mhwd" "$TARGET/Packages-Mhwd"
    cp "$PROFILE_ROOT/shared/Packages-Live" "$TARGET/Packages-Live"
    cp -a "$PROFILE_ROOT/shared/manjaro/live-overlay/." "$TARGET/live-overlay/"
    cat > "$TARGET/profile.conf" <<'MATE_PROFILE'
displaymanager="lightdm"
autologin="true"
nonfree_mhwd="false"
enable_systemd=('NetworkManager' 'bluetooth')
enable_systemd_live=('NetworkManager' 'bluetooth' 'manjaro-live' 'mhwd-live' 'pacman-init' 'mirrors-live')
MATE_PROFILE
  fi

  mkdir -p "$TARGET/desktop-overlay" "$TARGET/live-overlay"
  # Materializa a lista antes de anexar pacotes, sem alterar symlinks do perfil oficial.
  if [[ -L "$TARGET/Packages-Desktop" ]]; then
    cp "$(readlink -f "$TARGET/Packages-Desktop")" "$TARGET/Packages-Desktop.materialized"
    mv "$TARGET/Packages-Desktop.materialized" "$TARGET/Packages-Desktop"
  fi
  touch "$TARGET/Packages-Desktop"

  # Complementa o perfil-base com os programas e a identidade da Forja OS.
  # Não substitui a lista oficial: preserva os pacotes próprios do perfil.
  cat >> "$TARGET/Packages-Desktop" <<'MATE_PACKAGES'

# Forja OS: aplicativos completos do ambiente MATE.
mate-desktop
mate-backgrounds
mate-menus
mate-session-manager
mate-panel
mate-control-center
mate-settings-daemon
mate-polkit
mate-applets
mate-notification-daemon
mate-power-manager
mate-screensaver
mate-media
mate-system-monitor
mate-terminal
mate-calc
mate-utils
marco
caja
mozo
pluma
engrampa
atril
eom
fastfetch
vlc
htop
gparted
noto-fonts
ttf-jetbrains-mono

# Login, rede, Bluetooth e navegador.
lightdm
lightdm-slick-greeter
networkmanager
network-manager-applet
bluez
bluez-utils
blueman
firefox

# Áudio, aparência e dependências do Forja Software.
pipewire
pipewire-alsa
pipewire-pulse
wireplumber
materia-gtk-theme
bibata-cursor-theme
papirus-icon-theme
dconf
gtk3
gtk4
python
python-gobject
libayatana-appindicator
pacman-contrib
polkit
MATE_PACKAGES
fi

# Materia Dark é obrigatório em todas as ISOs e ambientes gráficos.
grep -Fxq 'materia-gtk-theme' "$TARGET/Packages-Desktop" || printf '%s\n' 'materia-gtk-theme' >> "$TARGET/Packages-Desktop"
if ! pacman_info materia-gtk-theme >/dev/null 2>&1; then
  echo "ERRO: materia-gtk-theme não está disponível nos repositórios Manjaro Stable." >&2
  exit 24
fi

# Personalização visual Forja OS: wallpaper próprio, Materia Dark, Papirus-Dark,
# Bibata, fontes Noto Sans/JetBrains Mono e LightDM estilizado.
# Materialize overlay symlinks before editing para não alterar arquivos compartilhados.
for overlay_name in desktop-overlay live-overlay; do
  overlay="$TARGET/$overlay_name"
  if [[ -L "$overlay" ]]; then
    overlay_source="$(readlink -f "$overlay")"
    rm "$overlay"
    cp -a "$overlay_source" "$overlay"
  fi
  if [[ -d "$overlay" ]]; then
    # Overlay exclusivo da sessão MATE.
      find "$overlay" -type f \( -iname '*midori*' -o -iname '*parole*' -o -iname '*ristretto*' -o -iname '*mousepad*' -o -iname '*thunar*' \) -delete
      mkdir -p "$overlay/etc/dconf/profile" "$overlay/etc/dconf/db/local.d"
      cat > "$overlay/etc/dconf/profile/user" <<'DCPROFILE'
user-db:user
system-db:local
DCPROFILE
      install -Dm644 /forja-ci/desktops/mate/forja-mate-wallpaper.svg \
        "$overlay/usr/share/backgrounds/forja-os-mate.svg"
      cat > "$overlay/etc/dconf/db/local.d/00-forja-visual" <<'DCCONF'
[org/mate/interface]
icon-theme='Papirus-Dark'
gtk-theme='Materia-dark'
font-name='Noto Sans 10'
document-font-name='Noto Sans 10'
monospace-font-name='JetBrains Mono 11'

[org/mate/background]
picture-filename='/usr/share/backgrounds/forja-os-mate.svg'
picture-options='zoom'

[org/mate/peripherals-mouse]
cursor-theme='Bibata-Modern-Ice'

[org/mate/marco/general]
theme='Materia-dark'
DCCONF
      # Fastfetch com identidade visual FORJA OS, disponível na sessão Live e instalada.
      install -Dm644 /dev/null "$overlay/etc/fastfetch/config.jsonc"
      cat > "$overlay/etc/fastfetch/config.jsonc" <<'FASTFETCH'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "/usr/share/fastfetch/forja-logo.txt",
    "padding": { "top": 1, "right": 2 }
  },
  "display": {
    "separator": "  "
  },
  "modules": [
    "host", "kernel", "uptime",
    "packages", "shell", "display", "de", "wm",
    "theme", "icons", "terminal", "cpu", "gpu", "memory",
    "break", "colors"
  ]
}
FASTFETCH
      install -Dm644 /dev/null "$overlay/usr/share/fastfetch/forja-logo.txt"
      cat > "$overlay/usr/share/fastfetch/forja-logo.txt" <<'LOGO'
FORJA OS
LOGO
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
      # Keep Papirus Dark's built-in default folder icons.
      # No papirus-folders customization package or service is required.
      rm -f "$overlay/etc/systemd/system/forja-papirus-cyan.service"
      rm -f "$overlay/etc/systemd/system/multi-user.target.wants/forja-papirus-cyan.service"
    # Cursor Bibata como padrão do sistema e de novos usuários da sessão MATE.
    mkdir -p "$overlay/usr/share/icons/default" \
             "$overlay/etc/skel/.config/gtk-3.0" \
             "$overlay/etc/skel/.config/gtk-4.0"
    cat > "$overlay/usr/share/icons/default/index.theme" <<'CURSOR'
[Icon Theme]
Name=Default
Comment=Forja default cursor
Inherits=Bibata-Modern-Ice
CURSOR
    # Tema, ícones e cursor são gravados juntos para evitar que uma etapa
    # sobrescreva as configurações produzidas pela outra.
    for settings in \
      "$overlay/etc/gtk-3.0/settings.ini" \
      "$overlay/etc/gtk-4.0/settings.ini" \
      "$overlay/etc/skel/.config/gtk-3.0/settings.ini" \
      "$overlay/etc/skel/.config/gtk-4.0/settings.ini"; do
      mkdir -p "$(dirname "$settings")"
      cat > "$settings" <<'GTK'
[Settings]
gtk-theme-name=Materia-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-font-name=Noto Sans 10
GTK
    done
    mkdir -p "$overlay/etc/systemd/system/multi-user.target.wants"
      cat > "$overlay/etc/systemd/system/forja-dconf-update.service" <<'UNIT'
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
      ln -sfn ../forja-dconf-update.service "$overlay/etc/systemd/system/multi-user.target.wants/forja-dconf-update.service"
      mkdir -p "$overlay/etc/lightdm/lightdm.conf.d"
      cat > "$overlay/etc/lightdm/lightdm.conf.d/50-forja-mate.conf" <<'LIGHTDM'
[Seat:*]
user-session=mate
greeter-session=lightdm-slick-greeter
LIGHTDM
      if [[ -f "$overlay/etc/lightdm/lightdm.conf" ]]; then
        awk -v session="mate" '
          BEGIN { in_seat=0; found=0 }
          /^\[Seat:\*\][[:space:]]*$/ {
            in_seat=1; found=1; print
            print "user-session=" session
            print "greeter-session=lightdm-slick-greeter"
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
              print "greeter-session=lightdm-slick-greeter"
            }
          }
        ' "$overlay/etc/lightdm/lightdm.conf" > "$overlay/etc/lightdm/lightdm.conf.forja"
        mv "$overlay/etc/lightdm/lightdm.conf.forja" "$overlay/etc/lightdm/lightdm.conf"
      fi
      cat > "$overlay/etc/lightdm/slick-greeter.conf" <<'GREETER'
[Greeter]
background=/usr/share/backgrounds/forja-os-mate.svg
draw-user-backgrounds=false
draw-grid=false
theme-name=Materia-dark
icon-theme-name=Papirus-Dark
cursor-theme-name=Bibata-Modern-Ice
font-name=Noto Sans 10
GREETER
  fi
done

# Papirus é fornecido pelo pacote oficial papirus-icon-theme.
# Instala a Forja Store independente, integrada diretamente ao Pacman.
if [[ "$DESKTOP" == mate ]]; then
  DESTDIR="$TARGET/desktop-overlay" bash /forja-ci/forja-pamac-pacman/install.sh
fi

# Materialize every package list in the selected profile. The MATE profile
# owns copies of the shared lists so filtering cannot modify upstream files.
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
  MATE_CORE_PACKAGES=(
    mate-session-manager mate-panel mate-control-center mate-settings-daemon
    mate-desktop mate-menus mate-polkit marco caja
    lightdm lightdm-slick-greeter firefox networkmanager network-manager-applet
    bluez bluez-utils blueman
    pipewire pipewire-alsa pipewire-pulse wireplumber
    mate-applets mate-notification-daemon mate-power-manager mate-screensaver mate-media
    mate-system-monitor mate-terminal mate-calc mate-utils mozo pluma engrampa atril eom
    gtk3 gtk4 python python-gobject libayatana-appindicator pacman-contrib polkit fastfetch bibata-cursor-theme papirus-icon-theme dconf vlc htop gparted noto-fonts ttf-jetbrains-mono
    systemd grub efibootmgr mkinitcpio calamares linux-firmware
    manjaro-release manjaro-keyring manjaro-system pacman-mirrors mhwd mhwd-db
  )
  MATE_MISSING_CORE=()
  for package in "${MATE_CORE_PACKAGES[@]}"; do
    if ! pacman_info "$package" >/dev/null 2>&1; then MATE_MISSING_CORE+=("$package"); fi
  done
  if (("${#MATE_MISSING_CORE[@]}")); then
    printf 'ERRO: componentes essenciais MATE/LightDM/rede/Bluetooth ausentes: %s\n' "${MATE_MISSING_CORE[*]}" >&2
    exit 22
  fi
  # Caja é o gerenciador de arquivos padrão e faz parte do desktop mínimo.
  if ! pacman_info caja >/dev/null 2>&1; then
    echo "ERRO: gerenciador de arquivos Caja ausente no Manjaro Stable." >&2
    exit 23
  fi
  awk '!seen[$0]++' "$TARGET/Packages-Desktop" > "$TARGET/Packages-Desktop.unique"
  mv "$TARGET/Packages-Desktop.unique" "$TARGET/Packages-Desktop"
  # O cursor configurado precisa existir na ISO; não aceitar uma configuração quebrada.
  pacman_info bibata-cursor-theme >/dev/null 2>&1 || {
    echo "ERRO: bibata-cursor-theme não está disponível nos repositórios Manjaro configurados." >&2
    exit 27
  }
  pacman_info dconf >/dev/null 2>&1 || {
    echo "ERRO: dconf não está disponível nos repositórios Manjaro configurados." >&2
    exit 28
  }
  echo "Preflight do núcleo MATE, rede e Bluetooth aprovado."
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
    if [[ -z "$package" || "$package" == KERNEL ]]; then
      printf '%s\n' "$line" >> "$filtered_list"
      continue
    fi
    case "$package" in
      # Drivers opcionais incompatíveis/dispensáveis na ISO desktop: módulo RT3562STA legado e módulos de convidado VirtualBox.
      linux[0-9]*-rt3562sta|linux[0-9]*-virtualbox-guest-modules|gtk-theme-breath|galculator-gtk2|qpdfview|gconf|gksu|appimagelauncher|hexchat|midori|pidgin|sylpheed|p7zip|ms-office-online|pulseaudio-ctl|steam-manjaro|pamac|gtk3-print-backends|splix|pyqt5-common|xdg-su|manjaro-documentation-en|papirus-folders|mlocate|gcc-libs-multilib|gcc-multilib|pkg-config|lib32-flex|lib32-mesa-demos|nvidia*|lib32-nvidia*|catalyst*|lib32-catalyst*)
        echo "Forja: pacote legado/NVIDIA removido: $package" >&2
        printf '# Forja: pacote legado removido: %s\n' "$package" >> "$filtered_list"
        continue
        ;;
    esac
    if pacman_info "$package" >/dev/null 2>&1; then
      printf '%s\n' "$line" >> "$filtered_list"
    else
      echo "Aviso: pacote ausente removido: $package (lista $resolved_list)" >&2
      printf '# Forja: pacote ausente removido: %s\n' "$package" >> "$filtered_list"
    fi
  done < "$resolved_list"
  mv "$filtered_list" "$resolved_list"
done < <(find -L "$TARGET" -type f -name 'Packages-*' -print0 | sort -zu)


# Componentes fundamentais da instalação e do ambiente selecionado não podem
# ser removidos como opcionais: a ausência deles deve parar a ISO com clareza.
BASE_CORE_PACKAGES=(systemd grub efibootmgr mkinitcpio calamares linux-firmware manjaro-release manjaro-keyring manjaro-system pacman-mirrors mhwd mhwd-db networkmanager)
DESKTOP_CORE_PACKAGES=(mate-session-manager mate-panel mate-control-center mate-settings-daemon mate-desktop mate-menus mate-polkit mate-applets mate-notification-daemon mate-power-manager mate-screensaver mate-media mate-system-monitor mate-terminal mate-calc mate-utils marco caja mozo pluma engrampa atril eom lightdm lightdm-slick-greeter firefox networkmanager network-manager-applet bluez bluez-utils blueman materia-gtk-theme papirus-icon-theme gtk3 gtk4 python python-gobject libayatana-appindicator pacman-contrib fastfetch bibata-cursor-theme dconf vlc htop gparted noto-fonts ttf-jetbrains-mono)
MISSING_CORE_PACKAGES=()
for package in "${BASE_CORE_PACKAGES[@]}" "${DESKTOP_CORE_PACKAGES[@]}"; do
  if ! pacman_info "$package" >/dev/null 2>&1; then
    MISSING_CORE_PACKAGES+=("$package")
  fi
done
if (("${#MISSING_CORE_PACKAGES[@]}")); then
  printf "ERRO: componentes essenciais ausentes para Manjaro/%s: %s\n" "$DESKTOP" "${MISSING_CORE_PACKAGES[*]}" >&2
  exit 25
fi
echo "Preflight de componentes essenciais Manjaro/$DESKTOP aprovado."

DM=lightdm
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

# Resolve entradas KERNEL-* do perfil MHWD com o kernel real selecionado.
# Drivers antigos que não existem para esse kernel são removidos antes do buildiso.
while IFS= read -r -d "" package_list; do
  resolved_list="$(readlink -f "$package_list")"
  [[ -n "$resolved_list" && -f "$resolved_list" ]] || continue
  filtered_list="$resolved_list.kernel-filtered"
  : > "$filtered_list"
  while IFS= read -r line || [[ -n "$line" ]]; do
    read -r -a fields <<< "$line"
    if [[ -z "${fields[0]:-}" || "${fields[0]}" == \#* ]]; then
      printf "%s\n" "$line" >> "$filtered_list"
      continue
    fi
    package_index=-1
    for index in "${!fields[@]}"; do
      [[ "${fields[$index]}" == \#* ]] && break
      [[ "${fields[$index]}" == \>* ]] && continue
      package_index="$index"
      break
    done
    if (( package_index >= 0 )) && [[ "${fields[$package_index]}" == KERNEL-* ]]; then
      original="${fields[$package_index]}"
      package="${KERNEL_PKG}${original#KERNEL}"
      if pacman_info "$package" >/dev/null 2>&1; then
        fields[$package_index]="$package"
        printf "%s\n" "${fields[*]}" >> "$filtered_list"
      else
        echo "Forja: driver MHWD incompatível com $KERNEL_PKG removido: $package" >&2
        printf "# Forja: driver MHWD indisponível: %s\n" "$package" >> "$filtered_list"
      fi
    else
      printf "%s\n" "$line" >> "$filtered_list"
    fi
  done < "$resolved_list"
  mv "$filtered_list" "$resolved_list"
done < <(find -L "$TARGET" -type f -name "Packages-*" -print0 | sort -zu)

if [[ "${FORJA_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  echo "PREFLIGHT_OK: Manjaro/$DESKTOP/$KERNEL ($KERNEL_PKG). ISO build intentionally skipped."
  exit 0
fi

cd "$PROFILE_ROOT"
# Resiliência de rede para downloads durante a montagem do sistema Live.
# Atualiza a lista para os 10 espelhos Manjaro mais rápidos e configura o
# libalpm para tolerar conexões lentas e repetir downloads interrompidos.
PACMAN_CONF=/etc/pacman.conf
command -v pacman-mirrors >/dev/null 2>&1 || {
  echo "ERRO: pacman-mirrors não está disponível no ambiente de compilação." >&2
  exit 42
}
echo "Atualizando espelhos Manjaro (10 mais rápidos)..."
pacman-mirrors --fasttrack 10
if ! grep -Eq '^[[:space:]]*XferCommand[[:space:]]*=' "$PACMAN_CONF"; then
  sed -i '/^\[options\]/a XferCommand = /usr/bin/curl --retry 5 --retry-all-errors --retry-delay 3 --connect-timeout 30 --max-time 600 -L -C - -f -o %o %u' "$PACMAN_CONF"
fi
if ! grep -Eq '^[[:space:]]*DisableDownloadTimeout([[:space:]]|$)' "$PACMAN_CONF"; then
  sed -i '/^\[options\]/a DisableDownloadTimeout' "$PACMAN_CONF"
fi
if grep -Eq '^[[:space:]]*ParallelDownloads[[:space:]]*=' "$PACMAN_CONF"; then
  sed -i -E 's/^[[:space:]]*ParallelDownloads[[:space:]]*=.*/ParallelDownloads = 3/' "$PACMAN_CONF"
else
  sed -i '/^\[options\]/a ParallelDownloads = 3' "$PACMAN_CONF"
fi
echo "Sincronizando bancos de pacotes após atualizar os espelhos..."
pacman -Syy --noconfirm

# Compressão SquashFS reforçada: XZ com blocos/dicionário de 1 MiB.
# O wrapper limpa somente caches temporários do sistema-alvo antes da imagem.
SQFS_WRAPPER_DIR="$WORK/squashfs-bin"
mkdir -p "$SQFS_WRAPPER_DIR"
cat > "$SQFS_WRAPPER_DIR/mksquashfs" <<'MKSQUASHFS'
#!/usr/bin/env bash
set -Eeuo pipefail
REAL_MKSQUASHFS=/usr/bin/mksquashfs
[[ -x "$REAL_MKSQUASHFS" ]] || { echo "ERRO: mksquashfs não encontrado." >&2; exit 40; }
SOURCE="${1:-}"
if [[ -d "$SOURCE" && -d "$SOURCE/var/cache/pacman/pkg" ]]; then
  find "$SOURCE/var/cache/pacman/pkg" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
  for temp_dir in "$SOURCE/var/tmp" "$SOURCE/tmp"; do
    if [[ -d "$temp_dir" ]]; then
      find "$temp_dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
    fi
  done
fi
exec "$REAL_MKSQUASHFS" "$@" -b 1M -Xdict-size 1M
MKSQUASHFS
chmod 0755 "$SQFS_WRAPPER_DIR/mksquashfs"
XZ_HELP="$("$SQFS_WRAPPER_DIR/mksquashfs" -help-comp xz 2>&1 || true)"
grep -q -- '-Xdict-size' <<< "$XZ_HELP" || {
  echo "ERRO: mksquashfs não oferece suporte aos parâmetros XZ avançados." >&2
  exit 41
}
# Usar -f para incluir o conjunto completo de pacotes do perfil Manjaro.
BUILDISO_OK=0
for attempt in 1 2 3; do
  echo "Iniciando geração do sistema Live e da ISO (tentativa $attempt/3)..."
  if PATH="$SQFS_WRAPPER_DIR:$PATH" buildiso -f -d xz -p "forja-$DESKTOP" -b stable -k "$KERNEL_PKG" -r "$CHROOTS" -t "$OUT" -v; then
    BUILDISO_OK=1
    break
  fi

  if (( attempt < 3 )); then
    echo "Aviso: buildiso falhou na tentativa $attempt. Atualizando espelhos e preparando nova tentativa..." >&2
    pacman-mirrors --fasttrack 10
    pacman -Syy --noconfirm
    sleep $((attempt * 20))
  fi
done
if (( BUILDISO_OK != 1 )); then
  echo "ERRO: geração do sistema Live/ISO falhou após 3 tentativas." >&2
  exit 43
fi

ISO="$(find "$OUT" -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"
test -n "$ISO" && test -s "$ISO" || {
  echo "ERRO: buildiso terminou sem produzir ISO."
  exit 30
}
SIZE="$(stat -c '%s' "$ISO")"
(( SIZE >= 1000000000 )) || { echo "ISO pequena/incompleta: $SIZE bytes"; exit 31; }
(cd "$(dirname "$ISO")" && sha256sum "$(basename "$ISO")" | tee "$(basename "$ISO").sha256")
printf 'ISO_FILE=%s\nISO_SIZE=%s\nDESKTOP=%s\nKERNEL=%s\nKERNEL_PACKAGE=%s\nBASE=Manjaro\nCOMPRESSION=xz\n' "$(basename "$ISO")" "$SIZE" "$DESKTOP" "$KERNEL" "$KERNEL_PKG" > "$OUT/build-info.txt"
echo "BUILD_OK: $ISO"
