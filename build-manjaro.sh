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
case "$DESKTOP" in xfce|mate|gnome) ;; *) echo "Desktop invÃ¡lido: $DESKTOP"; exit 2;; esac
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

case "$DESKTOP" in
  xfce) SOURCE="$PROFILE_ROOT/manjaro/xfce" ;;
  gnome) SOURCE="$PROFILE_ROOT/manjaro/gnome" ;;
  mate) SOURCE="" ;;
esac

TARGET="$PROFILE_ROOT/manjaro/forja-$DESKTOP"
rm -rf "$TARGET"

if [[ "$DESKTOP" == mate ]]; then
  # Perfil MATE independente: somente a estrutura compartilhada do Manjaro
  # é reutilizada. Nenhum arquivo ou configuração do perfil XFCE é copiado.
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
  cat > "$TARGET/Packages-Desktop" <<'MATE_PACKAGES'
mate-desktop
mate-menus
mate-polkit
mate-media
mate-session-manager
mate-panel
mate-control-center
mate-settings-daemon
marco
lightdm
lightdm-slick-greeter
network-manager-applet
bluez
bluez-utils
blueman
firefox
shelly
shelly-flatpak-backend
gvfs
gvfs-mtp
xdg-user-dirs
cups
system-config-printer
pipewire
pipewire-alsa
pipewire-pulse
wireplumber
papirus-icon-theme
bibata-cursor-theme
MATE_PACKAGES
else
  test -f "$SOURCE/Packages-Desktop" && test -f "$SOURCE/profile.conf" || {
    echo "ERRO: perfil-base invÃ¡lido: $SOURCE"
    exit 21
  }
  cp -a "$SOURCE" "$TARGET"
fi

# Materia Dark é obrigatório em todas as ISOs e ambientes gráficos.
grep -Fxq 'materia-gtk-theme' "$TARGET/Packages-Desktop" || printf '%s\\n' 'materia-gtk-theme' >> "$TARGET/Packages-Desktop"
if ! pacman_info materia-gtk-theme >/dev/null 2>&1; then
  echo "ERRO: materia-gtk-theme não está disponível nos repositórios Manjaro Stable." >&2
  exit 24
fi

# Shelly-ALPM is built locally and served over HTTP to buildiso.
rm -f "$TARGET/user-repos.conf"
cat > "$TARGET/user-repos.conf" <<'REPO'
[forja-shelly]
SigLevel = Optional TrustAll
Server = http://127.0.0.1:8765/$repo/$arch
REPO
if [[ "$DESKTOP" != mate ]]; then printf '\nshelly\nshelly-flatpak-backend\n' >> "$TARGET/Packages-Desktop"; fi

# Pacotes oficiais de wallpapers do Manjaro em todas as variantes Manjaro.
for wallpaper_package in manjaro-wallpapers-18.0 wallpapers-2018 wallpapers-juhraya illyria-wallpaper; do
  if ! pacman_info "$wallpaper_package" >/dev/null 2>&1; then
    echo "ERRO: pacote de wallpaper Manjaro ausente no Stable: $wallpaper_package" >&2
    exit 26
  fi
  grep -Fxq "$wallpaper_package" "$TARGET/Packages-Desktop" || printf '%s\\n' "$wallpaper_package" >> "$TARGET/Packages-Desktop"
done
# Bibata é compilado no repositório local Forja e obrigatório em todas as variantes.
grep -Fxq 'bibata-cursor-theme' "$TARGET/Packages-Desktop" || printf '%s\\n' 'bibata-cursor-theme' >> "$TARGET/Packages-Desktop"
if ! pacman --config "$PACMAN_CONF" -Si bibata-cursor-theme >/dev/null 2>&1; then
  echo "ERRO: Bibata não está disponível no repositório local Forja." >&2
  exit 27
fi

# Materialize overlay symlinks before editing so no shared profile outside this
# custom profile is changed. Remove desktop-specific defaults for MATE and set
# its LightDM session without inheriting another desktop profile.
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
      find "$overlay" -depth \( -iname '*xfce*' -o -iname '*sonar*' \) -exec rm -rf {} +
      find "$overlay" -type f \( -iname '*midori*' -o -iname '*parole*' -o -iname '*ristretto*' -o -iname '*mousepad*' -o -iname '*thunar*' \) -delete
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
    # Cursor Bibata como padrão do sistema e de novos usuários em todos os desktops.
    mkdir -p "$overlay/usr/share/icons/default" \
             "$overlay/etc/skel/.config/gtk-3.0" \
             "$overlay/etc/skel/.config/gtk-4.0"
    cat > "$overlay/usr/share/icons/default/index.theme" <<'CURSOR'
