#!/usr/bin/env bash
set -Eeuo pipefail
export LANG=C
# Evita chamadas ao systemd do host durante hooks de pacotes executados em chroot.
# O systemd ainda é instalado normalmente e seus serviços são habilitados no perfil ISO.
export SYSTEMD_OFFLINE=1
DESKTOP="${FORJA_DESKTOP:-xfce}"
case "$DESKTOP" in xfce) ;; *) echo "Esta edição da Forja OS oferece somente XFCE; valor recebido: $DESKTOP." >&2; exit 2;; esac
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

# DockbarX é distribuído assinado pelo repositório BigCommunity community-extra.
if ! grep -q "^\[community-extra\]" /etc/pacman.conf; then
  printf '\n[community-extra]\nSigLevel = PackageRequired\nServer = https://repo.communitybig.org/$repo/$arch\n\n[community-stable]\nSigLevel = PackageRequired\nServer = https://repo.communitybig.org/$repo/$arch\n' >> /etc/pacman.conf
fi
pacman -Sy --noconfirm
BUILD_TOOLS=(git base-devel make python python-yaml python-jinja python-requests curl jq libxslt docbook2x docbook-xsl squashfs-tools dosfstools libisoburn mtools grub efibootmgr cdrtools rsync wget gawk mhwd pkgconf libxml2)
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

# Pacotes locais da Forja: Shelly binária e integração Plymouth do rootfs.
SHELLY_BUILD_DIR="$WORK/shelly-build"
SHELLY_REPO_DIR="$WORK/shelly-repo"
FORJA_LOCAL_REPO_MARKER="# FORJA-LOCAL-REPO"
cleanup_shelly_repo() {
  if grep -qF "$FORJA_LOCAL_REPO_MARKER" /etc/pacman.conf; then
    sed -i '/# FORJA-LOCAL-REPO/,+3d' /etc/pacman.conf
  fi
}
trap cleanup_shelly_repo EXIT
rm -rf "$SHELLY_BUILD_DIR" "$SHELLY_REPO_DIR"
mkdir -p "$SHELLY_BUILD_DIR" "$SHELLY_REPO_DIR"
install -m 0644 /forja-ci/desktops/xfce/shelly/PKGBUILD-bin "$SHELLY_BUILD_DIR/PKGBUILD"
for source_file in shellybuild.conf com.shellyorg.shelly.desktop com.shellyorg.shelly-notifications.desktop shelly-flatpak-integrate; do
  install -m 0644 "/forja-ci/desktops/xfce/shelly/$source_file" "$SHELLY_BUILD_DIR/$source_file"
done
pacman -S --needed --noconfirm go-md2man binutils
if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "ERRO: o pacote binário oficial Shelly desta receita é x86_64; arquitetura detectada: $(uname -m)." >&2
  exit 26
