#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="venom-os-archiso-builder"

if command -v docker >/dev/null 2>&1; then
  ENGINE="docker"
elif command -v podman >/dev/null 2>&1; then
  ENGINE="podman"
else
  printf 'ERRO: instale Docker ou Podman para usar o ambiente isolado.\n' >&2
  exit 1
fi

AVAILABLE_KIB="$(df -Pk "$ROOT" | awk 'NR==2 {print $4}')"
REQUIRED_KIB=$((40 * 1024 * 1024))
if [[ -z "$AVAILABLE_KIB" || "$AVAILABLE_KIB" -lt "$REQUIRED_KIB" ]]; then
  printf 'ERRO: são necessários pelo menos 40 GiB livres no disco.\n' >&2
  exit 1
fi

printf '[VENOM] Construindo ambiente baseado somente nos repositórios oficiais Arch Linux...\n'
"$ENGINE" build \
  --build-arg BUILD_UID="$(id -u)" \
  --build-arg BUILD_GID="$(id -g)" \
  -t "$IMAGE" "$ROOT"

printf '[VENOM] Compilando a ISO com o mkarchiso oficial...\n'
"$ENGINE" run --rm --privileged \
  --user "$(id -u):$(id -g)" \
  -v "$ROOT:/workspace" \
  -w /workspace \
  "$IMAGE"
