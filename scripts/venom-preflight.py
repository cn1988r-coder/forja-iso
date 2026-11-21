#!/usr/bin/env python3
"""Fail-closed static preflight audit for the VENOM OS Archiso repository."""
from __future__ import annotations
import argparse
import json
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FINDINGS = []
COUNTS = defaultdict(int)

def add(level, area, message, evidence=""):
    FINDINGS.append({"level": level, "area": area, "message": message, "evidence": evidence})
    COUNTS[level] += 1

def read(rel):
    try:
        return (ROOT / rel).read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        return None

def run(cmd):
    try:
        return subprocess.run(cmd, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, timeout=90)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return None

def require_file(rel, area="Estrutura"):
    p = ROOT / rel
    if not p.is_file() or p.stat().st_size == 0:
        add("ERROR", area, f"Arquivo obrigatório ausente ou vazio: {rel}")
        return False
    add("OK", area, f"Arquivo presente: {rel}")
    return True

def main():
    global ROOT
    parser = argparse.ArgumentParser(description="Auditoria pré-compilação completa da VENOM OS.")
    parser.add_argument("--json", action="store_true", help="Imprime o relatório em JSON.")
    parser.add_argument("--root", type=Path, default=ROOT, help=argparse.SUPPRESS)
    args = parser.parse_args()
    ROOT = args.root.resolve()

    required = [
        "AGENTS.md", "README.md", "build/profiledef.sh", "build/pacman.conf",
        "build/packages.x86_64", "build/install-packages.x86_64", "build/aur-packages.x86_64",
        "build/airootfs/etc/pamac.conf",
        "build/airootfs/usr/share/venom/pacman-install.conf",
        "build/airootfs/etc/pacman.conf", "build/airootfs/etc/mkinitcpio.conf.d/archiso.conf",
        "build/airootfs/etc/locale.conf", "build/airootfs/etc/locale.gen",
        "build/airootfs/etc/vconsole.conf", "build/airootfs/root/.bash_profile",
        "build/airootfs/usr/local/lib/venom/venom-live-setup",
        "build/airootfs/usr/local/lib/venom/venom-live-ready",
        "build/airootfs/etc/systemd/system/venom-live-setup.service",
        "build/airootfs/etc/systemd/system/venom-live-ready.service",
        "build/airootfs/etc/lightdm/lightdm.conf.d/50-venom-live.conf",
        "build/syslinux/syslinux.cfg", "build/syslinux/archiso_sys.cfg",
        "build/syslinux/archiso_head.cfg", "build/syslinux/archiso_sys-linux.cfg",
        "build/grub/grub.cfg",
        "installer/settings.conf", "scripts/validate-xfce-profile.sh",
        ".github/workflows/build-arch-iso.yml",
        ".github/workflows/validate-arch-xfce.yml"
    ]
    for item in required:
        require_file(item)

    # Archiso identity and boot configuration.
    profile = read("build/profiledef.sh") or ""
    for token, label in [
        ('iso_name="venom"', "identidade VENOM"),
        ('arch="x86_64"', "arquitetura x86_64"),
        ("bios.syslinux", "boot BIOS/Syslinux"),
        ("uefi.grub", "boot UEFI/GRUB"),
        ('packages="packages.x86_64"', "manifest live")
    ]:
        add("OK" if token in profile else "ERROR", "Archiso",
            f"Configuração presente: {label}" if token in profile else f"Configuração ausente: {label}")
    syslinux_main = read("build/syslinux/syslinux.cfg") or ""
    syscfg = read("build/syslinux/archiso_sys.cfg") or ""
    head = read("build/syslinux/archiso_head.cfg") or ""
    main_routes_to_system = bool(re.search(
        r"^\s*INCLUDE\s+archiso_sys\.cfg\s*$", syslinux_main, re.M))
    sys_includes_head = bool(re.search(
        r"^\s*INCLUDE\s+archiso_head\.cfg\s*$", syscfg, re.M))
    sys_includes_kernel = bool(re.search(
        r"^\s*INCLUDE\s+archiso_sys-linux\.cfg\s*$", syscfg, re.M))
    add("OK" if main_routes_to_system else "ERROR", "BIOS",
        "Ponto de entrada syslinux.cfg encaminha para archiso_sys.cfg"
        if main_routes_to_system else
        "syslinux.cfg ausente ou não encaminha para archiso_sys.cfg")
    add("OK" if sys_includes_head and sys_includes_kernel else "ERROR", "BIOS",
        "archiso_sys.cfg inclui cabeçalho e entradas de kernel"
        if sys_includes_head and sys_includes_kernel else
        "archiso_sys.cfg não inclui cabeçalho e/ou entradas de kernel")
    serial_in_header = head.splitlines()[:1] == ["SERIAL 0 115200"]
    serial_directives = []
    for rel, content in (
        ("syslinux.cfg", syslinux_main), ("archiso_sys.cfg", syscfg),
        ("archiso_head.cfg", head),
        ("archiso_sys-linux.cfg", read("build/syslinux/archiso_sys-linux.cfg") or "")
    ):
        for line_number, line in enumerate(content.splitlines(), 1):
            if re.match(r"^\s*SERIAL\b", line):
                serial_directives.append(f"{rel}:{line_number}: {line.strip()}")
    add("OK" if serial_in_header else "ERROR", "BIOS",
        "SERIAL 0 115200 está na primeira linha de archiso_head.cfg, conforme o perfil Archiso"
        if serial_in_header else
        "archiso_head.cfg não começa com SERIAL 0 115200")
    add("OK" if len(serial_directives) == 1 else "ERROR", "BIOS",
        "Uma única diretiva SERIAL no conjunto Syslinux"
        if len(serial_directives) == 1 else
        f"Esperada uma única diretiva SERIAL; encontradas {len(serial_directives)}",
        "\n".join(serial_directives))
    grub = read("build/grub/grub.cfg") or ""
    add("OK" if "archiso" in grub.lower() else "WARNING", "UEFI",
        "GRUB contém referência Archiso" if "archiso" in grub.lower()
        else "Não foi possível confirmar parâmetros Archiso no grub.cfg")

    # Package manifests and live/install separation.
    manifests = ["build/packages.x86_64", "build/install-packages.x86_64"]
    package_sets = {}
    for manifest in manifests:
        raw = read(manifest)
        if raw is None:
            continue
        names = [x.strip() for x in raw.splitlines()
                 if x.strip() and not x.lstrip().startswith("#")]
        duplicates = sorted({x for x in names if names.count(x) > 1})
        add("ERROR" if duplicates else "OK", "Pacotes",
            f"Duplicatas em {manifest}: {', '.join(duplicates)}" if duplicates
            else f"Manifesto sem duplicatas: {manifest} ({len(names)} pacotes)")
        package_sets[manifest] = set(names)
        for name in names:
            if not re.fullmatch(r"[A-Za-z0-9@._+:-]+", name):
                add("ERROR", "Pacotes", f"Entrada inválida em {manifest}: {name}")

    live = package_sets.get(manifests[0], set())
    installed = package_sets.get(manifests[1], set())
    aur_raw = read("build/aur-packages.x86_64") or ""
    aur_names = {x.strip() for x in aur_raw.splitlines() if x.strip() and not x.lstrip().startswith("#")}
    for name in {"libpamac-aur", "pamac-aur"}:
        add("OK" if name in aur_names and name in live and name in installed else "ERROR",
            "Pamac/AUR", f"Pacote AUR declarado para Live e instalação: {name}"
            if name in aur_names and name in live and name in installed
            else f"Pacote AUR ausente do manifesto AUR/Live/instalação: {name}")
    must_live = {"base", "linux", "linux-firmware", "archlinux-keyring",
                 "mkinitcpio-archiso", "syslinux", "grub", "xfce4", "xfce4-docklike-plugin",
                 "lightdm", "lightdm-gtk-greeter", "networkmanager",
                 "bluez", "pipewire"}
    must_install = {"base", "linux", "linux-firmware", "archlinux-keyring",
                    "grub", "efibootmgr", "xorg-server", "lightdm",
                    "xfce4", "xfce4-docklike-plugin", "networkmanager"}
    for name in sorted(must_live - live):
        add("ERROR", "Pacotes", f"Pacote obrigatório ausente no live: {name}")
    for name in sorted(must_install - installed):
        add("ERROR", "Pacotes", f"Pacote obrigatório ausente na instalação: {name}")
    for manifest, names in package_sets.items():
        forbidden_pkgs = names & {"manjaro", "endeavouros", "mhwd", "pamac-gtk", "biglinux"}
        if forbidden_pkgs:
            add("ERROR", "Arquitetura", f"Pacotes de outra distribuição em {manifest}: {', '.join(sorted(forbidden_pkgs))}")
    if installed & {"archiso", "mkinitcpio-archiso", "syslinux", "squashfs-tools",
                    "linux-headers", "linux-lts", "linux-lts-headers"}:
        add("WARNING", "Pacotes", "Manifesto de instalação contém pacotes normalmente exclusivos da mídia live")
    if shutil.which("pacman"):
        for manifest, names in package_sets.items():
            for name in sorted(names):
                if name in aur_names:
                    add("OK", "Pamac/AUR", f"Pacote AUR será compilado na pipeline: {name}")
                    continue
                result = run(["pacman", "-Si", name])
                if result is None:
                    add("INCONCLUSIVE", "Pacotes", f"Consulta de repositório inconclusiva: {name}")
                elif result.returncode:
                    group = run(["pacman", "-Sgq", name])
                    if group and group.returncode == 0 and group.stdout.strip():
                        add("OK", "Pacotes", f"Grupo oficial disponível: {name}")
                    else:
                        add("ERROR", "Pacotes", f"Pacote/grupo não encontrado nos repositórios configurados: {name}")
                else:
                    add("OK", "Pacotes", f"Pacote disponível: {name}")
    else:
        add("INCONCLUSIVE", "Pacotes", "pacman ausente; disponibilidade atual dos pacotes não foi consultada")

    # Locale, initramfs and Arch mirror configuration.
    locale = read("build/airootfs/etc/locale.conf") or ""
    locale_gen = read("build/airootfs/etc/locale.gen") or ""
    vconsole = read("build/airootfs/etc/vconsole.conf") or ""
    initramfs = read("build/airootfs/etc/mkinitcpio.conf.d/archiso.conf") or ""
    for ok, area, message in [
        ("LANG=pt_BR.UTF-8" in locale, "Idioma", "Locale pt_BR configurado"),
        ("pt_BR.UTF-8 UTF-8" in locale_gen, "Idioma", "Locale pt_BR habilitado"),
        ("KEYMAP=br-abnt2" in vconsole, "Teclado", "Layout br-abnt2 configurado"),
        ("archiso" in initramfs and "HOOKS=" in initramfs, "Initramfs", "Hooks Archiso presentes"),
        ('COMPRESSION="zstd"' in initramfs, "Initramfs", "Compressão initramfs zstd configurada"),
        ("geo.mirror.pkgbuild.com" in (read("build/pacman.conf") or ""), "Repositórios", "Mirror oficial Arch configurado no perfil"),
        ("geo.mirror.pkgbuild.com" in (read("build/airootfs/etc/pacman.conf") or ""), "Repositórios", "Mirror oficial Arch configurado no live"),
        ("EnableAUR = true" in (read("build/airootfs/etc/pamac.conf") or ""), "Pamac/AUR", "AUR habilitado no Pamac Live"),
        ("/usr/share/venom/aur-repo" in (read("build/airootfs/usr/share/venom/pacman-install.conf") or ""), "Pamac/AUR", "Repositório AUR temporário configurado apenas para pacstrap"),
        ("/usr/share/venom/aur-repo" not in (read("build/airootfs/etc/pacman.conf") or ""), "Pamac/AUR", "Pamac Live mantém somente fontes oficiais e AUR"),
        ("systemd.firstboot=headless" in profile, "Boot", "First boot headless configurado"),
        ("zstd" in profile and "squashfs" in profile.lower(), "Archiso", "SquashFS com compressão zstd configurado")
    ]:
        add("OK" if ok else "ERROR", area, message if ok else f"Configuração ausente: {message}")

    bash_profile = read("build/airootfs/root/.bash_profile") or ""
    add("OK" if "systemctl start venom-live-setup.service" in bash_profile and "/dev/tty1" in bash_profile
        else "ERROR", "Inicialização", "Setup live é disparado via systemd somente no tty1"
        if "systemctl start venom-live-setup.service" in bash_profile and "/dev/tty1" in bash_profile
        else "Dispatcher tty1/systemd ausente ou incompleto")

    # Obsolete startup path must not remain alongside the systemd-based dispatcher.
    for rel in ("build/airootfs/root/.automated_script.sh", "build/airootfs/root/venom-live-setup"):
        if (ROOT / rel).exists():
            add("ERROR", "Inicialização", f"Arquivo legado não utilizado permanece no perfil: {rel}")
        else:
            add("OK", "Inicialização", f"Sem arquivo legado: {rel}")

    # LightDM, user session and startup.
    lightdm = read("build/airootfs/etc/lightdm/lightdm.conf.d/50-venom-live.conf") or ""
    for line in ("greeter-session=lightdm-gtk-greeter", "user-session=xfce",
                 "autologin-user=venom", "autologin-user-timeout=0"):
        add("OK" if line in lightdm else "ERROR", "Login/LightDM",
            f"Configuração presente: {line}" if line in lightdm else f"Configuração ausente: {line}")

    # systemd unit structure and ordering cycles.
    unit_dir = ROOT / "build/airootfs/etc/systemd/system"
    units = {}
    if unit_dir.exists():
        for path in unit_dir.rglob("*.service"):
            text = path.read_text(errors="replace")
            units[path.name] = text
            valid = "[Unit]" in text and "[Service]" in text
            add("OK" if valid else "ERROR", "systemd",
                f"Unit válida: {path.name}" if valid else f"Unit sem seções [Unit]/[Service]: {path.name}")
            for executable in re.findall(r"^Exec(?:Start|StartPre|StartPost|Stop|Reload)=([^\s]+)", text, re.M):
                if executable.startswith("/") and not (ROOT / "build/airootfs" / executable.lstrip("/")).exists():
                    if executable == "/usr/bin/bash" and ("bash" in live or "base" in live):
                        add("OK", "systemd", f"Executável fornecido pelo pacote bash: {path.name}")
                    else:
                        add("WARNING", "systemd",
                            f"Executável pode vir de pacote (não está no overlay): {path.name}: {executable}")
    graph = defaultdict(set)
    for name, text in units.items():
        for key, value in re.findall(r"^(After|Before)=([^\n]+)", text, re.M):
            for dependency in value.split():
                if dependency.endswith(".service") and dependency in units:
                    graph[name].add(dependency) if key == "After" else graph[dependency].add(name)
    visiting, visited, cycle = set(), set(), []
    def visit(node, stack):
        if node in visiting:
            cycle.extend(stack[stack.index(node):] + [node])
            return
        if node in visited:
            return
        visiting.add(node)
        for dependency in graph[node]:
            visit(dependency, stack + [dependency])
        visiting.remove(node)
        visited.add(node)
    for node in graph:
        visit(node, [node])
    add("ERROR" if cycle else "OK", "systemd",
        "Possível ciclo de ordenação: " + " -> ".join(cycle) if cycle
        else "Nenhum ciclo detectado entre as units locais")

    setup_unit = units.get("venom-live-setup.service", "")
    ready_unit = units.get("venom-live-ready.service", "")
    setup_script = read("build/airootfs/usr/local/lib/venom/venom-live-setup") or ""
    if "Before=lightdm.service" in setup_unit and re.search(r"systemctl\s+start\s+lightdm\.service", setup_script) and "--no-block" not in setup_script:
        add("ERROR", "systemd", "Setup anterior ao LightDM tenta iniciá-lo sincronamente")
    if "After=lightdm.service" in ready_unit and "Requires=lightdm.service" in ready_unit:
        add("OK", "systemd", "Serviço de readiness aguarda LightDM")
    else:
        add("ERROR", "systemd", "Serviço de readiness não exige/aguarda LightDM")
    if "TimeoutStartSec=150" in ready_unit:
        add("OK", "systemd", "Timeout de readiness limitado a 150 segundos")
    else:
        add("ERROR", "systemd", "TimeoutStartSec=150 ausente na unit de readiness")

    # XFCE configuration and XML parsing.
    ready = read("build/airootfs/usr/local/lib/venom/venom-live-ready") or ""
    if "VENOM_LIVE_READY" in ready:
        add("OK", "Readiness", "Marcador VENOM_LIVE_READY presente")
    else:
        add("ERROR", "Readiness", "Marcador VENOM_LIVE_READY ausente")
    for process in ("xfce4-session", "xfce4-panel", "xfdesktop"):
        add("OK" if f"pgrep -u venom -x {process}" in ready else "ERROR", "XFCE",
            f"Readiness verifica {process}" if f"pgrep -u venom -x {process}" in ready
            else f"Readiness não verifica {process}")
    xfce_dir = ROOT / "build/airootfs/etc/skel/.config/xfce4"
    if xfce_dir.is_dir():
        xml_files = list(xfce_dir.rglob("*.xml"))
        if not xml_files:
            add("ERROR", "XFCE", "Nenhum XML de configuração XFCE encontrado em /etc/skel")
        for path in xml_files:
            try:
                ET.parse(path)
                add("OK", "XFCE", f"XML válido: {path.relative_to(ROOT)}")
            except ET.ParseError as exc:
                add("ERROR", "XFCE", f"XML inválido: {path.relative_to(ROOT)}", str(exc))
    else:
        add("ERROR", "XFCE", "Diretório de configuração XFCE em /etc/skel ausente")
    for item in (
        "build/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml",
        "build/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
    ):
        require_file(item, "XFCE")

    # VENOM Docklike Taskbar and panel identity.
    for rel in (
        "build/airootfs/etc/xdg/xfce4/panel/docklike.rc",
        "build/install-overlay/etc/xdg/xfce4/panel/docklike.rc",
    ):
        content = read(rel) or ""
        valid = ("pinned=firefox.desktop;thunar.desktop;" in content and
                 "indicatorColor=rgb(22,143,255)" in content)
        add("OK" if valid else "ERROR", "Docklike",
            f"Configuração Docklike presente: {rel}" if valid else
            f"Configuração Docklike ausente/incompleta: {rel}")
    for rel in (
        "build/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml",
        "build/install-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml",
    ):
        try:
            root = ET.fromstring(read(rel) or "")
            dock = root.find("./property[@name='plugins']/property[@name='plugin-11']")
            valid = dock is not None and dock.attrib.get("value") == "docklike"
        except ET.ParseError:
            valid = False
        add("OK" if valid else "ERROR", "Docklike",
            f"Docklike no nível correto do painel: {rel}" if valid else
            f"Docklike ausente ou aninhada incorretamente: {rel}")

    # Shell and Python syntax.
    shell_files = []
    for base in ("scripts", "build"):
        folder = ROOT / base
        if folder.exists():
            for path in folder.rglob("*"):
                if not path.is_file():
                    continue
                try:
                    first_line = path.open(encoding="utf-8", errors="ignore").readline().strip()
                except OSError:
                    continue
                if path.suffix == ".sh" or path.name in {".bash_profile", "venom-live-setup", "venom-live-ready"} or (first_line.startswith("#!") and "bash" in first_line):
                    shell_files.append(path)
    for path in shell_files:
        result = run(["bash", "-n", str(path)])
        add("OK" if result and result.returncode == 0 else "ERROR", "Scripts",
            f"Bash válido: {path.relative_to(ROOT)}" if result and result.returncode == 0
            else f"Erro de sintaxe Bash: {path.relative_to(ROOT)}",
            "" if result and result.returncode == 0 else (result.stdout if result else "bash indisponível/timeout"))
    python_files = list((ROOT / "installer").rglob("*.py")) if (ROOT / "installer").exists() else []
    for path in python_files:
        try:
            compile(path.read_text(encoding="utf-8"), str(path), "exec")
            add("OK", "Python", f"Python válido: {path.relative_to(ROOT)}")
        except (OSError, SyntaxError) as exc:
            add("ERROR", "Python", f"Erro de sintaxe Python: {path.relative_to(ROOT)}", str(exc))
    if shutil.which("shellcheck"):
        for path in shell_files:
            result = run(["shellcheck", "-S", "error", str(path)])
            if not result or result.returncode:
                add("ERROR", "ShellCheck", f"ShellCheck falhou: {path.relative_to(ROOT)}",
                    result.stdout if result else "ShellCheck indisponível/timeout")
    else:
        add("INCONCLUSIVE", "ShellCheck", "ShellCheck não instalado neste ambiente")

    # YAML syntax.
    try:
        import yaml
        for rel in (".github/workflows/build-arch-iso.yml",
                    ".github/workflows/validate-arch-xfce.yml", "installer/settings.conf"):
            text = read(rel)
            if text is None:
                continue
            try:
                yaml.safe_load(text)
                add("OK", "YAML", f"YAML válido: {rel}")
            except yaml.YAMLError as exc:
                add("ERROR", "YAML", f"YAML inválido: {rel}", str(exc))
    except ImportError:
        add("INCONCLUSIVE", "YAML", "PyYAML não instalado; sintaxe YAML não verificada")

    # Enforce the agreed Arch-only base while allowing the official, VENOM-branded Calamares installer.
    forbidden = re.compile(r"manjaro|endeavouros|mhwd|biglinux", re.I)
    hits = []
    for rel in ("build", "installer", ".github/workflows"):
        folder = ROOT / rel
        if not folder.exists():
            continue
        for path in folder.rglob("*"):
            if not path.is_file() or path.stat().st_size > 2_000_000:
                continue
            try:
                lines = path.read_text(errors="ignore").splitlines()
            except OSError:
                continue
            for number, line in enumerate(lines, 1):
                if forbidden.search(line):
                    hits.append(f"{path.relative_to(ROOT)}:{number}: {line.strip()[:180]}")
    add("ERROR" if hits else "OK", "Arquitetura",
        "Referências de outras distribuições na arquitetura ativa encontradas" if hits
        else "Nenhuma dependência de outras distribuições encontrada nas áreas auditadas",
        "\n".join(hits[:50]))
    # Calamares is the official upstream installer, branded for VENOM OS.
    build_workflow = read(".github/workflows/build-arch-iso.yml") or ""
    branding = read("installer/branding/branding.desc") or ""
    installer_module = read("installer/modules/venominstall/main.py") or ""
    pinned_calamres = "Build upstream Calamares 3.3.14" in build_workflow and "refs/tags/v3.3.14" in build_workflow
    add("OK" if pinned_calamres else "ERROR", "Instalador",
        "Calamares oficial 3.3.14 fixado no workflow" if pinned_calamres
        else "Calamares oficial 3.3.14 não está fixado no workflow")
    branded = "productName: VENOM OS" in branding and "sidebarBackground" in branding
    add("OK" if branded else "ERROR", "Identidade",
        "Branding VENOM OS do Calamares presente" if branded
        else "Branding VENOM OS do Calamares ausente")
    add("OK" if "pacstrap" in installer_module else "ERROR", "Instalador",
        "Módulo VENOM de instalação via pacstrap presente" if "pacstrap" in installer_module
        else "Módulo venominstall sem pacstrap")

    # VENON must remain isolated from Pacman and must not run automatically.
    venon_paths = ["build/airootfs/usr/bin/venon-upgrade", "build/airootfs/usr/bin/venon-update"]
    venon_contents = {}
    for rel in venon_paths:
        content = read(rel)
        if content is None:
            add("ERROR", "VENON", f"Comando obrigatório ausente: {rel}")
            continue
        venon_contents[rel] = content
        if re.search(r"\b(pacman|pacman-key|libalpm)\b", content):
            add("ERROR", "VENON", f"Comando VENON viola a separação do Pacman: {rel}")
        else:
            add("OK", "VENON", f"Sem chamadas ao Pacman/libalpm: {rel}")
    upgrade = venon_contents.get(venon_paths[0], "")
    update = venon_contents.get(venon_paths[1], "")
    if upgrade and re.search(r"\b(pacman|pacman-key|libalpm|install|upgrade-package)\b", upgrade):
        add("ERROR", "VENON", "venon-upgrade contém ação de instalação ou dependência proibida")
    if update and not re.search(r"confirmação explícita|confirm", update, re.I):
        add("WARNING", "VENON", "venon-update ainda não documenta confirmação explícita")
    systemd_dir = ROOT / "build/airootfs/etc/systemd/system"
    automatic = list(systemd_dir.glob("venon*.service")) + list(systemd_dir.glob("venon*.timer"))
    add("ERROR" if automatic else "OK", "VENON",
        "Serviço/timer VENON automático encontrado" if automatic
        else "Nenhum serviço ou timer VENON automático")

    # Security and workflow trigger protection.
    tty = read("build/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf") or ""
    if "--autologin root" in tty:
        add("WARNING", "Segurança", "TTY1 faz autologin root; confirmar que o console não fica exposto após iniciar LightDM")
    build_workflow = read(".github/workflows/build-arch-iso.yml") or ""
    guarded = re.search(r"paths:\s*\n\s*-\s*['\"]?\.github/trigger-final-build\.txt", build_workflow)
    add("OK" if guarded else "ERROR", "Workflows",
        "Build por push limitado ao arquivo de gatilho dedicado" if guarded
        else "Não foi possível confirmar proteção por gatilho dedicado")
    if re.search(r"^\s*workflow_dispatch:", build_workflow, re.M):
        add("WARNING", "Workflows", "Build permite disparo manual; exige autorização expressa")
    if (ROOT / ".github/trigger-final-build.txt").is_file():
        add("OK", "Workflows", "Arquivo de gatilho existe e não é alterado pelo preflight")

    # Static checks cannot prove real hardware/boot readiness.
    add("INCONCLUSIVE", "Boot real", "Boot BIOS/UEFI, LightDM, XFCE visível e interação precisam de teste da ISO em VM")
    add("INCONCLUSIVE", "Hardware", "GPU, Wi-Fi, áudio, Bluetooth e periféricos precisam de teste em hardware real")

    errors, warnings = COUNTS["ERROR"], COUNTS["WARNING"]
    inconclusive, passed = COUNTS["INCONCLUSIVE"], COUNTS["OK"]
    status = "REPROVADO" if errors else (
        "APROVADO COM RESSALVAS" if warnings or inconclusive else "APROVADO")
    report = {"project": "VENOM OS", "status": status,
              "summary": {"OK": passed, "WARNING": warnings,
                          "ERROR": errors, "INCONCLUSIVE": inconclusive},
              "findings": FINDINGS}
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print("\n=== VENOM OS | AUDITORIA PRÉ-COMPILAÇÃO ===")
        print(f"STATUS: {status}")
        print(f"VERDE {passed} | AMARELO {warnings} | VERMELHO {errors} | CINZA {inconclusive}\n")
        for finding in FINDINGS:
            marker = {"OK": "[VERDE]", "WARNING": "[AMARELO]",
                      "ERROR": "[VERMELHO]", "INCONCLUSIVE": "[CINZA]"}[finding["level"]]
            print(f'{marker} {finding["area"]}: {finding["message"]}')
            if finding["evidence"]:
                for line in finding["evidence"].splitlines():
                    print("       " + line)
        print("\n" + ("BLOQUEADO: corrija os erros e execute novamente."
                       if errors else "Pré-verificação estática concluída."))
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main())
