#!/usr/bin/env bash
# Strict pre-build gate for VENOM OS XFCE 1.0.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/manjaro/venom-xfce"
D="$P/desktop-overlay"
L="$P/live-overlay"
R="$P/root-overlay"
X="$D/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
W="$ROOT/.github/workflows/build-venom-xfce.yml"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass(){ printf 'VERDE: %s\n' "$*"; }

required=(
  "$ROOT/shared/pacman.conf" "$W"
  "$P/profile.conf" "$P/user-repos.conf"
  "$P/Packages-Root" "$P/Packages-Desktop" "$P/Packages-Live" "$P/Packages-Mhwd"
  "$D/etc/skel/.config/gtk-3.0/settings.ini"
  "$D/etc/skel/.config/autostart/venom-iptvnator-install.desktop"
  "$D/etc/skel/.config/autostart/venom-network-applet.desktop"
  "$D/usr/local/bin/venom-install-iptvnator"
  "$D/etc/skel/.config/xfce4/panel/docklike-2.rc"
  "$D/etc/skel/.config/xfce4/helpers.rc"
  "$L/etc/issue"
  "$L/etc/calamares/settings.conf"
  "$L/etc/calamares/branding/venom/branding.desc"
  "$L/etc/calamares/branding/venom/logo.svg"
  "$L/etc/calamares/branding/venom/welcome.svg"
  "$L/usr/share/applications/venom-installer.desktop"
  "$R/etc/os-release" "$R/etc/default/grub" "$R/etc/pamac.conf"
  "$X/xfce4-panel.xml" "$X/xfce4-desktop.xml" "$X/xsettings.xml" "$X/xfwm4.xml"
  "$X/xfce4-keyboard-shortcuts.xml" "$X/thunar.xml" "$X/xfce4-session.xml"
  "$X/xfce4-notifyd.xml" "$X/xfce4-power-manager.xml" "$X/xfce4-screensaver.xml"
  "$X/xfce4-settings-manager.xml" "$X/xfce4-taskmanager.xml" "$X/xfce4-terminal.xml"
  "$D/usr/share/backgrounds/venom/venom-black.svg"
  "$D/usr/share/themes/adw-gtk3-dark/xfwm4/themerc"
)
for f in "${required[@]}"; do [[ -s "$f" ]] || fail "arquivo obrigatório ausente/vazio: $f"; done

bash -n "$P/profile.conf" || fail "sintaxe inválida em profile.conf"
bash -n "$D/usr/local/bin/venom-install-iptvnator" || fail "sintaxe inválida no instalador de aplicativos"

for pkg in xfce4 xfce4-panel xfce4-session xfce4-settings xfdesktop xfwm4 xfconf thunar xfce4-docklike-plugin firefox pamac-gtk lightdm networkmanager adw-gtk-theme bigicons-papient big-bibata-cursor-theme noto-nerd-fonts-lite; do
  grep -Fxq "$pkg" "$P/Packages-Desktop" || fail "pacote obrigatório ausente em Packages-Desktop: $pkg"
done
for pkg in calamares polkit-gnome community-livecd-key; do
  grep -Fxq "$pkg" "$P/Packages-Live" || fail "pacote obrigatório ausente em Packages-Live: $pkg"
done
grep -Fxq 'community-keyring' "$P/Packages-Root" || fail "community-keyring ausente em Packages-Root"
grep -Fq 'pamac build --no-confirm iptvnator-bin ferdium-bin' "$D/usr/local/bin/venom-install-iptvnator" || fail "instalação AUR de IPTVnator/Ferdium ausente"

if grep -Eiq '^(mate|mate-extra|mate-media|marco|caja)([[:space:]]|$)' "$P"/Packages-*; then
  fail "pacotes MATE encontrados no perfil XFCE"
fi
if grep -Eiq '^(big-video-converter|biglinux-webapps|bigocrpdf|comm-wallpapers-xfce|comm-welcome|biglinux-driver-manager|biglinux-metapackage|biglinux-apps-rename|auto-tweaks-browser|tts-biglinux|brave-browser|libreoffice-fresh-pt-br|steam|rustdesk-bin)([[:space:]]|$)' "$P"/Packages-*; then
  fail "aplicativo adicional da imagem Community foi incluído sem solicitação"
