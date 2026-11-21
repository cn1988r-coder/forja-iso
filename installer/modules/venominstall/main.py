#!/usr/bin/env python3
"""Instala VENOM OS com pacstrap dos repositórios oficiais Arch."""

import os
import subprocess
import urllib.request
import libcalamares


def run():
    config = libcalamares.job.configuration
    root = libcalamares.globalstorage.value("rootMountPoint")
    if not root or not os.path.isdir(root):
        return ("Destino inválido", "Calamares não forneceu rootMountPoint válido.")
    if not os.path.ismount(root):
        return ("Partição raiz não montada", "Monte uma partição como raiz (/).")
    packages_file = config.get("packagesFile", "/usr/share/venom/packages.x86_64")
    if not os.path.isfile(packages_file):
        return ("Manifesto ausente", "Não foi encontrado o manifesto de pacotes VENOM.")
    probe = config.get("mirrorProbe", "https://geo.mirror.pkgbuild.com/core/os/x86_64/core.db")
    try:
        request = urllib.request.Request(probe, method="HEAD")
        with urllib.request.urlopen(request, timeout=20) as response:
            if response.status < 200 or response.status >= 400:
                raise RuntimeError("HTTP " + str(response.status))
    except Exception as exc:
        return ("Sem acesso aos repositórios oficiais Arch",
                "A instalação exige internet. Não haverá instalação offline nem cópia do sistema live. " + str(exc))
    with open(packages_file, encoding="utf-8") as stream:
        packages = [line.strip() for line in stream if line.strip() and not line.lstrip().startswith("#")]
    if not packages:
        return ("Manifesto vazio", "A lista de pacotes VENOM está vazia.")
    try:
        libcalamares.utils.debug("VENOM: iniciando pacstrap no destino " + root)
        subprocess.run(["pacstrap", "-K", "-C", "/etc/pacman.conf", root, *packages], check=True)
        os.makedirs(os.path.join(root, "etc"), exist_ok=True)
        subprocess.run(["install", "-m", "0644", "/etc/pacman.conf",
                        os.path.join(root, "etc/pacman.conf")], check=True)
    except subprocess.CalledProcessError as exc:
        return ("Falha no pacstrap", "A instalação dos pacotes oficiais falhou. Código: " + str(exc.returncode))
    return None