fi
id shelly-builder >/dev/null 2>&1 || useradd --system --create-home --home-dir "$WORK/shelly-builder" --shell /usr/bin/nologin shelly-builder
chown -R shelly-builder:shelly-builder "$SHELLY_BUILD_DIR"
runuser -u shelly-builder -- bash -lc "cd '$SHELLY_BUILD_DIR' && makepkg --nodeps --noconfirm --cleanbuild --force"
find "$SHELLY_BUILD_DIR" -maxdepth 1 -type f -name 'shelly-*.pkg.tar.*' -exec cp -f {} "$SHELLY_REPO_DIR/" \;
find "$SHELLY_REPO_DIR" -maxdepth 1 -type f -name 'shelly-bin-*.pkg.tar.*' | grep -q . || {
  echo "ERRO: makepkg não gerou o pacote shelly-bin." >&2
  exit 27
}
repo-add "$SHELLY_REPO_DIR/forja-local.db.tar.gz" "$SHELLY_REPO_DIR"/*.pkg.tar.zst
printf '\n%s\n[forja-local]\nSigLevel = Optional TrustAll\nServer = file://%s\n' "$FORJA_LOCAL_REPO_MARKER" "$SHELLY_REPO_DIR" >> /etc/pacman.conf
pacman -Sy --noconfirm

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

TARGET="$PROFILE_ROOT/manjaro/forja-xfce"
rm -rf "$TARGET"
mkdir -p "$TARGET/desktop-overlay" "$TARGET/live-overlay"

# Perfil gráfico independente: usa somente a infraestrutura compartilhada
# necessária para gerar uma ISO Manjaro. Nunca importa manjaro/xfce.
for shared_list in Packages-Root Packages-Mhwd Packages-Live; do
  test -f "$PROFILE_ROOT/shared/$shared_list" || {
    echo "ERRO: componente técnico compartilhado ausente: $shared_list" >&2
    exit 21
  }
  install -m 0644 "$PROFILE_ROOT/shared/$shared_list" "$TARGET/$shared_list"
done

# O sistema instalado precisa do gerador oficial de mirrorlist no primeiro boot.
grep -Fxq pacman-mirrors "$TARGET/Packages-Root" || printf '%s\n' pacman-mirrors >> "$TARGET/Packages-Root"
# Plymouth fica no rootfs para o hook entrar no initramfs antes da montagem da ISO.
grep -Fxq plymouth "$TARGET/Packages-Root" || printf '%s\n' plymouth >> "$TARGET/Packages-Root"
# Btrfs é o formato padrão da instalação e precisa estar disponível no Live/Calamares.
grep -Fxq btrfs-progs "$TARGET/Packages-Root" || printf '%s\n' btrfs-progs >> "$TARGET/Packages-Root"

# A sessão Live usa apenas os mecanismos de inicialização da base.
# Todas as configurações XFCE do overlay genérico são descartadas e recriadas
# pela Forja antes da criação da imagem.
if [[ -d "$PROFILE_ROOT/shared/manjaro/live-overlay" ]]; then
  cp -a "$PROFILE_ROOT/shared/manjaro/live-overlay/." "$TARGET/live-overlay/"
fi
rm -rf "$TARGET/live-overlay/etc/skel/.config/xfce4" \
       "$TARGET/live-overlay/etc/xdg/xfce4"
rm -f "$TARGET/live-overlay/etc/xdg/autostart/manjaro-hello.desktop" \
      "$TARGET/live-overlay/etc/xdg/autostart/manjaro-settings-manager.desktop" \
      "$TARGET/live-overlay/etc/xdg/autostart/xfce4-tour.desktop"

# Perfil de sessão e pacotes mantido no próprio repositório Forja.
install -m 0644 /forja-ci/desktops/xfce/profile.conf "$TARGET/profile.conf"
install -m 0644 /forja-ci/desktops/xfce/packages.manjaro "$TARGET/Packages-Desktop"


# A edição única recebe o tema GTK escuro que realmente configura.
REQUIRED_GTK_THEME="adw-gtk-theme"
grep -Fxq "$REQUIRED_GTK_THEME" "$TARGET/Packages-Desktop" || printf '%s\n' "$REQUIRED_GTK_THEME" >> "$TARGET/Packages-Desktop"
if ! pacman_info "$REQUIRED_GTK_THEME" >/dev/null 2>&1; then
  echo "ERRO: $REQUIRED_GTK_THEME não está disponível nos repositórios Manjaro Stable." >&2
  exit 24
fi

# Visual XFCE Forja OS: Adw GTK escuro, decoração Materia Dark, Papirus cinza,
# Bibata escuro, fontes Noto Sans/JetBrains Mono e LightDM estilizado.
# Materialize overlay symlinks before editing para não alterar arquivos compartilhados.
for overlay_name in desktop-overlay live-overlay; do
  overlay="$TARGET/$overlay_name"
  if [[ -L "$overlay" ]]; then
    overlay_source="$(readlink -f "$overlay")"
    rm "$overlay"
    cp -a "$overlay_source" "$overlay"
  fi
  if [[ -d "$overlay" ]]; then
    # Overlay único da sessão XFCE.
      # Overlay da sessão XFCE: tema escuro, ícones neutros e configuração própria.
      DESTDIR="$overlay" bash /forja-ci/desktops/xfce/install-branding.sh
      mkdir -p "$overlay/usr/share/backgrounds" "$overlay/usr/share/icons/default" \
        "$overlay/etc/gtk-3.0" "$overlay/etc/gtk-4.0" \
        "$overlay/etc/skel/.config/gtk-3.0" "$overlay/etc/skel/.config/gtk-4.0" \
        "$overlay/etc/lightdm/lightdm.conf.d"
      # Keep the desktop intentionally plain: remove upstream XFCE/Manjaro artwork.
      rm -rf "$overlay/usr/share/backgrounds/xfce" "$overlay/usr/share/xfce4/backdrops"
      # Recolor Papirus-Dark folders as root before the graphical session starts.
      # Running papirus-folders from a user autostart would require sudo and fail without a terminal.
      mkdir -p "$overlay/etc/systemd/system/multi-user.target.wants"
      cat > "$overlay/etc/systemd/system/forja-papirus-folders.service" <<'UNIT'
[Unit]
Description=Apply neutral gray Papirus folder icons for Forja OS
Before=display-manager.service
ConditionPathExists=/usr/bin/papirus-folders

[Service]
Type=oneshot
ExecStart=/usr/bin/papirus-folders -C grey --theme Papirus-Dark
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
      ln -sfn ../forja-papirus-folders.service "$overlay/etc/systemd/system/multi-user.target.wants/forja-papirus-folders.service"
      cat > "$overlay/usr/share/icons/default/index.theme" <<'CURSOR'
[Icon Theme]
Name=Default
Comment=Forja OS default cursor
Inherits=Bibata-Modern-Classic
CURSOR
      for settings in \
        "$overlay/etc/gtk-3.0/settings.ini" \
        "$overlay/etc/gtk-4.0/settings.ini" \
        "$overlay/etc/skel/.config/gtk-3.0/settings.ini" \
        "$overlay/etc/skel/.config/gtk-4.0/settings.ini"; do
        cat > "$settings" <<'GTK'
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-font-name=Noto Sans 10
GTK
      done
      cat > "$overlay/etc/lightdm/lightdm.conf.d/50-forja-xfce.conf" <<'LIGHTDM'
[Seat:*]
user-session=xfce
greeter-session=lightdm-gtk-greeter
LIGHTDM
      cat > "$overlay/etc/lightdm/lightdm-gtk-greeter.conf" <<'GREETER'
[greeter]
background=/usr/share/backgrounds/forja-black.svg
user-background=false
theme-name=adw-gtk3-dark
icon-theme-name=Papirus-Dark
cursor-theme-name=Bibata-Modern-Classic
font-name=Noto Sans 10
GREETER
      # Mantém o navegador como padrão também na sessão Live e nos novos usuários.
      mkdir -p "$overlay/etc/xdg" "$overlay/etc/skel/.config"
      cat > "$overlay/etc/xdg/mimeapps.list" <<'MIMEAPPS'
[Default Applications]
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
text/html=firefox.desktop
application/xhtml+xml=firefox.desktop
MIMEAPPS
      install -Dm644 "$overlay/etc/xdg/mimeapps.list" "$overlay/etc/skel/.config/mimeapps.list"
      mkdir -p "$overlay/usr/share/fastfetch" "$overlay/etc/fastfetch"
      cat > "$overlay/usr/share/fastfetch/forja-logo.txt" <<'LOGO'
FORJA OS
LOGO
      cat > "$overlay/etc/fastfetch/config.jsonc" <<'FASTFETCH'
{
  "logo": { "type": "file", "source": "/usr/share/fastfetch/forja-logo.txt" },
  "display": { "separator": "  " },
  "modules": ["host", "kernel", "uptime", "packages", "shell", "display", "de", "wm", "theme", "icons", "terminal", "cpu", "gpu", "memory"]
}
FASTFETCH
  fi
done

# Papirus é fornecido pelo pacote oficial papirus-icon-theme.

# Materialize every package-list symlink before editing. Never rewrite
# shared Manjaro profile files through a symlink from the Forja profile.
while IFS= read -r -d '' package_list; do
  materialized="${package_list}.forja-materialized"
  cp -L -- "$package_list" "$materialized"
  chmod 0644 "$materialized"
  mv -f -- "$materialized" "$package_list"
done < <(find "$TARGET" -type l -name 'Packages-*' -print0)

# Package-list edits below operate only on regular files owned by this profile.

# Full package preflight runs after the desktop-specific list is finalized.

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
      linux[0-9]*-rt3562sta|linux[0-9]*-virtualbox-guest-modules|manjaro-hello|manjaro-settings-manager|manjaro-settings-manager-notifier|xfce4-goodies|xfce4-artwork|xfce4-wallpapers|manjaro-wallpapers|manjaro-wallpapers-18.0|manjaro-wallpapers-by-lunix-xfce|wallpapers-2018|wallpapers-juhraya|illyria-wallpaper|manjaro-xfce-settings|manjaro-xfce-minimal-settings|gtk-theme-breath|galculator-gtk2|qpdfview|gconf|gksu|appimagelauncher|hexchat|midori|pidgin|sylpheed|p7zip|ms-office-online|pulseaudio-ctl|steam-manjaro|pamac|pamac-cli|pamac-gtk|libpamac|libpamac-flatpak-plugin|gtk3-print-backends|splix|pyqt5-common|xdg-su|manjaro-documentation-en|mlocate|gcc-libs-multilib|gcc-multilib|pkg-config|lib32-flex|lib32-mesa-demos|nvidia*|lib32-nvidia*|catalyst*|lib32-catalyst*)
        echo "Forja: pacote legado/NVIDIA removido: $package" >&2
        printf '# Forja: pacote legado removido: %s\n' "$package" >> "$filtered_list"
        continue
        ;;
    esac
    if pacman_info "$package" >/dev/null 2>&1 || [[ -n "$(pacman -Sgq "$package" 2>/dev/null)" ]]; then
      printf '%s\n' "$line" >> "$filtered_list"
    else
      echo "Aviso: pacote ausente removido: $package (lista $resolved_list)" >&2
      printf '# Forja: pacote ausente removido: %s\n' "$package" >> "$filtered_list"
    fi
  done < "$resolved_list"
  mv "$filtered_list" "$resolved_list"
done < <(find "$TARGET" -type f -name 'Packages-*' -print0 | sort -zu)


# Componentes fundamentais da instalação e do ambiente selecionado não podem
# ser removidos como opcionais: a ausência deles deve parar a ISO com clareza.
BASE_CORE_PACKAGES=(systemd grub efibootmgr mkinitcpio plymouth calamares btrfs-progs linux-firmware manjaro-release manjaro-keyring manjaro-system pacman-mirrors mhwd mhwd-db networkmanager)
DESKTOP_CORE_PACKAGES=(libnotify shelly-bin shelly-flatpak-backend-bin xfce4-session xfce4-panel xfce4-settings xfce4-appfinder xfdesktop xfwm4 xfconf exo garcon thunar thunar-volman tumbler xfce4-terminal xfce4-taskmanager xfce4-power-manager xfce4-notifyd xfce4-whiskermenu-plugin dockbarx xfce4-dockbarx-plugin xfce4-panel-profiles xfce4-pulseaudio-plugin xfce4-clipman-plugin lightdm lightdm-gtk-greeter firefox networkmanager network-manager-applet bluez bluez-utils blueman adw-gtk-theme materia-gtk-theme papirus-icon-theme papirus-folders bibata-cursor-theme gtk3 gsettings-desktop-schemas python python-gobject pacman-contrib polkit polkit-gnome flatpak yay git base-devel appstream archlinux-appstream-data)
MISSING_CORE_PACKAGES=()
for package in "${BASE_CORE_PACKAGES[@]}" "${DESKTOP_CORE_PACKAGES[@]}"; do
  if ! pacman_info "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" >/dev/null 2>&1; then
    MISSING_CORE_PACKAGES+=("$package")
  fi
done
if (("${#MISSING_CORE_PACKAGES[@]}")); then
  printf "ERRO: componentes essenciais ausentes para Manjaro/%s: %s\n" "$DESKTOP" "${MISSING_CORE_PACKAGES[*]}" >&2
  exit 25
fi
echo "Preflight de componentes essenciais da Forja XFCE (base Manjaro) aprovado."

# Arquivos de boot são aplicados no rootfs do perfil antes da montagem do sistema.
# Isso permite que o hook do mkinitcpio esteja presente quando o initramfs do
# kernel for gerado durante a instalação dos pacotes.
mkdir -p "$TARGET/rootfs"
# Configurar Plymouth no rootfs real após a instalação dos pacotes e antes
# da compactação. Assim mkinitcpio gera o initramfs já com tema e hook Forja.

# Calamares: Btrfs pré-selecionado para novas instalações, mantendo ext4/f2fs disponíveis.
install -Dm644 /forja-ci/desktops/xfce/calamares/partition.conf "$TARGET/rootfs/etc/calamares/modules/partition.conf"
install -Dm644 /forja-ci/desktops/xfce/calamares/mount.conf "$TARGET/rootfs/etc/calamares/modules/mount.conf"

# Repositórios do sistema instalado: pacman usa exclusivamente a mirrorlist
# gerada pelo utilitário oficial pacman-mirrors do Manjaro.
install -Dm644 /dev/stdin "$TARGET/rootfs/etc/pacman.conf" <<'PACMANCONF'
[options]
HoldPkg = pacman glibc manjaro-system
Architecture = auto
Color
CheckSpace
ParallelDownloads = 5
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
SigLevel = PackageRequired
Include = /etc/pacman.d/mirrorlist

[extra]
SigLevel = PackageRequired
Include = /etc/pacman.d/mirrorlist

[community-extra]
SigLevel = PackageRequired
Server = https://repo.communitybig.org/$repo/$arch

[community-stable]
SigLevel = PackageRequired
Server = https://repo.communitybig.org/$repo/$arch
PACMANCONF

install -Dm644 /dev/stdin "$TARGET/rootfs/etc/pacman-mirrors.conf" <<'MIRRORSCONF'
Branch = stable
Method = rank
Protocols = https
MIRRORSCONF

install -Dm644 /dev/stdin "$TARGET/rootfs/etc/pacman.d/mirrorlist" <<'MIRRORLIST'
## Mirrorlist gerada no primeiro boot pelo forja-manjaro-mirrors.service.
## Não adicione servidores de outras distribuições neste arquivo.
MIRRORLIST

install -Dm644 /dev/stdin "$TARGET/rootfs/etc/systemd/system/forja-manjaro-mirrors.service" <<'MIRRORSERVICE'
[Unit]
Description=Generate current official Manjaro mirror list for Forja OS
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0
ConditionPathExists=/usr/bin/pacman-mirrors

[Service]
Type=oneshot
ExecStart=/usr/bin/pacman-mirrors --fasttrack 10
TimeoutStartSec=10min
Restart=on-failure
RestartSec=30
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
MIRRORSERVICE
mkdir -p "$TARGET/rootfs/etc/systemd/system/multi-user.target.wants"
ln -sfn ../forja-manjaro-mirrors.service "$TARGET/rootfs/etc/systemd/system/multi-user.target.wants/forja-manjaro-mirrors.service"

DM=lightdm
if grep -q '^#\?displaymanager=' "$TARGET/profile.conf"; then
  sed -i "s/^#\?displaymanager=.*/displaymanager=\"$DM\"/" "$TARGET/profile.conf"