fi
if grep -R -Eiq 'biglinux|bigcommunity|repo\.biglinux\.com\.br' "$P/user-repos.conf" "$ROOT/shared/pacman.conf" "$L" "$D"; then
  fail "branding ou repositório BigLinux/BigCommunity ainda presente nos overlays VENOM"
fi

grep -Fq 'label="VENOM_OS_XFCE_1.0"' "$P/profile.conf" || fail "rótulo VENOM OS XFCE 1.0 ausente"
grep -Fq 'hostname="venom"' "$P/profile.conf" || fail "hostname VENOM ausente"
grep -Fq 'displaymanager="lightdm"' "$P/profile.conf" || fail "LightDM não selecionado"
grep -Fq 'autologin="true"' "$P/profile.conf" || fail "autologin do Live não habilitado no perfil Manjaro"
if grep -R -Eiq 'autologin-user=|autologin="true"' "$D" "$R"; then fail "autologin foi incluído no sistema instalado; deve existir somente no Live"; fi
grep -Fq 'mhwd_used="true"' "$P/profile.conf" || fail "integração MHWD do instalador não habilitada"
grep -Fq '[community-stable]' "$P/user-repos.conf" || fail "repositório Community Stable não configurado"
grep -Fq 'https://repo.communitybig.org/community-stable/$arch' "$P/user-repos.conf" || fail "URL Community Stable ausente"
grep -Fq '[community-stable]' "$ROOT/shared/pacman.conf" || fail "repositório Community Stable ausente na configuração de compilação"
if grep -Fq 'repo.biglinux.com.br' "$ROOT/shared/pacman.conf"; then fail "URL antiga do repositório ainda configurada"; fi

grep -Fq 'AECEEE84E52BBFAA9F1C9DF01EA0CEEEB09B44A3' "$W" || fail "fingerprint completo da chave Community não está configurado no workflow"
if grep -Eiq 'TrustAll|SigLevel[[:space:]]*=[[:space:]]*Optional' "$ROOT/shared/pacman.conf" "$P/user-repos.conf"; then fail "verificação de assinatura foi enfraquecida"; fi
grep -Fq "if: github.event_name == 'workflow_dispatch'" "$W" || fail "build não está protegido contra disparo automático por push"

grep -Fq 'NAME="VENOM OS"' "$R/etc/os-release" || fail "nome do sistema não é VENOM OS"
grep -Fq 'PRETTY_NAME="VENOM OS"' "$R/etc/os-release" || fail "nome amigável não é VENOM OS"
grep -Fq 'GRUB_DISTRIBUTOR="VENOM OS"' "$R/etc/default/grub" || fail "identidade VENOM OS ausente no GRUB"
grep -Fq 'EnableAUR' "$R/etc/pamac.conf" || fail "Pamac AUR não habilitado"
grep -Fq 'Exec=nm-applet --indicator' "$D/etc/skel/.config/autostart/venom-network-applet.desktop" || fail "NetworkManager applet não inicia na sessão XFCE"
grep -Fq 'button-icon" type="string" value="comm-menu-symbolic"' "$X/xfce4-panel.xml" || fail "ícone Community do menu Whisker ausente"
grep -Fq 'WebBrowser=firefox' "$D/etc/skel/.config/xfce4/helpers.rc" || fail "Firefox não configurado como navegador padrão"
grep -Fq '/usr/share/backgrounds/venom/venom-black.svg' "$X/xfce4-desktop.xml" || fail "papel de parede VENOM ausente"

