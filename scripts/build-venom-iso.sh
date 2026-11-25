#!/usr/bin/env bash
# Explicit build entry point. Never called by static validation or on push.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ $EUID -ne 0 ]]; then
  command -v sudo >/dev/null 2>&1 || { echo "É necessário root ou sudo." >&2; exit 1; }
  exec sudo -E bash "$0" "$@"
fi

for tool in pacman mkarchiso git cmake ninja repo-add; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'ERRO: %s não encontrado no ambiente Arch de construção.\n' "$tool" >&2
    exit 1
  }
done

[[ -s build/profiledef.sh && -s build/packages.x86_64 ]] || {
  printf 'ERRO: perfil Archiso VENOM ausente ou incompleto.\n' >&2
  exit 1
}

printf '[VENOM] Etapa 1/4: validação estática do perfil.\n'
bash scripts/validate-xfce-profile.sh

printf '[VENOM] Etapa 2/4: preparação dos pacotes AUR declarados.\n'
bash scripts/build-aur-packages.sh

printf '[VENOM] Etapa 3/4: preparação do instalador Calamares e payload.\n'
bash scripts/stage-installer-payload.sh

printf '[VENOM] Etapa 4/5: teste gráfico do Calamares em Xvfb.\n'
bash scripts/test-calamares-ui.sh

printf '[VENOM] Etapa 5/5: geração da ISO com Archiso oficial.\n'
rm -rf out work
mkdir -p out work
mkarchiso -v -w work -o out build

ISO="$(find out -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$ISO" ]] || {
  printf 'ERRO: Archiso terminou sem gerar arquivo ISO.\n' >&2
  exit 1
}
sha256sum "$ISO" | tee "$ISO.sha256"
printf '[VENOM] ISO criada: %s\n' "$ISO"