else
  printf '\ndisplaymanager="%s"\n' "$DM" >> "$TARGET/profile.conf"
fi

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
done < <(find "$TARGET" -type f -name "Packages-*" -print0 | sort -zu)

if [[ "${FORJA_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  echo "PREFLIGHT_OK: Forja XFCE / base Manjaro / $KERNEL ($KERNEL_PKG). ISO build intentionally skipped."
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
echo "Definindo branch Manjaro Stable e priorizando HTTPS..."
pacman-mirrors --api --set-branch stable --protocol https
echo "Atualizando espelhos Manjaro (10 mais rápidos)..."
pacman-mirrors --fasttrack 10
MIRRORLIST=/etc/pacman.d/mirrorlist
if ! grep -Fqx '[core]' "$PACMAN_CONF" || ! grep -Fqx '[extra]' "$PACMAN_CONF"; then
  echo "ERRO: repositórios core/extra do Manjaro não estão habilitados no pacman.conf." >&2
  exit 42
fi
if [[ "$(grep -Fc 'Include = /etc/pacman.d/mirrorlist' "$PACMAN_CONF")" -lt 2 ]]; then
  echo "ERRO: pacman.conf não está direcionando core/extra para a mirrorlist Manjaro." >&2
  exit 42
fi
if ! grep -Eq '^[[:space:]]*Server[[:space:]]*=[[:space:]]*https?://' "$MIRRORLIST"; then
  echo "ERRO: pacman-mirrors não gerou servidores válidos em $MIRRORLIST." >&2
  exit 42
fi
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
# Usar -f para incluir o conjunto completo do perfil próprio Forja XFCE.
# Etapa 1: construir as camadas do sistema sem compactar a ISO.
# O Plymouth é configurado no rootfs real após a instalação dos pacotes e antes
# da geração final da imagem initramfs.
BUILD_IMAGES_OK=0
for attempt in 1 2 3; do
  echo "Preparando as camadas do sistema (tentativa $attempt/3)..."
  if buildiso -f -x -d xz -p "forja-$DESKTOP" -b stable -k "$KERNEL_PKG" -r "$CHROOTS" -t "$OUT" -v; then
    BUILD_IMAGES_OK=1
    break
  fi
  if (( attempt < 3 )); then
    echo "Aviso: preparação das camadas falhou; atualizando espelhos e tentando novamente." >&2
    pacman-mirrors --fasttrack 10
    pacman -Syy --noconfirm
    sleep $((attempt * 20))
  fi
done
if (( BUILD_IMAGES_OK != 1 )); then
  echo "ERRO: preparação das camadas falhou após 3 tentativas." >&2
  exit 43
fi

ROOTFS_CHROOT="$(find "$CHROOTS" -type d -name rootfs -print -quit)"
[[ -n "$ROOTFS_CHROOT" && -d "$ROOTFS_CHROOT" ]] || {
  echo "ERRO: buildiso não deixou o rootfs de trabalho disponível para configurar o Plymouth." >&2
  exit 44
}

# Ferdium é incluído como aplicativo instalado no sistema, não apenas listado na Shelly.
# O Flatpak é instalado em escopo system dentro do rootfs para aparecer no menu XFCE.
echo "Instalando Ferdium no rootfs da Forja OS..."
manjaro-chroot "$ROOTFS_CHROOT" flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
manjaro-chroot "$ROOTFS_CHROOT" flatpak install --system --noninteractive --assumeyes flathub org.ferdium.Ferdium
manjaro-chroot "$ROOTFS_CHROOT" flatpak info --system org.ferdium.Ferdium >/dev/null || {
  echo "ERRO: Ferdium não foi encontrado após a instalação no rootfs." >&2
  exit 48
}
test -s "$ROOTFS_CHROOT/var/lib/flatpak/exports/share/applications/org.ferdium.Ferdium.desktop" || {
  echo "ERRO: o atalho do Ferdium não foi exportado para o menu XFCE." >&2
  exit 49
}
install -Dm644 /forja-ci/desktops/xfce/plymouth/forja-mkinitcpio.conf "$ROOTFS_CHROOT/tmp/forja-mkinitcpio.conf"
install -Dm755 /forja-ci/desktops/xfce/plymouth/apply-mkinitcpio.sh "$ROOTFS_CHROOT/tmp/forja-apply-mkinitcpio.sh"
# Acrescenta os parâmetros silenciosos ao GRUB existente sem substituir
# as demais opções padrão fornecidas pelo Manjaro.
source /forja-ci/desktops/xfce/plymouth/forja-grub
GRUB_DEFAULT_FILE="$ROOTFS_CHROOT/etc/default/grub"
[[ -s "$GRUB_DEFAULT_FILE" ]] || {
  echo "ERRO: configuração padrão do GRUB ausente no rootfs." >&2
  exit 47
}
GRUB_EXISTING_ARGS="$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"$/\1/p' "$GRUB_DEFAULT_FILE" | head -n1)"
for boot_arg in $GRUB_CMDLINE_LINUX_DEFAULT; do
  case " $GRUB_EXISTING_ARGS " in
    *" $boot_arg "*) ;;
    *) GRUB_EXISTING_ARGS="${GRUB_EXISTING_ARGS:+$GRUB_EXISTING_ARGS }$boot_arg" ;;
  esac
