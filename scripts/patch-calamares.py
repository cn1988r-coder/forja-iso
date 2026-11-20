#!/usr/bin/env python3
"""Apply the VENOM OS branding and focused users-step fixes to pinned Calamares."""
from pathlib import Path
import re
import sys

source = Path(sys.argv[1])
branding = Path(__file__).resolve().parent / "branding/venom"
target_branding = source / "data/eos/branding/venom"
target_branding.mkdir(parents=True, exist_ok=True)
for item in branding.iterdir():
    if item.is_file():
        (target_branding / item.name).write_bytes(item.read_bytes())

settings = source / "data/eos/settings_offline.conf"
text = settings.read_text()
if "branding: endeavouros" not in text:
    raise SystemExit("Branding upstream esperado não encontrado em settings_offline.conf.")
settings.write_text(text.replace("branding: endeavouros", "branding: venom", 1))

# Bind pkexec's Calamares action to the VENOM wrapper, which fixes Qt's display backend.
policy = source / "com.github.calamares.calamares.policy"
if not policy.exists():
    raise SystemExit("Polkit action policy for Calamares is missing.")
policy_text = policy.read_text()
old_policy_path = '<annotate key="org.freedesktop.policykit.exec.path">/usr/bin/calamares</annotate>'
new_policy_path = '<annotate key="org.freedesktop.policykit.exec.path">/usr/bin/venom-calamares</annotate>'
if old_policy_path not in policy_text:
    raise SystemExit("Expected Calamares pkexec executable path was not found.")
policy.write_text(policy_text.replace(old_policy_path, new_policy_path, 1))

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


# Both installation modes deploy the exact VENOM OS filesystem shipped in this ISO.
# Online mode then applies a full update from official Arch repositories.
packages_arch = branding.parent / "packages.arch"
packages_mate = branding.parent / "packages.mate"
if not packages_arch.is_file() or not packages_mate.is_file():
    raise SystemExit("Manifestos de pacotes Arch/VENOM ausentes para o instalador online.")

def read_packages(path):
    return [line.strip() for line in path.read_text().splitlines()
            if line.strip() and not line.lstrip().startswith("#")]

arch_packages = read_packages(packages_arch)
mate_packages = read_packages(packages_mate)
online_packages = list(dict.fromkeys(arch_packages + mate_packages))
required_kernel_packages = {"linux", "linux-headers", "linux-lts", "linux-lts-headers"}
for manifest_name, manifest in (("build/packages.arch", arch_packages), ("build/packages.mate", mate_packages)):
    missing_kernels = sorted(required_kernel_packages - set(manifest))
    if missing_kernels:
        raise SystemExit(f"Manifesto {manifest_name} sem pacotes de kernel obrigatórios: {', '.join(missing_kernels)}")
if not online_packages or any(not re.fullmatch(r"[a-zA-Z0-9@._+-]+", p) for p in online_packages):
    raise SystemExit("Manifesto online contém nome de pacote vazio ou inválido.")
if any(p.startswith(("eos-", "endeavouros-")) for p in online_packages):
    raise SystemExit("O manifesto online não pode instalar pacotes EndeavourOS.")

settings_offline_text = """# VENOM OS offline: copia a imagem completa da própria ISO.
---
modules-search: [ local ]
instances:
- id: venom_sudoers
  module: shellprocess
  config: shellprocess_venom_sudoers.conf
- id: venom_grub_defaults
  module: shellprocess
  config: shellprocess_venom_grub_defaults.conf
- id: venom_cleanup
  module: shellprocess
  config: shellprocess_venom_cleanup.conf
sequence:
- show:
  - usersq
  - partition
  - summary
- exec:
  - partition
  - mount
  - unpackfs
  - machineid
  - fstab
  - removeuser
  - usersq
  - shellprocess@venom_sudoers
  - networkcfg
  - displaymanager
  - hwclock
  - shellprocess@venom_grub_defaults
  - bootloader
  - services-systemd
  - preservefiles
  - shellprocess@venom_cleanup
  - umount
- show:
  - finished
branding: venom
prompt-install: true
dont-chroot: false
oem-setup: false
disable-cancel: false
disable-cancel-during-exec: false
hide-back-and-next-during-exec: true
quit-at-end: false
"""

settings_online_text = """# VENOM OS online: deploys the VENOM image, then updates it from official Arch repositories.
---
modules-search: [ local ]
instances:
- id: venom_welcome
  module: welcome
  config: welcome_venom_online.conf
- id: online
  module: packages
  config: packages_online.conf
- id: venom_sudoers
  module: shellprocess
  config: shellprocess_venom_sudoers.conf
- id: venom_grub_defaults
  module: shellprocess
  config: shellprocess_venom_grub_defaults.conf
- id: venom_cleanup
  module: shellprocess
  config: shellprocess_venom_cleanup.conf
sequence:
- show:
  - welcome@venom_welcome
  - locale
  - keyboard
  - usersq
  - partition
  - summary
- exec:
  - partition
  - mount
  - unpackfs
  - machineid
  - locale
  - keyboard
  - localecfg
  - fstab
  - removeuser
  - usersq
  - shellprocess@venom_sudoers
  - networkcfg
  - packages@online
  - displaymanager
  - hwclock
  - shellprocess@venom_grub_defaults
  - bootloader
  - services-systemd
  - preservefiles
  - shellprocess@venom_cleanup
  - umount
- show:
  - finished
branding: venom
prompt-install: true
dont-chroot: false
oem-setup: false
disable-cancel: false
disable-cancel-during-exec: false
hide-back-and-next-during-exec: true
quit-at-end: false
"""

