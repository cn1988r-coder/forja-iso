#!/usr/bin/env python3
"""Aplica BTRFS + Timeshift + GRUB ao Arch Linux instalado pela VENOM OS."""

import os
import shlex
import subprocess

import libcalamares


def resolve_block_device(source):
    """Resolve UUID/LABEL specifications and accepts an existing /dev node."""
    if source.startswith("/dev/"):
        device = os.path.realpath(source)
        if os.path.exists(device):
            return device
        raise RuntimeError("Dispositivo da raiz não existe: " + source)

    if source.startswith("UUID="):
        command = ["blkid", "-U", source[5:]]
    elif source.startswith("LABEL="):
        command = ["blkid", "-L", source[6:]]
    elif source.startswith("PARTUUID="):
        command = ["blkid", "-t", source, "-o", "device"]
    elif source.startswith("PARTLABEL="):
        command = ["blkid", "-t", source, "-o", "device"]
    else:
        raise RuntimeError("Identificador de dispositivo não reconhecido: " + source)

    result = subprocess.run(
        command, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ).stdout.strip().splitlines()
    if not result:
        raise RuntimeError("Não foi possível resolver o dispositivo: " + source)
    device = os.path.realpath(result[0])
    if not os.path.exists(device):
        raise RuntimeError("Dispositivo resolvido não existe: " + device)
    return device


def run():
    config = libcalamares.job.configuration
    root = libcalamares.globalstorage.value("rootMountPoint")
    if not root or not os.path.isdir(root):
        return ("Destino inválido", "Calamares não forneceu rootMountPoint válido.")

    fstab = os.path.join(root, "etc", "fstab")
    if not os.path.isfile(fstab):
        return ("fstab ausente", "Não foi possível localizar o fstab do Arch instalado.")

    root_source = None
    root_type = None
    with open(fstab, encoding="utf-8") as stream:
        for line in stream:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            try:
                fields = shlex.split(stripped)
            except ValueError:
                continue
            if len(fields) >= 3 and fields[1] == "/":
                root_source, root_type = fields[0], fields[2]
                break

    if root_type != "btrfs" or not root_source:
        return (
            "Raiz não é BTRFS",
            "A integração Timeshift exige que a partição raiz do Arch Linux use BTRFS.",
        )

    script = config.get(
        "setupScript", "/usr/share/venom/setup-arch-btrfs-timeshift-grub.sh"
    )
    if not os.path.isfile(script):
        return ("Script ausente", "O script de integração BTRFS não foi incluído na mídia live.")

    try:
        device = resolve_block_device(root_source)
        libcalamares.utils.debug(
            "VENOM: aplicando integração BTRFS + Timeshift + GRUB ao Arch instalado."
        )
        subprocess.run(["bash", script, root, device], check=True)
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        return (
            "Falha na integração BTRFS",
            "Não foi possível configurar Timeshift e GRUB no Arch Linux instalado. "
            + str(exc),
        )

    return None
