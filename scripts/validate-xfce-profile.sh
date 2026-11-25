#!/usr/bin/env bash
# Static profile checks only. This script does not compile, build an ISO,
# execute an installer, format disks, or run virtual machines.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
B="$ROOT/build"
fail(){ printf 'FALHA: %s
' "$*" >&2; exit 1; }
need(){ [[ -s "$1" ]] || fail "Arquivo ausente/vazio: ${1#"$ROOT"/}"; }

required=(
  build/profiledef.sh build/pacman.conf build/packages.x86_64
  build/install-packages.x86_64 build/aur-packages.x86_64
  build/airootfs/etc/mkinitcpio.conf.d/archiso.conf
  build/airootfs/etc/locale.conf build/airootfs/etc/locale.gen
  build/airootfs/etc/vconsole.conf build/airootfs/root/.bash_profile
  build/airootfs/usr/local/lib/venom/venom-live-setup
  build/airootfs/usr/local/lib/venom/venom-live-ready
  build/airootfs/etc/systemd/system/venom-live-setup.service
  build/airootfs/etc/systemd/system/venom-live-ready.service
  build/airootfs/etc/lightdm/lightdm.conf.d/50-venom-live.conf
  build/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
  build/airootfs/etc/skel/.config/fastfetch/config.jsonc
  build/airootfs/etc/skel/.config/fastfetch/logo.txt
  build/airootfs/usr/share/icons/hicolor/scalable/apps/venom-menu.svg
  build/install-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
  build/install-overlay/etc/skel/.config/fastfetch/config.jsonc
  build/install-overlay/etc/skel/.config/fastfetch/logo.txt
  build/install-overlay/usr/share/icons/hicolor/scalable/apps/venom-menu.svg
  build/install-overlay/usr/local/lib/venom/configure-recovery
  build/install-overlay/etc/systemd/system/venom-recovery-setup.service
  build/install-overlay/etc/systemd/system/grub-btrfsd.service.d/override.conf
  build/install-overlay/etc/mkinitcpio.conf.d/venom-btrfs.conf
  build/install-overlay/etc/default/grub
  installer/settings.conf installer/modules/partition/partition.conf
  installer/modules/mount/mount.conf installer/modules/fstab/fstab.conf
  installer/modules/venominstall/main.py installer/modules/venominstall/venominstall.conf
  installer/pacman-install.conf
  installer/modules/services-systemd/services-systemd.conf
  installer/branding/branding.desc installer/venom-installer.desktop
  scripts/build-venom-iso.sh scripts/build-aur-packages.sh scripts/stage-installer-payload.sh scripts/setup-xfce-windows-dark.sh
)
for f in "${required[@]}"; do need "$ROOT/$f"; done

for f in build/profiledef.sh build/airootfs/root/.bash_profile \
  build/airootfs/usr/local/lib/venom/venom-live-setup \
  build/airootfs/usr/local/lib/venom/venom-live-ready \
  build/install-overlay/usr/local/lib/venom/configure-recovery \
  scripts/build-venom-iso.sh scripts/build-aur-packages.sh scripts/stage-installer-payload.sh; do
  bash -n "$ROOT/$f" || fail "Sintaxe Bash inválida: $f"
done

grep -Fxq 'LANG=pt_BR.UTF-8' "$B/airootfs/etc/locale.conf" || fail "Locale pt_BR ausente."
grep -Fxq 'pt_BR.UTF-8 UTF-8' "$B/airootfs/etc/locale.gen" || fail "Locale pt_BR não habilitado."
grep -Fxq 'KEYMAP=br-abnt2' "$B/airootfs/etc/vconsole.conf" || fail "Teclado ABNT2 ausente."
grep -Fq 'systemctl start venom-live-setup.service' "$B/airootfs/root/.bash_profile" || fail "Inicialização Live não chama o setup."
grep -Fq 'autologin root' "$B/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf" || fail "Autologin tty1 ausente."
grep -Fq 'user-session=xfce' "$B/airootfs/etc/lightdm/lightdm.conf.d/50-venom-live.conf" || fail "LightDM não inicia XFCE."

for manifest in "$B/packages.x86_64" "$B/install-packages.x86_64"; do
  for package in xfce4 xfce4-whiskermenu-plugin xfce4-docklike-plugin \
    lightdm lightdm-gtk-greeter materia-gtk-theme papirus-icon-theme \
    timeshift btrfs-progs inotify-tools cronie; do
    grep -Fxq "$package" "$manifest" || fail "$package ausente de $manifest"
  done
done
for manifest in "$B/packages.x86_64" "$B/install-packages.x86_64"; do
  grep -Fxq fastfetch "$manifest" || fail "Fastfetch ausente de $manifest"
done
for package in libpamac-aur pamac-aur grub-btrfs bibata-cursor-theme papirus-folders-git; do
  grep -Fxq "$package" "$B/aur-packages.x86_64" || fail "Pacote AUR ausente: $package"
done

for panel in \
  "$B/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
  "$B/install-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"; do
  grep -Fq 'value="whiskermenu"' "$panel" || fail "Whisker Menu ausente: $panel"
  grep -Fq 'value="venom-menu"' "$panel" || fail "Ícone VENOM ausente: $panel"
  grep -Fq 'value="11"' "$panel" || fail "Docklike ausente: $panel"
  grep -Fq 'name="size" type="uint" value="40"' "$panel" || fail "Painel de 40 px ausente: $panel"
  PANEL_FILE="$panel" python - <<'PY'
import os
import sys
import xml.etree.ElementTree as ET

path = os.environ["PANEL_FILE"]
root = ET.parse(path).getroot()
panel = root.find("./property[@name='panels']/property[@name='panel-1']")
plugins = root.find("./property[@name='plugins']")
if panel is None or plugins is None:
    sys.exit("Painel ou lista de plugins ausente: " + path)

ids_node = panel.find("./property[@name='plugin-ids']")
if ids_node is None:
    sys.exit("Ordem dos plugins não definida: " + path)

ordered_ids = [int(node.attrib["value"]) for node in ids_node.findall("value")]
plugin_types = {}
for node in plugins.findall("property"):
    name = node.attrib.get("name", "")
    if name.startswith("plugin-"):
        plugin_types[name.removeprefix("plugin-")] = node.attrib.get("value", "")

if len(ordered_ids) < 2:
    sys.exit("Painel não tem dois plugins iniciais: " + path)
first_two = [plugin_types.get(str(plugin_id)) for plugin_id in ordered_ids[:2]]
if first_two != ["whiskermenu", "docklike"]:
    sys.exit(
        "Docklike precisa estar imediatamente à direita do menu Iniciar. "
        f"Ordem encontrada: {first_two!r} em {path}"
    )
print(f"OK: Whisker Menu seguido imediatamente por Docklike em {path}")
PY
done

grep -Fq 'Materia-dark' "$B/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" || fail "Materia Dark não definido."
grep -Fq 'Papirus-Dark' "$B/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" || fail "Papirus não definido."
grep -Fq 'Bibata-Modern-Classic' "$B/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" || fail "Bibata não definido."

grep -Fq 'defaultFileSystemType: btrfs' "$ROOT/installer/modules/partition/partition.conf" || fail "Btrfs não é o padrão do instalador."
grep -Fq 'efiSystemPartition: /boot/efi' "$ROOT/installer/modules/partition/partition.conf" || fail "ESP deve ser montada em /boot/efi."
grep -Fq 'subvolume: /@' "$ROOT/installer/modules/mount/mount.conf" || fail "Subvolume @ ausente."
grep -Fq 'subvolume: /@home' "$ROOT/installer/modules/mount/mount.conf" || fail "Subvolume @home ausente."
grep -Fq 'venom-recovery-setup.service' "$ROOT/installer/modules/services-systemd/services-systemd.conf" || fail "Serviço de recuperação não será habilitado."
grep -Fq 'include_btrfs_home_for_backup": "true"' "$B/install-overlay/usr/local/lib/venom/configure-recovery" || fail "Snapshot não inclui home."
grep -Fq 'grub-btrfsd.service' "$B/install-overlay/usr/local/lib/venom/configure-recovery" || fail "grub-btrfsd não é ativado."

if grep -R -Eiq 'manjaro|endeavouros|biglinux|mhwd|Kora|Coral|Yaru-blue|adw-gtk3-dark' \
  "$B/packages.x86_64" "$B/install-packages.x86_64" "$B/airootfs/etc/skel" "$B/install-overlay" "$ROOT/installer"; then
  fail "Resíduo de outra base/tema não aprovado encontrado."
fi

python - <<'PY'
import ast
import json
import xml.etree.ElementTree as ET
from pathlib import Path
import yaml

root = Path(".")
for p in [
    Path("build/airootfs/etc/skel/.config/fastfetch/config.jsonc"),
    Path("build/install-overlay/etc/skel/.config/fastfetch/config.jsonc"),
]:
    config = json.loads(p.read_text(encoding="utf-8"))
    assert config["logo"]["source"] == "~/.config/fastfetch/logo.txt"
    assert config["logo"]["color"] == {"1": "#2588ff", "2": "#ffffff"}
    assert config["display"]["color"]["keys"] == "#2588ff"
    assert config["display"]["color"]["output"] == "#ffffff"
    assert len(config["modules"]) >= 15
for p in [
    Path("build/airootfs/etc/skel/.config/fastfetch/logo.txt"),
    Path("build/install-overlay/etc/skel/.config/fastfetch/logo.txt"),
]:
    logo = p.read_text(encoding="utf-8")
    assert "$1" in logo and "$2" in logo and "_/" in logo
for p in [Path("installer/modules/venominstall/main.py")]:
    ast.parse(p.read_text(encoding="utf-8"), filename=str(p))
for p in [Path("installer/settings.conf"), *Path("installer/modules").rglob("*.conf"), Path("installer/branding/branding.desc")]:
    yaml.safe_load(p.read_text(encoding="utf-8"))
for p in list(Path("build/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml").glob("*.xml")) + list(Path("build/install-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml").glob("*.xml")):
    ET.parse(p)
print("VENOM: arquivos, sintaxe e configurações estáticas aprovados.")
PY

printf '[VENOM] Validação estática concluída. Nenhuma compilação ou ISO foi iniciada.
'