done
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_DEFAULT_FILE"; then
  sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_EXISTING_ARGS\"|" "$GRUB_DEFAULT_FILE"
else
  printf 'GRUB_CMDLINE_LINUX_DEFAULT="%s"\n' "$GRUB_EXISTING_ARGS" >> "$GRUB_DEFAULT_FILE"
fi
install -Dm644 /forja-ci/desktops/xfce/plymouth/plymouthd.conf "$ROOTFS_CHROOT/etc/plymouth/plymouthd.conf"
install -Dm644 /forja-ci/desktops/xfce/plymouth/forja.plymouth "$ROOTFS_CHROOT/usr/share/plymouth/themes/forja/forja.plymouth"
install -Dm644 /forja-ci/desktops/xfce/plymouth/forja.script "$ROOTFS_CHROOT/usr/share/plymouth/themes/forja/forja.script"
command -v manjaro-chroot >/dev/null 2>&1 || {
  echo "ERRO: manjaro-chroot não está disponível para regenerar o initramfs com Plymouth." >&2
  exit 45
}
echo "Aplicando o hook Plymouth à configuração nativa do mkinitcpio..."
manjaro-chroot "$ROOTFS_CHROOT" bash /tmp/forja-apply-mkinitcpio.sh
echo "Regenerando initramfs com o hook e o tema Plymouth da Forja..."
manjaro-chroot "$ROOTFS_CHROOT" mkinitcpio -P
rm -f "$ROOTFS_CHROOT/tmp/forja-apply-mkinitcpio.sh"

# Etapa 2: compactar as camadas já configuradas e gerar a ISO.
BUILDISO_OK=0
for attempt in 1 2 3; do
  echo "Gerando a ISO (tentativa $attempt/3)..."
  if PATH="$SQFS_WRAPPER_DIR:$PATH" buildiso -f -c -z -d xz -p "forja-$DESKTOP" -b stable -k "$KERNEL_PKG" -r "$CHROOTS" -t "$OUT" -v; then
    BUILDISO_OK=1
    break
  fi
  if (( attempt < 3 )); then
    echo "Aviso: compactação/geração da ISO falhou na tentativa $attempt." >&2
    sleep $((attempt * 20))
  fi
done
if (( BUILDISO_OK != 1 )); then
  echo "ERRO: geração da ISO falhou após 3 tentativas." >&2
  exit 46
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
