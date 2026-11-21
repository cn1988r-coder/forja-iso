#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

for tool in pacman mkarchiso; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'ERRO: %s não encontrado. Use um ambiente Arch Linux com archiso instalado.\n' "$tool" >&2
    exit 1
  }
done

[[ -f build/profiledef.sh && -f build/packages.x86_64 ]] || {
  printf 'ERRO: perfil Archiso VENOM ausente ou incompleto.\n' >&2
  exit 1
}

[[ -x scripts/validate-arch-profile.sh ]] || chmod +x scripts/validate-arch-profile.sh
scripts/validate-arch-profile.sh

mkdir -p out work
printf '[VENOM] Construindo ISO com Archiso oficial.\n'
mkarchiso -v -w work -o out build

ISO="$(find out -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$ISO" ]] || {
  printf 'ERRO: Archiso terminou sem gerar arquivo ISO.\n' >&2
  exit 1
}
sha256sum "$ISO" | tee "$ISO.sha256"
printf '[VENOM] ISO criada: %s\n' "$ISO"
