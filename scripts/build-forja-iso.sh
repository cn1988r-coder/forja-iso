#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${ROOT}/work"
EOS_DIR="${WORK}/EndeavourOS-ISO"
PKG_DIR="${WORK}/packages"
EOS_COMMIT="90376d8f52ab19e19073eed33d6f36c46ec7c409"
PKGBUILDS_COMMIT="474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd"
SHELLY_COMMIT="6840658b19d72205c38bd320c1cef6ff3076bc7c"

log() { printf '\n[FORJA] %s\n' "$*"; }
die() { printf '\n[ERRO] %s\n' "$*" >&2; exit 1; }
trap 'die "Falha na linha $LINENO. Consulte a mensagem acima."' ERR

[[ "$(uname -m)" == x86_64 ]] || die "A compilação atual exige x86_64."
[[ -f /etc/arch-release ]] || die "Use EndeavourOS ou Arch Linux com os repositórios EndeavourOS habilitados."
[[ $EUID -ne 0 ]] || die "Execute como usuário normal. O script usa sudo apenas nas etapas necessárias."
command -v git >/dev/null || die "Instale git."
command -v makepkg >/dev/null || die "makepkg não encontrado. Use um host Arch/EndeavourOS."
command -v sudo >/dev/null || die "sudo não encontrado."

mkdir -p "$WORK" "$PKG_DIR"

log "Instalando dependências de compilação"
sudo pacman -S --needed --noconfirm archiso git squashfs-tools imagemagick base-devel python

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

log "Adaptando lista KDE para MATE"
python - "$EOS_DIR/packages.x86_64" "$ROOT/build/packages.mate" <<'PY'
import pathlib, re, sys
target = pathlib.Path(sys.argv[1])
mate = pathlib.Path(sys.argv[2]).read_text()
remove = re.compile(r'^(ark|bluedevil|breeze.*|dolphin.*|endeavouros-konsole-colors|eos-apps-info|eos-log-tool|eos-packagelist|eos-quickstart|firewall-applet|ffmpegthumbs|gwenview|haruna|kate|kcalc|kde.*|kimageformats|kinfocenter|kio.*|konsole|kscreen|kwallet.*|kwayland.*|okular|partitionmanager|plasma.*|powerdevil|print-manager|reflector-simple|spectacle|sddm|welcome|xdg-desktop-portal-kde)$')
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
chmod 0755 "$EOS_DIR/airootfs/usr/bin/forja-installer"
SKEL="$EOS_DIR/airootfs/root/endeavouros-skel-liveuser/src/etc/skel"
mkdir -p "$SKEL/.config/gtk-3.0" "$SKEL/.config/gtk-4.0"
cp "$ROOT/build/airootfs/etc/skel/.config/gtk-3.0/settings.ini" "$SKEL/.config/gtk-3.0/settings.ini"
cp "$ROOT/build/airootfs/etc/skel/.config/gtk-4.0/settings.ini" "$SKEL/.config/gtk-4.0/settings.ini"
rm -f "$SKEL/.local/share/applications/calamares.desktop"
rm -rf "$SKEL/.config/kdedefaults" "$SKEL/.config/plasma"* "$SKEL/.local/share/plasma" "$SKEL/.local/share/konsole" "$SKEL/.local/etc/xdg/kdeglobals"
find "$SKEL/.config" -maxdepth 1 -type f \( -name 'balo*' -o -name 'kcm*' -o -name 'kde*' -o -name 'kscreen*' -o -name 'ksmserverrc' -o -name 'ksplashrc' -o -name 'kwalletrc' -o -name 'kxkbrc' -o -name 'plasma*' -o -name 'powerdevilrc' -o -name 'powermanagementprofilesrc' -o -name 'systemsettingsrc' \) -delete
mkdir -p "$EOS_DIR/airootfs/root/packages"

log "Gerando wallpapers pretos puros"
magick -size 1920x1080 xc:'#000000' "$EOS_DIR/airootfs/root/livewall.png"
magick -size 1920x1080 xc:'#000000' "$EOS_DIR/airootfs/root/endeavouros-wallpaper.png"