[Icon Theme]
Name=Default
Comment=Forja default cursor
Inherits=Bibata-Modern-Ice
CURSOR
    for settings in \
      "$overlay/etc/gtk-3.0/settings.ini" \
      "$overlay/etc/gtk-4.0/settings.ini" \
      "$overlay/etc/skel/.config/gtk-3.0/settings.ini" \
      "$overlay/etc/skel/.config/gtk-4.0/settings.ini"; do
      mkdir -p "$(dirname "$settings")"
      if [[ -f "$settings" ]]; then
        if grep -q '^gtk-cursor-theme-name=' "$settings"; then
          sed -i 's/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Bibata-Modern-Ice/' "$settings"
        else
          printf '\ngtk-cursor-theme-name=Bibata-Modern-Ice\n' >> "$settings"
        fi
      else
        cat > "$settings" <<'GTK'
[Settings]
gtk-theme-name=Materia-dark
gtk-cursor-theme-name=Bibata-Modern-Ice
GTK
      fi
    done
    # Tema GTK Materia Dark como padrão global e para novos usuários.
    mkdir -p "$overlay/etc/gtk-3.0" "$overlay/etc/gtk-4.0" \
             "$overlay/etc/skel/.config/gtk-3.0" \
             "$overlay/etc/skel/.config/gtk-4.0"
    for settings in \
      "$overlay/etc/gtk-3.0/settings.ini" \
      "$overlay/etc/gtk-4.0/settings.ini" \
      "$overlay/etc/skel/.config/gtk-3.0/settings.ini" \
      "$overlay/etc/skel/.config/gtk-4.0/settings.ini"; do
      cat > "$settings" <<'GTK'
[Settings]
gtk-theme-name=Materia-dark
GTK
    done
    if [[ "$DESKTOP" == gnome ]]; then
      mkdir -p "$overlay/etc/dconf/profile" "$overlay/etc/dconf/db/local.d"
      cat > "$overlay/etc/dconf/profile/user" <<'DCPROFILE'
user-db:user
system-db:local
DCPROFILE
      cat > "$overlay/etc/dconf/db/local.d/00-forja-theme" <<'DCCONF'
[org/gnome/desktop/interface]
gtk-theme='Materia-dark'
color-scheme='prefer-dark'
DCCONF
    elif [[ "$DESKTOP" == xfce ]]; then
      mkdir -p "$overlay/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
      cat > "$overlay/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" <<'XFCONF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Materia-dark"/>
  </property>
</channel>
XFCONF
    fi
    if [[ "$DESKTOP" == gnome || "$DESKTOP" == mate ]]; then
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
      ln -sfn /etc/systemd/system/forja-dconf-update.service "$overlay/etc/systemd/system/multi-user.target.wants/forja-dconf-update.service"
    fi
    # XFCE e MATE usam LightDM. GNOME e KDE mantêm seus próprios
    # gerenciadores (GDM/Plasma Login Manager) e não recebem configuração LightDM.
    if [[ "$DESKTOP" == mate || "$DESKTOP" == xfce ]]; then
      SESSION="$DESKTOP"
      mkdir -p "$overlay/etc/lightdm/lightdm.conf.d"
      cat > "$overlay/etc/lightdm/lightdm.conf.d/50-forja-$DESKTOP.conf" <<LIGHTDM
[Seat:*]
user-session=$SESSION
greeter-session=lightdm-slick-greeter
LIGHTDM
      if [[ -f "$overlay/etc/lightdm/lightdm.conf" ]]; then
        awk -v session="$SESSION" '
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
      if [[ -f "$overlay/etc/lightdm/lightdm-slick-greeter.conf" ]]; then
        sed -i -E 's/^icon-theme-name[[:space:]]*=.*/icon-theme-name = Adwaita/; s/^cursor-theme-name[[:space:]]*=.*/cursor-theme-name = Adwaita/' "$overlay/etc/lightdm/lightdm-slick-greeter.conf"
      fi
    fi
  fi