grep -Fq 'gtk-theme-name=adw-gtk3-dark' "$D/etc/skel/.config/gtk-3.0/settings.ini" || fail "tema GTK escuro Community ausente"
grep -Fq 'gtk-icon-theme-name=bigicons-papient-dark' "$D/etc/skel/.config/gtk-3.0/settings.ini" || fail "ícones BigIcons Papient Dark ausentes"
grep -Fq 'gtk-font-name=Noto Sans Nerd Font Medium 10' "$D/etc/skel/.config/gtk-3.0/settings.ini" || fail "fonte GTK Noto Sans Nerd ausente"
grep -Fq 'ThemeName" type="string" value="adw-gtk3-dark"' "$X/xsettings.xml" || fail "tema XFCE incorreto"
grep -Fq 'IconThemeName" type="string" value="bigicons-papient-dark"' "$X/xsettings.xml" || fail "ícones XFCE incorretos"
grep -Fq 'FontName" type="string" value="Noto Sans Nerd Font Medium 10"' "$X/xsettings.xml" || fail "fonte de interface incorreta"
grep -Fq 'MonospaceFontName" type="string" value="Noto Mono Nerd Font Medium 11"' "$X/xsettings.xml" || fail "fonte monoespaçada incorreta"
grep -Fq 'CursorThemeName" type="string" value="Bibata-Modern-Classic"' "$X/xsettings.xml" || fail "cursor Bibata incorreto"
grep -Fq 'name="theme" type="string" value="adw-gtk3-dark"' "$X/xfwm4.xml" || fail "tema do gerenciador de janelas incorreto"

grep -Fq 'branding: venom' "$L/etc/calamares/settings.conf" || fail "Calamares não está usando branding VENOM"
grep -Fq '      - mhwdcfg' "$L/etc/calamares/settings.conf" || fail "módulo MHWD ausente na sequência Calamares"
grep -Fq 'productName:         VENOM OS' "$L/etc/calamares/branding/venom/branding.desc" || fail "nome VENOM OS ausente no branding Calamares"
grep -Fq 'Exec=pkexec /usr/bin/calamares -D6' "$L/usr/share/applications/venom-installer.desktop" || fail "atalho do instalador não executa Calamares"

python3 - "$P" <<'PY'
import pathlib, sys, xml.etree.ElementTree as ET
root = pathlib.Path(sys.argv[1])
xmls = list(root.rglob("*.xml")) + list(root.rglob("*.svg"))
for path in xmls:
    ET.parse(path)
x = root / "desktop-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
panel = ET.parse(x / "xfce4-panel.xml").getroot()
panels = panel.find("./property[@name='panels']")
ids = [int(v.attrib["value"]) for v in panels.findall("value")]
if ids != [1]:
    raise SystemExit(f"FALHA: esperado somente um painel, encontrados {ids}")
p = panel.find("./property[@name='panels']/property[@name='panel-1']")
def prop(name):
    n = p.find(f"./property[@name='{name}']")
    return n.attrib.get("value") if n is not None else None
if prop("length") != "100" or prop("size") != "40" or prop("mode") != "0":
    raise SystemExit("FALHA: painel deve ser horizontal, 100% de largura e 40 px")
if not (prop("position") or "").startswith("p=8;"):
    raise SystemExit("FALHA: painel não está ancorado na parte inferior")
plugins = p.find("./property[@name='plugin-ids']")
plugin_ids = [int(v.attrib["value"]) for v in plugins.findall("value")]
if plugin_ids != [1,2,7,9,4,3,6,10,5,8]:
    raise SystemExit(f"FALHA: ordem dos plugins do painel divergiu: {plugin_ids}")
print("VERDE: painel único inferior, horizontal, 100%, 40 px e ordem original dos plugins")
print(f"VERDE: {len(xmls)} XML/SVG válidos")
PY

ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' "$L/etc/calamares/settings.conf" >/dev/null || fail "settings.conf do Calamares não é YAML válido"

pass "perfil XFCE, dependências, configurações e scripts"
[[ "$(find "$D/usr/share/themes/adw-gtk3-dark/xfwm4" -type f | wc -l)" -eq 58 ]] || fail "tema XFWM4 Community incompleto (esperados 58 arquivos)"
pass "tema Community, ícones, cursor, fontes e decoração XFWM4 instalados e selecionados"
pass "Calamares, branding VENOM e integração MHWD configurados"
pass "assinatura PGP verificada sem TrustAll"
printf 'VALIDAÇÃO ESTRITA CONCLUÍDA: TODOS OS REQUISITOS ESTÁTICOS ESTÃO VERDES.\n'
