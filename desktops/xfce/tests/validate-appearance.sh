#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd -- "$ROOT/../.." && pwd)"
BUILD="$REPO_ROOT/build-manjaro.sh"

fail() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}
pass() {
  printf 'OK: %s\n' "$*"
}

# 1. Shell syntax of the profile scripts and the main builder.
while IFS= read -r -d '' script; do
  bash -n "$script" || fail "sintaxe Bash inválida: $script"
done < <(find "$ROOT" -type f -name '*.sh' -print0)
bash -n "$ROOT/profile.conf" || fail "sintaxe inválida em profile.conf"
bash -n "$BUILD" || fail "sintaxe inválida em build-manjaro.sh"
pass "sintaxe dos scripts"

# 2. Required packages. Repository-qualified package lines are accepted.
for package in \
  xfce4-session xfce4-panel xfce4-settings xfdesktop xfwm4 thunar \
  xfce4-whiskermenu-plugin dockbarx xfce4-dockbarx-plugin \
  networkmanager network-manager-applet bluez bluez-utils blueman \
  papirus-icon-theme papirus-folders bibata-cursor-theme \
  materia-gtk-theme adw-gtk-theme lightdm lightdm-gtk-greeter \
  shelly-bin shelly-flatpak-backend-bin flatpak firefox; do
  grep -Fxq "$package" "$ROOT/packages.manjaro" ||
    grep -Eq "^>[^[:space:]]+[[:space:]]+$package$" "$ROOT/packages.manjaro" ||
    fail "pacote obrigatório ausente: $package"
done
! grep -Eq '(^|[[:space:]])(pamac|pamac-gtk|pamac-cli|libpamac|libpamac-flatpak-plugin)([[:space:]]|$)' "$ROOT/packages.manjaro" ||
  fail "Pamac ainda consta no perfil"
pass "pacotes XFCE, DockbarX e Shelly"

# 3. Native XFCE panel XML and plugin order.
python3 - "$ROOT/panel-default.xml" <<'PY'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
plugins = root.find("./property[@name='plugins']")
panel = root.find("./property[@name='panels']/property[@name='panel-1']")
assert plugins is not None and panel is not None, "estrutura Xfconf ausente"
expected = {
    "1": "whiskermenu",
    "2": "dockbarx",
    "3": "xfce4-clipman-plugin",
    "4": "showdesktop",
    "5": "separator",
    "6": "systray",
    "7": "pulseaudio",
    "8": "power-manager-plugin",
    "9": "notification-plugin",
    "10": "clock",
}
for key, value in expected.items():
    node = plugins.find(f"./property[@name='plugin-{key}']")
    assert node is not None and node.attrib.get("value") == value, (key, value)
ids = [node.attrib["value"] for node in panel.findall("./property[@name='plugin-ids']/value")]
assert ids == list(expected), ids
assert plugins.find("./property[@name='plugin-5']/property[@name='expand']").attrib["value"] == "true"
PY
pass "painel XFCE e sequência dos plugins"

# 4. Visual defaults, neutral palette and Whisker menu.
grep -Fq 'button-title=Forja OS' "$ROOT/forja-whiskermenu.rc" || fail "nome do botão Iniciar ausente"
grep -Fq 'item-icon-size=2' "$ROOT/forja-whiskermenu.rc" || fail "tamanho dos ícones do Whisker ausente"
grep -Fq 'menu-width=600' "$ROOT/forja-whiskermenu.rc" || fail "largura do menu ausente"
grep -Fq 'menu-height=560' "$ROOT/forja-whiskermenu.rc" || fail "altura do menu ausente"
grep -Fq '@define-color forja_bg #202020' "$ROOT/forja-gtk.css" || fail "fundo grafite ausente"
grep -Fq '@define-color forja_surface #292929' "$ROOT/forja-gtk.css" || fail "superfície grafite ausente"
grep -Fq '@define-color forja_text #f4f4f4' "$ROOT/forja-gtk.css" || fail "texto claro ausente"
grep -Eqi '#[0-9a-f]*(00a|08f|f80|f00)' "$ROOT/forja-gtk.css" && fail "cor de destaque não neutra no CSS"
grep -Fq 'Materia-dark' "$ROOT/apply-forja-layout.sh" || fail "tema de janelas Materia ausente"
grep -Fq 'Papirus-Dark' "$ROOT/apply-forja-layout.sh" || fail "ícones Papirus ausentes"
grep -Fq 'Bibata-Modern-Classic' "$ROOT/apply-forja-layout.sh" || fail "cursor Bibata ausente"
pass "tema visual monocromático e menu"

