#!/usr/bin/env python3
"""Apply the Forja OS branding and focused users-step fixes to pinned Calamares."""
from pathlib import Path
import re
import sys

source = Path(sys.argv[1])
branding = Path(__file__).resolve().parent / "branding/forja"
target_branding = source / "data/eos/branding/forja"
target_branding.mkdir(parents=True, exist_ok=True)
for item in branding.iterdir():
    if item.is_file():
        (target_branding / item.name).write_bytes(item.read_bytes())

settings = source / "data/eos/settings_offline.conf"
text = settings.read_text()
if "branding: endeavouros" not in text:
    raise SystemExit("Branding upstream esperado não encontrado em settings_offline.conf.")
settings.write_text(text.replace("branding: endeavouros", "branding: forja", 1))

# Keep only the explicit system-group mapping for wheel.
for name in ("usersq.conf", "users.conf"):
    path = source / "data/eos/modules" / name
    if not path.exists():
        continue
    text = path.read_text()
    text, count = re.subn(r"(?m)^    - wheel\n(?=    - rfkill\n)", "", text, count=1)
    if count != 1:
        raise SystemExit(f"Entrada duplicada de wheel não encontrada em {name}.")
    path.write_text(text)

# Anchor the QML expressions to match Calamares' full-string C++ validation.
for name in ("usersq-qt6.qml", "usersq.qml"):
    path = source / "src/modules/usersq" / name
    if not path.exists():
        continue
    text = path.read_text()
    old_user = "regularExpression: /[a-z_][a-z0-9_-]*[$]?$/"
    new_user = "regularExpression: /^[a-z_][a-z0-9_-]*[$]?$/"
    old_host = "regularExpression: /[a-zA-Z0-9][-a-zA-Z0-9_]+/"
    new_host = "regularExpression: /^[a-zA-Z0-9][-a-zA-Z0-9_]+$/"
    if old_user not in text or old_host not in text:
        raise SystemExit(f"Expressões de validação esperadas não encontradas em {name}.")
    text = text.replace(old_user, new_user, 1).replace(old_host, new_host, 1)
    text = text.replace("id: _userLoginField\n", "id: _userLoginField\n                maximumLength: 31\n", 1)
    text = text.replace("id: _hostName\n", "id: _hostName\n                maximumLength: 63\n", 1)
    text = text.replace('_userLoginField.text === "root"', '(_userLoginField.text === "root" || _userLoginField.text === "nobody")')
    text = text.replace('_hostName.text === "localhost"', '_hostName.text.toLowerCase() === "localhost"')
    text = text.replace("root is not allowed as username.", "root and nobody are reserved usernames.")
    if name == "usersq-qt6.qml":
        colors = {
            '#3A3F45': '#202a36',
            '#4E5661': '#26394b',
            '#7F3F3F': '#63343b',
            '#5C6370': '#40546b',
            '#7F9F7F': '#4b91c8',
            '#BF616A': '#d56b78',
        }
        for old, new in colors.items():
            text = text.replace(old, new)
        text = text.replace('commentsColor: "#ffffff"', 'commentsColor: "#b8c4d2"')
    path.write_text(text)

qml = (source / "src/modules/usersq/usersq-qt6.qml").read_text()
if "regularExpression: /[a-z_][a-z0-9_-]*[$]?$/" in qml:
    raise SystemExit("Validação QML do login não foi ancorada.")
if "regularExpression: /[a-zA-Z0-9][-a-zA-Z0-9_]+/" in qml:
    raise SystemExit("Validação QML do hostname não foi ancorada.")


# Replace the EndeavourOS installer flows with the Forja image installer.
# Both modes install the exact live filesystem from the ISO. Online mode only
# refreshes Arch package databases; it does not run netinstall or select a DE.
settings_common = """# Forja OS installer: one guided flow, user credentials first, disk second, then install the Forja live image.
---
modules-search: [ local ]

instances:
- id: online
  module: packages
  config: packages_online.conf
- id: forja_cleanup
  module: shellprocess
  config: shellprocess_forja_cleanup.conf

sequence:
- show:
  - usersq
  - partition
  - summary
- exec:
  - partition
  - mount
  - unpackfs
  - packages@online
  - machineid
  - locale
  - keyboard
  - localecfg
  - fstab
  - removeuser
  - usersq
  - networkcfg
  - displaymanager
  - hwclock
  - grubcfg
  - bootloader
  - services-systemd
  - preservefiles
  - shellprocess@forja_cleanup
  - umount
- show:
  - finished

branding: forja
prompt-install: true
dont-chroot: false
oem-setup: false
disable-cancel: false
disable-cancel-during-exec: false
hide-back-and-next-during-exec: true
quit-at-end: false
"""

