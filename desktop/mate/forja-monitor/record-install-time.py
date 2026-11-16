#!/usr/bin/env python3
"""Grava uma única vez o instante real de conclusão da instalação da Forja OS.

O instalador deve executar este programa como root, imediatamente após concluir
a instalação no disco. Nunca chama este programa no primeiro boot.
"""
import argparse
import json
import os
import tempfile
from datetime import datetime
from pathlib import Path

DEFAULT_FILE = "/var/lib/forja-os/install-info.json"


def parse_timestamp(value):
    if value is None:
        return datetime.now().astimezone().isoformat(timespec="seconds")
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        raise ValueError("O timestamp precisa incluir fuso horário, por exemplo -03:00 ou Z.")
    return parsed.isoformat(timespec="seconds")


def record(root, timestamp):
    target = Path(root) / DEFAULT_FILE.lstrip("/")
    target.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(
        {"installed_at": timestamp, "format": 1},
        ensure_ascii=False,
        indent=2,
    ) + "\n"

    fd, temporary = tempfile.mkstemp(prefix=".install-info-", dir=str(target.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(payload)
            stream.flush()
            os.fchmod(stream.fileno(), 0o644)
            os.fsync(stream.fileno())
        # Hard-link creation is atomic and fails if the final marker already exists.
        os.link(temporary, target)
        directory_fd = os.open(target.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default="/", help="Raiz do sistema instalado (uso em testes).")
    parser.add_argument("--installed-at", help="Timestamp ISO 8601 com fuso, fornecido pelo instalador.")
    args = parser.parse_args()

    if os.geteuid() != 0:
        parser.error("Execute como root, no final da instalação.")
    try:
        timestamp = parse_timestamp(args.installed_at)
        target = record(args.root, timestamp)
    except FileExistsError:
        parser.error("O registro de instalação já existe. Ele não será sobrescrito.")
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    print(f"Data/hora de instalação registrada em {target}: {timestamp}")


if __name__ == "__main__":
    main()
