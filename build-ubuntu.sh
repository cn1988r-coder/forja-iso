#!/usr/bin/env bash
# Forja: construção da BASE Ubuntu LTS, sem ambiente gráfico.
# Esta base é independente de Arch Linux e Manjaro.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

UBUNTU_SUITE="${FORJA_UBUNTU_SUITE:-resolute}"
UBUNTU_ARCH="${FORJA_UBUNTU_ARCH:-amd64}"
MIRROR="${FORJA_UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu}"
WORK="${FORJA_UBUNTU_WORK:-/tmp/forja-ubuntu}"
ROOTFS="${FORJA_UBUNTU_ROOTFS:-$WORK/rootfs}"
OUTPUT="${FORJA_OUTPUT:-/forja-output}"
BASE_PACKAGES=(
  ubuntu-minimal
  systemd systemd-sysv
  sudo
  network-manager
  linux-generic
  initramfs-tools
  locales
  tzdata
  ca-certificates
  curl wget gnupg
  apt-transport-https
  unattended-upgrades
  dbus
  xdg-user-dirs
)

die() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
log() { printf '\n[Forja Ubuntu] %s\n' "$*"; }

[[ "$EUID" -eq 0 ]] || die "Execute como root dentro do contêiner de compilação."
[[ "$UBUNTU_SUITE" == resolute ]] || die "A base está fixada no Ubuntu 26.04 LTS (resolute). Não use versões intermediárias."
[[ "$UBUNTU_ARCH" == amd64 || "$UBUNTU_ARCH" == arm64 ]] || die "Arquitetura não suportada: $UBUNTU_ARCH"
command -v chroot >/dev/null 2>&1 || die "chroot não está disponível."
if ! command -v debootstrap >/dev/null 2>&1 || ! command -v zstd >/dev/null 2>&1; then
  command -v apt-get >/dev/null 2>&1 || die "Instale debootstrap e zstd no ambiente construtor."
  log "Instalando ferramentas necessárias no contêiner construtor."
  apt-get update
  apt-get install -y debootstrap zstd ca-certificates
fi
mkdir -p "$WORK" "$OUTPUT"
[[ ! -e "$ROOTFS" ]] || rm -rf "$ROOTFS"

log "Criando sistema-base Ubuntu 26.04 LTS ($UBUNTU_SUITE), arquitetura $UBUNTU_ARCH."
debootstrap --arch="$UBUNTU_ARCH" --variant=minbase \
  --components=main,restricted,universe,multiverse \
  "$UBUNTU_SUITE" "$ROOTFS" "$MIRROR"

# DNS e pseudo-filesystems necessários durante a configuração do chroot.
install -Dm644 /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
for fs in proc sys dev dev/pts; do
  mkdir -p "$ROOTFS/$fs"
done
mount -t proc proc "$ROOTFS/proc"
mount -t sysfs sysfs "$ROOTFS/sys"
mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"
cleanup() {
  for fs in dev/pts dev sys proc; do
    mountpoint -q "$ROOTFS/$fs" && umount -lf "$ROOTFS/$fs" || true
  done
}
trap cleanup EXIT

cat > "$ROOTFS/etc/apt/sources.list.d/ubuntu.sources" <<SOURCES
Types: deb
URIs: $MIRROR
Suites: $UBUNTU_SUITE ${UBUNTU_SUITE}-updates ${UBUNTU_SUITE}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu
Suites: ${UBUNTU_SUITE}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
SOURCES

log "Atualizando somente os repositórios oficiais Ubuntu."
chroot "$ROOTFS" apt-get update
chroot "$ROOTFS" apt-get install -y --no-install-recommends "${BASE_PACKAGES[@]}"
chroot "$ROOTFS" apt-get full-upgrade -y
chroot "$ROOTFS" apt-get clean
rm -rf "$ROOTFS/var/lib/apt/lists/"*

# Não instalar desktop, display manager, sessão gráfica ou pacotes de outra base.
if chroot "$ROOTFS" dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | \
  grep -Eiq '^(xorg|wayland|gnome-shell|plasma-desktop|xfce4|mate-desktop-environment|lightdm|gdm3|sddm)(:|$)'; then
  die "Foi detectado pacote de ambiente gráfico na base Ubuntu."
fi