settings_offline = source / "data/eos/settings_offline.conf"
settings_online = source / "data/eos/settings_online.conf"
settings_offline.write_text(settings_common)
settings_online.write_text(settings_common)

modules = source / "data/eos/modules"
# The same installer automatically works with or without a network connection.
(modules / "packages_online.conf").write_text("""---
backend: pacman
skip_if_no_internet: true
update_db: true
update_system: false
pacman:
    num_retries: 6
    disable_download_timeout: true
    needed_only: true
""")

# Fixed Forja boot policy: no desktop/package/bootloader chooser.
modules = source / "data/eos/modules"
(modules / "bootloader.conf").write_text("""---
kernelSearchPath: "/usr/lib/modules"
kernelPattern: "^vmlinuz.*"
kernelParams: [ "quiet", "loglevel=3" ]
refindKernelList: [ "linux" ]
efiBootloaderId: "Forja OS"
grubInstall: "grub-install"
grubMkconfig: "grub-mkconfig"
grubCfg: "/boot/grub/grub.cfg"
grubProbe: "grub-probe"
efiBootMgr: "efibootmgr"
installEFIFallback: true
""")
(modules / "grubcfg.conf").write_text("""---
overwrite: true
prefer_grub_d: false
keep_distributor: false
kernel_params:
  - "quiet"
  - "loglevel=3"
defaults:
    GRUB_TIMEOUT: 5
    GRUB_DEFAULT: 0
    GRUB_DISABLE_SUBMENU: false
    GRUB_DISABLE_RECOVERY: true
    GRUB_EARLY_INITRD_LINUX_STOCK: ""
always_use_defaults: true
""")
(modules / "displaymanager.conf").write_text("""---
displaymanagers:
  - lightdm
basicSetup: false
sysconfigSetup: false
""")
(modules / "shellprocess_forja_cleanup.conf").write_text("""---
dontChroot: false
verbose: true
script:
  - "pacman -Rdd --noconfirm calamares"
  - "rm -rf /etc/calamares /usr/share/calamares /usr/lib/calamares /usr/share/endeavouros"
  - "rm -f /etc/pacman.d/endeavouros-mirrorlist /usr/lib/endeavouros-release"
""")
(modules / "services-systemd.conf").write_text("""---
units:
  - name: "NetworkManager.service"
    action: "enable"
  - name: "lightdm.service"
    action: "enable"
  - name: "bluetooth.service"
    action: "enable"
  - name: "systemd-timesyncd.service"
    action: "enable"
  - name: "fstrim.timer"
    action: "enable"
  - name: "graphical.target"
    action: "set-default"
""")

# Fail closed if the pinned source no longer provides the image-based install path.
unpackfs = modules / "unpackfs.conf"
if not unpackfs.exists() or "/run/archiso/bootmnt/arch/x86_64/airootfs.sfs" not in unpackfs.read_text():
    raise SystemExit("A origem da imagem Forja no unpackfs.conf não foi encontrada.")
for required in ("packages_online.conf", "displaymanager.conf", "services-systemd.conf", "bootloader.conf", "grubcfg.conf", "shellprocess_forja_cleanup.conf"):
    if not (modules / required).exists():
        raise SystemExit(f"Módulo necessário ausente: {required}")
for config in (settings_offline, settings_online):
    data = config.read_text()
    for forbidden in ("packagechooser", "netinstall", "eos_pacman", "pacstrap", "eos_script", "cleaner_script"):
        if forbidden in data:
            raise SystemExit(f"Fluxo EndeavourOS não removido de {config.name}: {forbidden}")
    if "branding: forja" not in data or "  - unpackfs" not in data or "  - usersq" not in data:
        raise SystemExit(f"Fluxo Forja incompleto em {config.name}.")
for config in (settings_offline, settings_online):
    if "packages@online" not in config.read_text():
        raise SystemExit(f"{config.name} não executa a etapa de rede opcional.")
if "skip_if_no_internet: true" not in (modules / "packages_online.conf").read_text():
    raise SystemExit("A instalação sem internet não está protegida contra falha de rede.")