modules = source / "data/eos/modules"
settings_offline = source / "data/eos/settings_offline.conf"
settings_online = source / "data/eos/settings_online.conf"
settings_offline.write_text(settings_offline_text)
settings_online.write_text(settings_online_text)

packages_config = source / "data/eos/modules/packages_online.conf"
packages_config.write_text(
    "---\n"
    "backend: pacman\n"
    "skip_if_no_internet: false\n"
    "update_db: true\n"
    "update_system: true\n"
    "pacman:\n"
    "  num_retries: 6\n"
    "  disable_download_timeout: true\n"
    "  needed_only: true\n"
    "operations:\n"
    "  - install:\n" +
    "".join(f"      - {package}\n" for package in online_packages)
)

welcome_config = source / "data/eos/modules/welcome_venom_online.conf"
welcome_config.write_text("""---
showSupportUrl: false
showKnownIssuesUrl: false
showReleaseNotesUrl: false
showDonateUrl: false
requirements:
  requiredStorage: 20
  requiredRam: 2
  internetCheckUrl:
    - https://archlinux.org/
    - https://kernel.org/
  check:
    - storage
    - ram
    - internet
    - root
    - screen
  required:
    - ram
    - internet
geoip:
  style: "none"
  url: "https://geoip.kde.org/v1/ubiquity"
  selector: "CountryCode"
""")

(modules / "shellprocess_venom_sudoers.conf").write_text("""---
dontChroot: false
timeout: 30
verbose: true
script:
  - "install -d -m 0750 /etc/sudoers.d"
  - "echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-venom-wheel"
  - "chmod 0440 /etc/sudoers.d/10-venom-wheel"
  - "visudo -cf /etc/sudoers"
""")
(modules / "shellprocess_venom_cleanup.conf").write_text("""---
dontChroot: false
timeout: 180
verbose: true
script:
  - 'if pacman -Q calamares >/dev/null 2>&1; then pacman -Rdd --noconfirm calamares; fi'
  - 'packages=$(pacman -Qq | grep -E "^(endeavouros-|eos-|yay$|rate-mirrors$|reflector-simple$|welcome$|iso-create-ml$)" || true); if [ -n "$packages" ]; then pacman -Rdd --noconfirm $packages; fi'
  - 'remaining=$(pacman -Qq | grep -E "^(endeavouros-|eos-)" || true); if [ -n "$remaining" ]; then printf "Pacotes EndeavourOS/EOS ainda instalados: %s\\n" "$remaining" >&2; exit 1; fi'
  - 'if grep -Eiq "endeavouros|eos-" /etc/pacman.conf; then echo "Configuração de repositórios EndeavourOS/EOS encontrada." >&2; exit 1; fi'
  - 'rm -rf /etc/calamares /usr/share/calamares /usr/lib/calamares /usr/share/endeavouros /usr/share/eos /usr/share/venom/packages'
  - 'rm -f /etc/pacman.d/endeavouros-mirrorlist /usr/lib/endeavouros-release /etc/polkit-1/rules.d/49-venom-calamares.rules'
""")


# Keep partitioning safe and independent of the removed package/bootloader chooser.
partition_config = modules / "partition.conf"
partition_text = partition_config.read_text()
partition_text, removed = re.subn(r"(?m)^efiBootLoaderVar:.*\n", "", partition_text, count=1)
if removed != 1:
    raise SystemExit("A referência obsoleta ao seletor de bootloader não foi encontrada em partition.conf.")
partition_text, fs_count = re.subn(
    r"(?m)^availableFileSystemTypes:\s+\[.*\]$",
    'availableFileSystemTypes:  ["ext4"]',
    partition_text,
    count=1,
)
if fs_count != 1:
    raise SystemExit("A lista de sistemas de arquivos de partition.conf mudou inesperadamente.")
partition_text = partition_text.replace("recommendedSize:    2048MiB", "recommendedSize:    512MiB", 1)
partition_text = partition_text.replace("minimumSize:        500MiB", "minimumSize:        300MiB", 1)
partition_text = partition_text.replace('name: "endeavouros"', 'name: "venom"', 1)
partition_config.write_text(partition_text)