log "Removendo etapa específica de configuração KDE do prepare.sh"
python - "$EOS_DIR/prepare.sh" <<'PY'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
s = re.sub(r'(?s)# add date to wallpaper.*?a[i]rootfs/root/livewall\.png\n', '# Forja OS: fundo preto puro, sem data sobreposta.\n', s, count=1)
s = re.sub(r'(?m)^wget -qN .*endeavouros-wallpaper\.png.*\n', '', s)
s = re.sub(r'(?m)^get_pkg "eos-settings-plasma"\s*$', '# KDE settings package intentionally omitted for Forja OS.', s)
p.write_text(s)
PY

log "Configurando LightDM, removendo sobras KDE e alvo gráfico"
python - "$EOS_DIR/run_before_squashfs.sh" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
old = 'systemctl set-default multi-user.target'
new = 'systemctl enable lightdm.service\nsystemctl set-default graphical.target\ndconf update'
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
s = s.replace(motd_marker, "sed -i 's/EndeavourOS/Forja OS/g' \"/usr/lib/endeavouros-release\"\n" + motd_marker, 1)
os_marker = 'echo "---> Install locally built packages on ISO (place packages under airootfs/root/packages) --->"'
os_patch = 'sed -i -e \'s/^NAME=.*/NAME="Forja OS"/\' -e \'s/^PRETTY_NAME=.*/PRETTY_NAME="Forja OS"/\' -e \'s/^ID=.*/ID=forja/\' -e \'s/^ID_LIKE=.*/ID_LIKE=arch/\' "/usr/lib/os-release"\nif ! grep -q \'^ID_LIKE=\' "/usr/lib/os-release"; then printf \'ID_LIKE=arch\\n\' >> "/usr/lib/os-release"; fi\n'
if os_marker not in s:
    raise SystemExit('Não foi possível localizar a etapa de pacotes locais.')
s = s.replace(os_marker, os_patch + os_marker, 1)
package_cleanup = 'rm -rf "/root/packages/"'
if package_cleanup not in s:
    raise SystemExit('Não foi possível localizar a limpeza dos pacotes locais.')
s = s.replace(package_cleanup, 'rm -f "/usr/share/applications/calamares.desktop"\n' + package_cleanup, 1)
p.write_text(s)
PY
rm -rf "$EOS_DIR/airootfs/root/root-theme"

log "Removendo marcas visíveis do EndeavourOS nos menus de boot"
mapfile -t boot_files < <(grep -RIl 'EndeavourOS' "$EOS_DIR/efiboot" "$EOS_DIR/syslinux" 2>/dev/null || true)
for file in "${boot_files[@]}"; do
  sed -i 's/EndeavourOS/Forja OS/g' "$file"
done

log "Definindo identificação da ISO"
python - "$EOS_DIR/profiledef.sh" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
s = s.replace('iso_name="EndeavourOS_Triton"', 'iso_name="ForjaOS_MATE"')
s = s.replace('iso_label="EOS_$(date +%Y%m)"', 'iso_label="FORJA_$(date +%Y%m)"')
s = s.replace('iso_publisher="EndeavourOS <https://endeavouros.com>"', 'iso_publisher="Forja OS"')
s = s.replace('iso_application="EndeavourOS Live/Rescue CD"', 'iso_application="Forja OS Live/Install"')
p.write_text(s)
PY

