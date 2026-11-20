#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/manjaro/venom-xfce"
X="$P/desktop-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass(){ printf 'OK: %s\n' "$*"; }

required=(
  "$ROOT/shared/pacman.conf"
  "$P/profile.conf" "$P/user-repos.conf"
  "$P/Packages-Root" "$P/Packages-Desktop" "$P/Packages-Live" "$P/Packages-Mhwd"
  "$P/desktop-overlay/etc/skel/.config/gtk-3.0/settings.ini"
  "$P/desktop-overlay/etc/skel/.config/autostart/venom-iptvnator-install.desktop"
  "$P/desktop-overlay/usr/local/bin/venom-install-iptvnator"
  "$P/desktop-overlay/etc/skel/.config/xfce4/panel/docklike-2.rc"
  "$P/desktop-overlay/etc/skel/.config/xfce4/helpers.rc"
  "$P/live-overlay/etc/issue"
  "$P/root-overlay/etc/os-release"
  "$P/root-overlay/etc/default/grub"
  "$P/root-overlay/etc/pamac.conf"
  "$X/xfce4-panel.xml" "$X/xfce4-desktop.xml" "$X/xsettings.xml" "$X/xfwm4.xml"
  "$X/xfce4-keyboard-shortcuts.xml" "$X/thunar.xml" "$X/xfce4-session.xml"
  "$X/xfce4-notifyd.xml" "$X/xfce4-power-manager.xml" "$X/xfce4-screensaver.xml"
  "$X/xfce4-settings-manager.xml" "$X/xfce4-taskmanager.xml" "$X/xfce4-terminal.xml"
  "$P/desktop-overlay/usr/share/backgrounds/venom/venom-black.svg"
)
for f in "${required[@]}"; do [[ -s "$f" ]] || fail "arquivo obrigatório ausente: $f"; done

bash -n "$P/profile.conf" || fail "sintaxe inválida em profile.conf"
bash -n "$P/desktop-overlay/usr/local/bin/venom-install-iptvnator" || fail "sintaxe inválida no instalador IPTVnator"

for pkg in xfce4 xfce4-panel xfce4-session xfce4-settings xfdesktop xfwm4 xfconf thunar xfce4-docklike-plugin firefox pamac-gtk lightdm networkmanager; do
  grep -Fxq "$pkg" "$P/Packages-Desktop" || fail "pacote XFCE/aplicativo selecionado ausente: $pkg"
done
grep -Fxq 'community-keyring' "$P/Packages-Root" || fail "chave da fonte de pacotes XFCE ausente"
grep -Fxq 'community-livecd-key' "$P/Packages-Live" || fail "chave do ambiente Live ausente"
grep -Fq 'pamac build --no-confirm iptvnator-bin ferdium-bin' "$P/desktop-overlay/usr/local/bin/venom-install-iptvnator" || fail "instalação IPTVnator e Ferdium via Pamac ausente"

if grep -Eiq '^(mate|mate-extra|mate-media|marco|caja)([[:space:]]|$)' "$P"/Packages-*; then
  fail "pacotes MATE encontrados no perfil XFCE"
fi
if grep -Eiq '^(big-video-converter|biglinux-webapps|bigocrpdf|bigicons-papient|comm-wallpapers-xfce|comm-welcome|comm-xfce-config|biglinux-driver-manager|biglinux-metapackage|biglinux-apps-rename|auto-tweaks-browser|tts-biglinux|brave-browser|libreoffice-fresh-pt-br|steam|rustdesk-bin)([[:space:]]|$)' "$P"/Packages-*; then
  fail "aplicativo adicional/identidade visual do fornecedor ainda listado"
fi
if grep -Eiq 'calamares|biglinux|bigcommunity|repo\.biglinux\.com\.br' "$P"/Packages-* "$P/user-repos.conf" "$ROOT/shared/pacman.conf"; then
  fail "identidade ou instalador de terceiros encontrado no perfil"
fi

