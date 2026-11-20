#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/manjaro/venom-community-mate"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass(){ printf 'OK: %s\n' "$*"; }

required=(
  "$ROOT/shared/pacman.conf"
  "$P/profile.conf" "$P/user-repos.conf"
  "$P/Packages-Root" "$P/Packages-Desktop" "$P/Packages-Live" "$P/Packages-Mhwd"
  "$P/desktop-overlay/etc/lightdm/lightdm.conf"
  "$P/desktop-overlay/etc/skel/.config/gtk-3.0/settings.ini"
  "$P/desktop-overlay/etc/dconf/db/local.d/00-venom"
  "$P/live-overlay/usr/share/calamares/branding/biglinux/branding.desc"
  "$P/live-overlay/usr/share/calamares/branding/biglinux/logo.svg"
  "$P/live-overlay/usr/share/calamares/branding/biglinux/big-welcome.svg"
  "$P/root-overlay/etc/default/grub"
  "$P/root-overlay/etc/mkinitcpio.conf"
  "$P/root-overlay/etc/plymouth/plymouthd.conf"
  "$P/root-overlay/etc/systemd/system/venom-dconf-update.service"
)
for f in "${required[@]}"; do [[ -s "$f" ]] || fail "arquivo obrigatório ausente: $f"; done

bash -n "$P/profile.conf" || fail "sintaxe inválida em profile.conf"
bash -n "$P/desktop-overlay/usr/local/bin/venom-mate-first-login" || fail "sintaxe inválida no primeiro login"
bash -n "$P/live-overlay/usr/local/bin/venom-mate-first-login" || fail "sintaxe inválida no primeiro login Live"

for pkg in mate mate-extra mate-media lightdm lightdm-gtk-greeter networkmanager network-manager-applet bluez bluez-utils blueman papirus-icon-theme bibata-cursor-theme gnome-themes-extra cantarell-fonts; do
  grep -Fxq "$pkg" "$P/Packages-Desktop" || fail "pacote MATE/integração ausente: $pkg"
done
for pkg in calamares calamares-biglinux grub-theme-live-manjaro manjaro-live-systemd mkinitcpio-nfs-utils nbd; do
  grep -Fxq "$pkg" "$P/Packages-Live" || fail "dependência Live/Calamares ausente: $pkg"
done
grep -Fxq 'plymouth' "$P/Packages-Root" || fail "Plymouth ausente"
grep -Fxq 'biglinux-keyring' "$P/Packages-Root" || fail "chave do repositório que fornece Calamares ausente"

if grep -Eiq '^(xfce|xfce4-|xfconf|xfdesktop|xfwm4|thunar|thunar-|xfce4-panel|xfce4-session)' "$P"/Packages-*; then
  fail "pacotes XFCE ainda presentes"
fi
if grep -Eiq '^(biglinux-driver-manager|biglinux-bash-config|biglinux-nano-config|biglinux-vim-config|biglinux-metapackage|biglinux-apps-rename|biglinux-base-icons|bigicons-papient|comm-wallpapers-xfce|biglinux-livecd|biglinux-grub-restore|biglinux-webapps|bigocrpdf|auto-tweaks-browser|tts-biglinux)$' "$P"/Packages-*; then
  fail "aplicativo/branding adicional do BigLinux ainda listado"
fi

grep -Fq 'displaymanager="lightdm"' "$P/profile.conf" || fail "LightDM não selecionado"
grep -Fq "'lightdm'" "$P/profile.conf" || fail "serviço LightDM não habilitado"
grep -Fq '[venom-community]' "$P/user-repos.conf" || fail "repositório do Calamares não configurado no perfil"
grep -Fq '[venom-community]' "$ROOT/shared/pacman.conf" || fail "repositório do Calamares não configurado para a compilação"
grep -Fq 'componentName:           venom' "$P/live-overlay/usr/share/calamares/branding/biglinux/branding.desc" || fail "identificador VENOM do Calamares ausente"
grep -Fq 'productName:          VENOM OS' "$P/live-overlay/usr/share/calamares/branding/biglinux/branding.desc" || fail "marca VENOM ausente no Calamares"
grep -Fq 'SidebarBackground:    "#03060b"' "$P/live-overlay/usr/share/calamares/branding/biglinux/branding.desc" || fail "tema escuro do Calamares ausente"
grep -Fq 'GRUB_DISTRIBUTOR="VENOM OS"' "$P/root-overlay/etc/default/grub" || fail "identidade VENOM no GRUB ausente"
grep -Fq 'quiet splash' "$P/root-overlay/etc/default/grub" || fail "inicialização silenciosa/preta não configurada"
grep -Fq 'plymouth' "$P/root-overlay/etc/mkinitcpio.conf" || fail "hook Plymouth ausente"
grep -Fq 'Theme=spinner' "$P/root-overlay/etc/plymouth/plymouthd.conf" || fail "tema Plymouth ausente"
grep -Fq 'gtk-theme-name=Adwaita-dark' "$P/desktop-overlay/etc/skel/.config/gtk-3.0/settings.ini" || fail "Adwaita-dark ausente"
grep -Fq 'gtk-icon-theme-name=Papirus-Dark' "$P/desktop-overlay/etc/skel/.config/gtk-3.0/settings.ini" || fail "Papirus escuro/azul ausente"
grep -Fq 'gtk-cursor-theme-name=Bibata-Modern-Classic' "$P/desktop-overlay/etc/skel/.config/gtk-3.0/settings.ini" || fail "Bibata ausente"

if grep -RniE 'BigLinux|BigCommunity|coruja|owl|xfce|xfwm|thunar|sddm|plasma' "$P"/desktop-overlay "$P"/live-overlay "$P"/root-overlay; then
  fail "referência visual/desktop antigo encontrada nos overlays"
fi

python3 - "$P" <<'PY'
import pathlib, sys, xml.etree.ElementTree as ET
root = pathlib.Path(sys.argv[1])
svgs = list(root.rglob("*.svg"))
if not svgs:
    raise SystemExit("FALHA: nenhum SVG de identidade encontrado")
for path in svgs:
    ET.parse(path)
print(f"OK: {len(svgs)} SVG(s) bem formados")
PY

pass "arquivos e sintaxe do perfil Manjaro"
pass "MATE completo, LightDM, rede, Bluetooth, Papirus e Bibata"
pass "XFCE e aplicativos adicionais BigLinux removidos da seleção"
pass "Calamares preservado com identidade VENOM e tema escuro"
pass "GRUB/Plymouth escuros e defaults MATE preparados"
printf 'VALIDAÇÃO ESTÁTICA CONCLUÍDA. A compilação só inicia no job dependente deste validador.\n'