# Fixed VENOM boot policy: no desktop/package/bootloader chooser.
modules = source / "data/eos/modules"
(modules / "bootloader.conf").write_text("""---
# No bootloader chooser is shown. Always install GRUB on BIOS and UEFI systems.
efiBootLoader: "grub"
kernelSearchPath: "/usr/lib/modules"
kernelPattern: "^vmlinuz.*"
kernelParams: [ "quiet", "loglevel=3" ]
refindKernelList: [ "linux" ]
efiBootloaderId: "VENOM OS"
grubInstall: "grub-install"
grubMkconfig: "grub-mkconfig"
grubCfg: "/boot/grub/grub.cfg"
grubProbe: "grub-probe"
efiBootMgr: "efibootmgr"
installEFIFallback: true
""")
# grubcfg is intentionally omitted: upstream requires packagechooser_bootloader global storage.
(modules / "displaymanager.conf").write_text("""---
displaymanagers:
  - lightdm
basicSetup: false
sysconfigSetup: false
""")
(modules / "shellprocess_venom_grub_defaults.conf").write_text("""---
dontChroot: false
timeout: 30
verbose: true
script:
  - "install -d -m 0755 /etc/default"
  - |
    cat > /etc/default/grub <<'GRUB'
    GRUB_DEFAULT="VENOM OS, with Linux linux-lts"
    GRUB_TIMEOUT=5
    GRUB_DISTRIBUTOR="VENOM OS"
    GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3"
    GRUB_CMDLINE_LINUX=""
    GRUB_DISABLE_SUBMENU=true
    GRUB_DISABLE_RECOVERY=true
    GRUB_EARLY_INITRD_LINUX_STOCK=""
    GRUB
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
    raise SystemExit("A origem da imagem VENOM no unpackfs.conf não foi encontrada.")
for required in ("displaymanager.conf", "services-systemd.conf", "bootloader.conf", "grubcfg.conf", "removeuser.conf", "shellprocess_venom_cleanup.conf", "shellprocess_venom_sudoers.conf", "shellprocess_venom_grub_defaults.conf", "packages_online.conf", "welcome_venom_online.conf"):
    if not (modules / required).exists():
        raise SystemExit(f"Módulo necessário ausente: {required}")
for config in (settings_offline, settings_online):
    data = config.read_text()
    for forbidden in ("packagechooser", "netinstall", "eos_pacman", "pacstrap", "eos_script", "cleaner_script"):
        if forbidden in data:
            raise SystemExit(f"Fluxo EndeavourOS não removido de {config.name}: {forbidden}")
    if "branding: venom" not in data or "  - usersq" not in data or "  - bootloader" not in data:
        raise SystemExit(f"Fluxo VENOM incompleto em {config.name}.")
if "  - unpackfs" not in settings_offline.read_text():
    raise SystemExit("O instalador offline deve copiar a imagem da ISO.")
if "  - unpackfs" not in settings_online.read_text():
    raise SystemExit("O instalador online deve copiar a imagem VENOM OS da própria ISO.")
if "  - packages@online" not in settings_online.read_text():
    raise SystemExit("O instalador online não atualiza a VENOM OS pelos repositórios Arch.")
if "  - removeuser" not in settings_online.read_text():
    raise SystemExit("O instalador online deve remover o usuário temporário da sessão Live.")
if "update_system: true" not in packages_config.read_text():
    raise SystemExit("O modo online deve atualizar a instalação VENOM já copiada.")
cleanup_text = (modules / "shellprocess_venom_cleanup.conf").read_text()
if "remaining=$(pacman -Qq | grep -E" not in cleanup_text or "grep -Eiq \"endeavouros|eos-\" /etc/pacman.conf" not in cleanup_text:
    raise SystemExit("A limpeza final deve bloquear pacotes e repositórios EndeavourOS/EOS remanescentes.")
if "pacstrap" in settings_online.read_text():
    raise SystemExit("O modo online não pode criar um Arch genérico com pacstrap.")
if "packages@online" in settings_offline.read_text():
    raise SystemExit("O instalador offline não pode depender de internet.")
if "  - internet" not in welcome_config.read_text() or "    - internet" not in welcome_config.read_text():
    raise SystemExit("O fluxo online precisa exigir conectividade real.")
if "backend: pacman" not in packages_config.read_text():
    raise SystemExit("O instalador online não usa Pacman/Arch.")
partition_data = partition_config.read_text()
if "efiBootLoaderVar:" in partition_data:
    raise SystemExit("partition.conf ainda depende do seletor de bootloader removido.")
if 'availableFileSystemTypes:  ["ext4"]' not in partition_data:
    raise SystemExit("A instalação VENOM deve usar ext4 como único sistema de arquivos selecionável.")
if 'efiBootLoader: "grub"' not in (modules / "bootloader.conf").read_text():
    raise SystemExit("GRUB não está definido como bootloader fixo.")
if "packages@online" in settings_offline.read_text():
    raise SystemExit("A instalação offline não pode depender de internet.")
for inherited in ("locale", "keyboard", "localecfg"):
    if f"  - {inherited}" + chr(10) in settings_offline.read_text():
        raise SystemExit(f"Idioma e teclado offline devem ser herdados da imagem Live: {inherited}")