done

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
    mate-desktop mate-menus mate-polkit mate-media marco lightdm lightdm-slick-greeter firefox networkmanager
    network-manager-applet bluez bluez-utils blueman
    systemd grub efibootmgr mkinitcpio calamares linux-firmware
    manjaro-release manjaro-keyring manjaro-system pacman-mirrors mhwd mhwd-db
  )
  MATE_MISSING_CORE=()
  for package in "${MATE_CORE_PACKAGES[@]}"; do
    if ! pacman_info "$package" >/dev/null 2>&1; then MATE_MISSING_CORE+=("$package"); fi
  done
  if (("${#MATE_MISSING_CORE[@]}")); then
    printf 'ERRO: componentes essenciais MATE/LightDM/rede/Bluetooth ausentes: %s\\n' "${MATE_MISSING_CORE[*]}" >&2
    exit 22
  fi
  # Conjunto completo dos grupos oficiais mate e mate-extra, listado por
  # pacote individual para permitir validação real com pacman -Si.
  MATE_REQUIRED_PACKAGES=(
    caja marco mate-backgrounds mate-control-center mate-desktop
    mate-icon-theme mate-menus mate-notification-daemon mate-panel
    mate-polkit mate-session-manager mate-settings-daemon mate-themes
    mate-user-guide atril engrampa eom mate-applets mate-calc mate-media
    mate-power-manager mate-screensaver mate-system-monitor mate-terminal
    mate-utils mozo pluma
  )
  MATE_MISSING_PACKAGES=()
  for package in "${MATE_REQUIRED_PACKAGES[@]}"; do
    if pacman_info "$package" >/dev/null 2>&1; then
      printf '%s\\n' "$package" >> "$TARGET/Packages-Desktop"
    else
      MATE_MISSING_PACKAGES+=("$package")
    fi
  done
  if (("${#MATE_MISSING_PACKAGES[@]}")); then
    printf 'ERRO: pacotes obrigatórios do MATE ausentes no Manjaro Stable: %s\\n' "${MATE_MISSING_PACKAGES[*]}" >&2
    exit 23
  fi
  awk '!seen[$0]++' "$TARGET/Packages-Desktop" > "$TARGET/Packages-Desktop.unique"
  mv "$TARGET/Packages-Desktop.unique" "$TARGET/Packages-Desktop"
  for package in papirus-icon-theme bibata-cursor-theme; do
    if ! pacman_info "$package" >/dev/null 2>&1; then
      sed -i "/^$package$/d" "$TARGET/Packages-Desktop"
      echo "Aviso: tema opcional indisponível, removido: $package" >&2
    fi
  done
  if ! pacman --config "$PACMAN_CONF" -Si bibata-cursor-theme >/dev/null 2>&1; then
    sed -i '/^bibata-cursor-theme$/d' "$TARGET/Packages-Desktop"
  fi
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
    if [[ -z "$package" || "$package" == KERNEL || "$package" == KERNEL-* ]]; then
      printf '%s\\n' "$line" >> "$filtered_list"
      continue
    fi
    case "$package" in
      gtk-theme-breath|galculator-gtk2|qpdfview|gconf|gksu|gnome-icon-theme|gnome-themes-standard|appimagelauncher|hexchat|midori|pidgin|sylpheed|p7zip|ms-office-online|pulseaudio-ctl|steam-manjaro|pamac|gtk3-print-backends|splix|pyqt5-common|gtk-xfce-engine|xf86-input-keyboard|xf86-input-mouse|xdg-su|manjaro-documentation-en|mlocate|gcc-libs-multilib|gcc-multilib|pkg-config|lib32-flex|lib32-mesa-demos|xfce4*|xfconf|exo|garcon|thunar|tumbler|menulibre|mugshot|ristretto|mousepad|parole|orage|catfish|xfburn|xfdesktop*|xfwm4*|galculator|evince|manjaro-xfce-settings|manjaro-xfce-minimal-settings|nvidia*|lib32-nvidia*|catalyst*|lib32-catalyst*)
        echo "Forja: pacote legado/XFCE/NVIDIA removido: $package" >&2
        printf '# Forja: pacote legado removido: %s\\n' "$package" >> "$filtered_list"
        continue
        ;;
    esac
    if pacman_info "$package" >/dev/null 2>&1; then
      printf '%s\\n' "$line" >> "$filtered_list"
    else
      echo "Aviso: pacote ausente removido: $package (lista $resolved_list)" >&2
      printf '# Forja: pacote ausente removido: %s\\n' "$package" >> "$filtered_list"
    fi
  done < "$resolved_list"
  mv "$filtered_list" "$resolved_list"
done < <(find -L "$TARGET" -type f -name 'Packages-*' -print0 | sort -zu)


# Componentes fundamentais da instalação e do ambiente selecionado não podem
# ser removidos como opcionais: a ausência deles deve parar a ISO com clareza.
BASE_CORE_PACKAGES=(systemd grub efibootmgr mkinitcpio calamares linux-firmware manjaro-release manjaro-keyring manjaro-system pacman-mirrors mhwd mhwd-db networkmanager)
case "$DESKTOP" in
  xfce) DESKTOP_CORE_PACKAGES=(xfce4-panel xfce4-session xfce4-settings xfdesktop xfwm4 lightdm lightdm-slick-greeter materia-gtk-theme) ;;
  gnome) DESKTOP_CORE_PACKAGES=(gnome-shell gdm gnome-control-center nautilus materia-gtk-theme) ;;
  mate) DESKTOP_CORE_PACKAGES=(mate-session-manager mate-panel mate-control-center mate-settings-daemon mate-desktop mate-menus mate-polkit mate-media marco lightdm lightdm-slick-greeter firefox materia-gtk-theme) ;;
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
