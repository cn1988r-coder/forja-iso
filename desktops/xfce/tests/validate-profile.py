#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

# Shell syntax: scripts that assemble or configure the XFCE edition.
shell_files = [REPO / "build-manjaro.sh"]
shell_files += sorted(ROOT.rglob("*.sh"))
shell_files += sorted((ROOT / "shelly").glob("PKGBUILD*"))
for path in shell_files:
    if not path.is_file():
        errors.append(f"Arquivo ausente: {path.relative_to(REPO)}")
        continue
    result = subprocess.run(["bash", "-n", str(path)], capture_output=True, text=True)
    if result.returncode:
        errors.append(f"Erro de sintaxe em {path.relative_to(REPO)}: {result.stderr.strip()}")

# Parse all XFCE XML defaults instead of relying on grep-only checks.
for relative in ("panel-default.xml", "forja-xfce-desktop.xml"):
    path = ROOT / relative
    try:
        ET.parse(path)
    except (OSError, ET.ParseError) as exc:
        errors.append(f"XML inválido em {relative}: {exc}")

# Verify the package profile, including Manjaro's '>repository package' syntax.
package_file = ROOT / "packages.manjaro"
lines = package_file.read_text(encoding="utf-8").splitlines()
packages = set()
for raw in lines:
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    fields = line.split()
    packages.add(fields[-1] if fields[0].startswith(">") else fields[0])

required_packages = {
    "xfce4-session", "xfce4-panel", "xfce4-settings", "xfdesktop", "xfwm4",
    "thunar", "xfce4-whiskermenu-plugin", "dockbarx", "xfce4-dockbarx-plugin",
    "lightdm", "lightdm-gtk-greeter", "firefox", "shelly-bin",
    "shelly-flatpak-backend-bin", "flatpak", "papirus-icon-theme",
    "papirus-folders", "bibata-cursor-theme", "adw-gtk-theme",
    "materia-gtk-theme", "networkmanager", "network-manager-applet",
    "bluez", "bluez-utils", "blueman"
}
missing = sorted(required_packages - packages)
require(not missing, "Pacotes obrigatórios ausentes: " + ", ".join(missing))
require("pamac" not in packages and "pamac-gtk" not in packages,
        "Pamac ainda aparece no perfil de pacotes.")
require("xfce4-docklike-plugin" not in packages,
        "Docklike ainda aparece no perfil; a edição deve usar DockbarX.")

# Check the panel's declared plugin order and names.
try:
    tree = ET.parse(ROOT / "panel-default.xml")
    plugins = tree.getroot().find("./property[@name='plugins']")
    panel = tree.getroot().find("./property[@name='panels']/property[@name='panel-1']")
    require(plugins is not None and panel is not None, "Estrutura Xfconf do painel incompleta.")
    if plugins is not None and panel is not None:
        expected = {
            "1": "whiskermenu", "2": "dockbarx", "3": "xfce4-clipman-plugin",
            "4": "showdesktop", "5": "separator", "6": "systray",
            "7": "pulseaudio", "8": "power-manager-plugin",
            "9": "notification-plugin", "10": "clock"
        }
        for ident, name in expected.items():
            node = plugins.find(f"./property[@name='plugin-{ident}']")
            require(node is not None and node.get("value") == name,
                    f"Plugin {ident} do painel deveria ser {name}.")
        actual_ids = [node.get("value") for node in panel.findall("./property[@name='plugin-ids']/value")]
        require(actual_ids == list(expected), f"Ordem de plugins inesperada: {actual_ids}")
except (OSError, ET.ParseError):
    pass

# Verify required branding/session integration files and exact autostart target.
required_files = [
    "profile.conf", "install-branding.sh", "apply-forja-layout.sh",
    "panel-default.xml", "forja-whiskermenu.rc", "forja-gtk.css",
    "forja-xfce-desktop.xml", "shelly-autostart.desktop",
    "plymouth/forja.plymouth", "plymouth/forja.script",
    "plymouth/forja-mkinitcpio.conf", "calamares/partition.conf",
    "calamares/mount.conf", "shelly/PKGBUILD-bin"
]
for relative in required_files:
    require((ROOT / relative).is_file(), f"Arquivo de integração ausente: {relative}")

desktop = (ROOT / "shelly-autostart.desktop").read_text(encoding="utf-8")
require("Exec=/usr/bin/shelly-ui" in desktop, "Autostart da Shelly não aponta para shelly-ui.")
require("X-GNOME-Autostart-enabled=true" in desktop, "Autostart da Shelly não está habilitado.")

build = (REPO / "build-manjaro.sh").read_text(encoding="utf-8")
require('TARGET="$PROFILE_ROOT/manjaro/forja-xfce"' in build,
        "O build não cria o perfil independente forja-xfce.")
require("FORJA_PREFLIGHT_ONLY" in build,
        "Modo de pré-verificação sem compilação da ISO não encontrado.")
require("buildiso -f -c -z" in build,
        "Etapa de geração da ISO não está identificável no script.")

if errors:
    print("VALIDAÇÃO XFCE: FALHOU")
    for error in errors:
        print(" - " + error)
    sys.exit(1)

print("VALIDAÇÃO XFCE: APROVADA")
print(f"Scripts verificados: {len(shell_files)}")
print(f"Pacotes obrigatórios conferidos: {len(required_packages)}")
print("XML do painel e da área de trabalho: válido")
print("Perfil independente, DockbarX, Shelly e arquivos de integração: presentes")
print("Nenhuma compilação da ISO foi executada.")