grep -Fq 'label="VENOM_OS_XFCE_1.0"' "$P/profile.conf" || fail "rótulo VENOM OS XFCE 1.0 ausente"
grep -Fq 'hostname="venom"' "$P/profile.conf" || fail "hostname VENOM ausente"
grep -Fq 'displaymanager="lightdm"' "$P/profile.conf" || fail "LightDM não selecionado"
grep -Fq '[community-stable]' "$P/user-repos.conf" || fail "repositório Community Stable não configurado"
grep -Fq 'https://repo.communitybig.org/community-stable/$arch' "$P/user-repos.conf" || fail "URL Community Stable ausente"
grep -Fq '[community-stable]' "$ROOT/shared/pacman.conf" || fail "repositório Community Stable ausente na configuração de compilação"
if grep -Fq 'repo.biglinux.com.br' "$ROOT/shared/pacman.conf"; then fail "URL antiga que retornava 404 ainda está configurada"; fi

grep -Fq 'NAME="VENOM OS"' "$P/root-overlay/etc/os-release" || fail "nome do sistema não é VENOM OS"
grep -Fq 'PRETTY_NAME="VENOM OS"' "$P/root-overlay/etc/os-release" || fail "nome amigável não é VENOM OS"
grep -Fq 'GRUB_DISTRIBUTOR="VENOM OS"' "$P/root-overlay/etc/default/grub" || fail "identidade VENOM OS ausente no GRUB"
grep -Fq 'gtk-theme-name=Adwaita-dark' "$P/desktop-overlay/etc/skel/.config/gtk-3.0/settings.ini" || fail "tema escuro ausente"
grep -Fq 'gtk-icon-theme-name=Papirus-Dark' "$P/desktop-overlay/etc/skel/.config/gtk-3.0/settings.ini" || fail "ícones escuros ausentes"
grep -Fq 'ThemeName" type="string" value="Adwaita-dark"' "$X/xsettings.xml" || fail "tema escuro XFCE ausente"
grep -Fq 'IconThemeName" type="string" value="Papirus-Dark"' "$X/xsettings.xml" || fail "ícones escuros XFCE ausentes"
grep -Fq 'EnableAUR' "$P/root-overlay/etc/pamac.conf" || fail "Pamac AUR não habilitado"
grep -Fq 'WebBrowser=firefox' "$P/desktop-overlay/etc/skel/.config/xfce4/helpers.rc" || fail "Firefox não configurado como navegador padrão"
grep -Fq '/usr/share/backgrounds/venom/venom-black.svg' "$X/xfce4-desktop.xml" || fail "papel de parede VENOM OS ausente"
if grep -RniE 'biglinux|bigcommunity|Snowy\.jpg|brave-browser|libreoffice-writer|ashyterm|comm-menu-symbolic' "$P/desktop-overlay"; then
  fail "identidade visual ou lançador de aplicativo removido ainda presente no XFCE"
fi

python3 - "$P" <<'PY'
import pathlib, sys, xml.etree.ElementTree as ET
root = pathlib.Path(sys.argv[1])
xmls = list(root.rglob("*.xml")) + list(root.rglob("*.svg"))
if not xmls:
    raise SystemExit("FALHA: nenhum XML/SVG encontrado")
for path in xmls:
    ET.parse(path)
panel_path = root / "desktop-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
tree = ET.parse(panel_path)
channel = tree.getroot()
panels = channel.find("./property[@name='panels']")
ids = [int(v.attrib["value"]) for v in panels.findall("value")]
if ids != [1]:
    raise SystemExit(f"FALHA: esperado somente um painel, encontrados {ids}")
p = channel.find("./property[@name='panels']/property[@name='panel-1']")
def prop(name):
    node = p.find(f"./property[@name='{name}']")
    return node.attrib.get("value") if node is not None else None
if prop("length") != "100" or prop("size") != "40" or prop("mode") != "0":
    raise SystemExit("FALHA: painel deve ser horizontal, 100% de largura e 40 px")
if not (prop("position") or "").startswith("p=8;"):
    raise SystemExit("FALHA: painel não está ancorado na parte inferior")
print("OK: painel único inferior, horizontal, 100% de largura e 40 px")
print(f"OK: {len(xmls)} XML/SVG(s) bem formados")
PY

pass "perfil e sintaxe do VENOM OS XFCE"
pass "estrutura, painel e configurações originais do XFCE preservados"
pass "Firefox, Pamac, IPTVnator e Ferdium selecionados"
pass "aplicativos extras e identidade visual do fornecedor removidos"
pass "tema escuro e identidade VENOM OS configurados"
pass "repositório Community Stable configurado com nome de base correto"
printf 'VALIDAÇÃO ESTÁTICA DO VENOM OS CONCLUÍDA.\n'
