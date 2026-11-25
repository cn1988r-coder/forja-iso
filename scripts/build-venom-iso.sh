#!/usr/bin/env bash
# Explicit build entry point. Never called by static validation or on push.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Keep previous ISOs and validation logs; only the temporary work tree is disposable.
mkdir -p out

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

printf '[VENOM] Etapa 4/5: validação do payload Calamares antes do Archiso.\n'
bash scripts/test-calamares-ui.sh

printf '[VENOM] Ativando o serviço de preparação do ambiente Live no multi-user.target.\n'
install -d -m 0755 build/airootfs/etc/systemd/system/multi-user.target.wants
ln -sfn ../venom-live-setup.service build/airootfs/etc/systemd/system/multi-user.target.wants/venom-live-setup.service

printf '[VENOM] Etapa 5/5: geração da ISO com Archiso oficial.\n'
rm -rf work
mkdir -p work
BUILD_ID="$(date -u +%Y%m%dT%H%M%SZ)"
BUILD_OUT="$ROOT/out/venom-$BUILD_ID"
mkdir -p "$BUILD_OUT"
mkarchiso -v -w work -o "$BUILD_OUT" build

ISO="$(find "$BUILD_OUT" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$ISO" ]] || {
  printf 'ERRO: Archiso terminou sem gerar arquivo ISO.\n' >&2
  exit 1
}
sha256sum "$ISO" | tee "$ISO.sha256"
printf '[VENOM] ISO criada: %s\n' "$ISO"