# 5. DockbarX repository and removal of Docklike.
grep -Fq '>community-extra dockbarx' "$ROOT/packages.manjaro" || fail "DockbarX sem origem Community"
grep -Fq '>community-extra xfce4-dockbarx-plugin' "$ROOT/packages.manjaro" || fail "plugin DockbarX sem origem Community"
grep -Fq '[community-extra]' "$BUILD" || fail "repositório community-extra ausente"
grep -Fq '[community-stable]' "$BUILD" || fail "repositório community-stable ausente"
grep -Fq 'https://repo.communitybig.org/$repo/$arch' "$BUILD" || fail "URL do repositório Community ausente"
if grep -Eqi 'docklike' "$ROOT/packages.manjaro" "$ROOT/panel-default.xml" "$ROOT/install-branding.sh" "$ROOT/apply-forja-layout.sh"; then
  fail "referência antiga ao Docklike encontrada no perfil Manjaro XFCE"
fi
pass "DockbarX e ausência do Docklike"

# 6. Shelly, locale and branding installation.
grep -q '^Exec=/usr/bin/shelly-ui$' "$ROOT/shelly-autostart.desktop" || fail "atalho de inicialização da Shelly inválido"
grep -q '^X-GNOME-Autostart-enabled=true$' "$ROOT/shelly-autostart.desktop" || fail "autostart da Shelly desativado"
grep -Fq 'etc/xdg/autostart/shelly.desktop' "$ROOT/install-branding.sh" || fail "Shelly não é instalada no autostart"
grep -Fq 'LANG=pt_BR.UTF-8' "$ROOT/install-branding.sh" || fail "locale pt_BR ausente"
grep -Fq 'LANGUAGE=pt_BR:pt:en' "$ROOT/install-branding.sh" || fail "LANGUAGE pt-BR ausente"
grep -Fq 'localedef --prefix="$DEST" -i pt_BR -f UTF-8 pt_BR.UTF-8' "$ROOT/install-branding.sh" || fail "geração do locale pt_BR ausente"
grep -Fq 'etc/xdg/xfce4/panel/default.xml' "$ROOT/install-branding.sh" || fail "painel padrão não é instalado"
grep -Fq 'etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml' "$ROOT/install-branding.sh" || fail "painel padrão não é aplicado a novos usuários"
pass "Shelly, idioma e instalação da identidade"

# 7. Independent XFCE profile, boot splash and installer defaults.
grep -Fq 'TARGET="$PROFILE_ROOT/manjaro/forja-xfce"' "$BUILD" || fail "destino do perfil Forja XFCE ausente"
grep -Fq 'desktops/xfce/profile.conf' "$BUILD" || fail "profile.conf próprio não é utilizado"
grep -Fq 'GRUB_DEFAULT_FILE="$ROOTFS_CHROOT/etc/default/grub"' "$BUILD" || fail "caminho do GRUB no rootfs não está configurado"
grep -Fq 'buildiso -f -x' "$BUILD" || fail "etapa de preparação do rootfs ausente"
grep -Fq 'buildiso -f -c -z' "$BUILD" || fail "etapa de compactação da ISO ausente"
grep -Fq 'Theme=forja' "$ROOT/plymouth/plymouthd.conf" || fail "tema Plymouth não selecionado"
grep -Fq 'quiet splash loglevel=3' "$ROOT/plymouth/forja-grub" || fail "parâmetros de boot silencioso ausentes"
grep -Fq 'defaultFileSystemType: "btrfs"' "$ROOT/calamares/partition.conf" || fail "Btrfs não é padrão do instalador"
grep -Fq 'compress=zstd:1' "$ROOT/calamares/mount.conf" || fail "compressão Btrfs zstd ausente"
pass "perfil independente, Plymouth e Calamares"

# 8. Ferdium is installed in the system rootfs, not just listed as a package.
grep -Fq 'flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo' "$BUILD" || fail "Flathub system remote ausente"
grep -Fq 'flatpak install --system --noninteractive --assumeyes flathub org.ferdium.Ferdium' "$BUILD" || fail "instalação system-wide do Ferdium ausente"
grep -Fq 'flatpak info --system org.ferdium.Ferdium' "$BUILD" || fail "verificação do Ferdium ausente"
pass "integração declarada do Ferdium"

# 9. All XML files in the XFCE profile must parse.
python3 - "$ROOT" <<'PY'
import sys
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(sys.argv[1])
files = sorted(root.rglob("*.xml"))
assert files, "nenhum XML encontrado"
for path in files:
    ET.parse(path)
    print(f"XML_OK: {path.relative_to(root)}")
PY
pass "arquivos XML"

echo "VALIDATION_OK: perfil-fonte Forja OS XFCE aprovado; nenhuma ISO foi compilada."