# Perfil visual declarativo: será consumido pelo módulo de desktop escolhido
# somente na etapa de composição da ISO. Nenhum tema é aplicado à base sem GUI.
install -d "$ROOTFS/usr/share/forja/visual"
cat > "$ROOTFS/usr/share/forja/visual/profile.conf" <<'VISUAL'
# Forja Ubuntu visual profile. Applied later by the selected desktop module.
GTK_THEME=Materia-dark
ICON_THEME=Papirus
ICON_THEME_DARK=Papirus-Dark
ICON_THEME_LIGHT=Papirus
CURSOR_THEME=Bibata-Modern-Ice
FOLDER_ICON_FAMILY=Papirus
VISUAL

cat > "$ROOTFS/usr/share/forja/visual/README" <<'VISUAL_README'
Este arquivo pertence à base Ubuntu da Forja.
O módulo de interface gráfica selecionado deve instalar os temas Materia,
Papirus e Bibata a partir de fontes compatíveis com Ubuntu e aplicar este perfil.
A base não instala nem configura ambiente gráfico.
VISUAL_README

# O atualizador de versão só deve oferecer upgrades entre versões LTS.
# Ex.: 26.04 LTS -> 28.04 LTS; nunca 26.10 ou 27.04.
cat > "$ROOTFS/etc/update-manager/release-upgrades" <<'RELEASE'
[DEFAULT]
Prompt=lts
RELEASE

cat > "$ROOTFS/etc/apt/apt.conf.d/20auto-upgrades" <<'AUTO'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
AUTO

# Atualiza automaticamente os pacotes da LTS instalada, incluindo o pocket
# -updates e correções de segurança. Não habilita pockets de outra versão.
cat > "$ROOTFS/etc/apt/apt.conf.d/52forja-unattended-upgrades" <<'APTCONF'
Unattended-Upgrade::Origins-Pattern {
  "origin=Ubuntu,codename=${distro_codename}";
  "origin=Ubuntu,codename=${distro_codename}-updates";
  "origin=Ubuntu,codename=${distro_codename}-security";
};
APTCONF

cat > "$ROOTFS/etc/apt/apt.conf.d/53forja-phased-updates" <<'APTCONF'
APT::Get::Always-Include-Phased-Updates "true";
APTCONF

printf '%s\n' "Forja Ubuntu LTS" > "$ROOTFS/etc/hostname"
cat > "$ROOTFS/etc/os-release.forja" <<'OSRELEASE'
NAME="Forja Ubuntu"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Forja Ubuntu 26.04 LTS"
VERSION_ID="26.04"
VERSION_CODENAME=resolute
UBUNTU_CODENAME=resolute
OSRELEASE
# Preserve os-release fornecido pelo pacote base; disponibiliza metadados Forja.
install -Dm644 "$ROOTFS/etc/os-release.forja" "$ROOTFS/usr/share/forja/os-release"
rm -f "$ROOTFS/etc/os-release.forja"

log "Validando identidade da base e ausência de ambiente gráfico."
grep -q '^VERSION_CODENAME=resolute$' "$ROOTFS/usr/share/forja/os-release"
test -s "$ROOTFS/usr/share/forja/visual/profile.conf"
chroot "$ROOTFS" dpkg-query -W ubuntu-minimal systemd-sysv network-manager linux-generic

log "Empacotando root filesystem Ubuntu."
mkdir -p "$OUTPUT"
tar --numeric-owner --xattrs --acls -C "$ROOTFS" -I 'zstd -T0 -19' \
  -cf "$OUTPUT/forja-ubuntu-resolute-base.tar.zst" .
sha256sum "$OUTPUT/forja-ubuntu-resolute-base.tar.zst" \
  > "$OUTPUT/forja-ubuntu-resolute-base.tar.zst.sha256"

cat > "$OUTPUT/ubuntu-base-info.txt" <<INFO
BASE=Ubuntu
VERSION=26.04 LTS
CODENAME=resolute
ARCH=$UBUNTU_ARCH
DESKTOP=none
KERNEL=linux-generic
VISUAL_PROFILE=Materia-dark;Papirus;Bibata-Modern-Ice
UPDATES=Ubuntu official LTS repositories
RELEASE_UPGRADES=disabled
INFO

log "BASE_OK: $OUTPUT/forja-ubuntu-resolute-base.tar.zst"