log "Construindo Calamares do fork EndeavourOS"
CALAMARES_SRC="$WORK/PKGBUILDS"
clone_at_commit https://github.com/endeavouros-team/PKGBUILDS.git "$CALAMARES_SRC" "$PKGBUILDS_COMMIT"
(
  cd "$CALAMARES_SRC/calamares"
  python - PKGBUILD <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
needle = '    awk -i inplace -v version="${pkgver}" -v release="${release_name}" "$replace_command" "${srcdir}/calamares-${pkgver}/data/eos/branding/endeavouros/branding.desc"\n'
if needle not in s:
    raise SystemExit("Não foi possível localizar a etapa de branding no PKGBUILD do Calamares.")
extra = """    sed -i "s/EndeavourOS/Forja OS/g" "${srcdir}/calamares-${pkgver}/data/eos/branding/endeavouros/branding.desc"
    sed -i -E 's/requiredStorage:[[:space:]]*5\.5/requiredStorage:    15.0/' "${srcdir}/calamares-${pkgver}/data/eos/modules/welcome_offline.conf"
    sed -i -E 's/requiredRam:[[:space:]]*1\.0/requiredRam:        2.0/' "${srcdir}/calamares-${pkgver}/data/eos/modules/welcome_offline.conf"
    python - <<'PATCH'
from pathlib import Path
cleaner = Path("${srcdir}/calamares-${pkgver}/data/eos/scripts/chrooted_cleaner_script.sh")
content = cleaner.read_text()
remove_marker = "        /etc/sudoers.d/g_wheel\\n"
if remove_marker not in content:
    raise SystemExit("Não foi possível localizar a lista de limpeza do liveuser no Calamares.")
content = content.replace(remove_marker, remove_marker + "        /etc/lightdm/lightdm.conf.d/10-forja-live.conf\\n", 1)
cleanup_marker = "    rm -rf /etc/calamares /opt/extra-drivers"
if cleanup_marker not in content:
    raise SystemExit("Não foi possível localizar a limpeza final do Calamares.")
content = content.replace(cleanup_marker, "    rm -f /usr/bin/forja-installer /usr/share/applications/forja-installer.desktop\\n" + cleanup_marker, 1)
cleaner.write_text(content)
PATCH
"""
s = s.replace(needle, needle + extra)
p.write_text(s)
PY
  makepkg --syncdeps --noconfirm
  find . -maxdepth 1 -name 'calamares-*.pkg.tar.zst' -exec cp -v {} "$PKG_DIR/" \;
)

log "Construindo Shelly a partir do código oficial fixado"
SHELLY_SRC="$WORK/Shelly-ALPM"
clone_at_commit https://github.com/Seafoam-Labs/Shelly-ALPM.git "$SHELLY_SRC" "$SHELLY_COMMIT"
(
  cd "$SHELLY_SRC"
  cp PKGBUILD-git PKGBUILD
  sed -i 's/#branch=development/#commit='"$SHELLY_COMMIT"'/' PKGBUILD
  makepkg --syncdeps --noconfirm
  find . -maxdepth 1 -name 'shelly-git-*.pkg.tar.zst' -exec cp -v {} "$PKG_DIR/" \;
)

log "Construindo tema Bibata a partir da receita AUR"
BIBATA_SRC="$WORK/bibata-cursor-theme-aur"
BIBATA_COMMIT="$(git ls-remote https://aur.archlinux.org/bibata-cursor-theme.git HEAD | awk '{print $1}')"
[[ -n "$BIBATA_COMMIT" ]] || die "Não foi possível localizar a receita AUR do Bibata."
clone_at_commit https://aur.archlinux.org/bibata-cursor-theme.git "$BIBATA_SRC" "$BIBATA_COMMIT"
(
  cd "$BIBATA_SRC"
  makepkg --syncdeps --noconfirm
  find . -maxdepth 1 -name 'bibata-cursor-theme-*.pkg.tar.zst' -exec cp -v {} "$PKG_DIR/" \;
)

log "Construindo Ferdium a partir da receita AUR"
FERDIUM_SRC="$WORK/ferdium-aur"
clone_at_commit https://aur.archlinux.org/ferdium-bin.git "$FERDIUM_SRC" "$(git ls-remote https://aur.archlinux.org/ferdium-bin.git HEAD | awk '{print $1}')"
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
[[ -f "$EOS_DIR/airootfs/root/packages/$(basename "$(find "$EOS_DIR/airootfs/root/packages" -maxdepth 1 -name 'bibata-cursor-theme-*.pkg.tar.zst' -print -quit)")" ]] || die "Pacote Bibata não foi gerado."

log "Preparando framework EndeavourOS"
(
  cd "$EOS_DIR"
  ./prepare.sh
)

log "Reaplicando fundo preto após prepare.sh"
magick -size 1920x1080 xc:'#000000' "$EOS_DIR/airootfs/root/livewall.png"
magick -size 1920x1080 xc:'#000000' "$EOS_DIR/airootfs/root/endeavouros-wallpaper.png"

log "Compilando ISO Forja OS. Esta etapa pode levar bastante tempo."
(
  cd "$EOS_DIR"
  sudo ./mkarchiso -v .
)

log "Arquivos ISO gerados:"
find "$EOS_DIR/out" -maxdepth 1 -type f -name '*.iso' -printf '%p (%k KiB)\n'
