#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="forja-os-iso-builder"

if command -v docker >/dev/null 2>&1; then
  ENGINE="docker"
elif command -v podman >/dev/null 2>&1; then
  ENGINE="podman"
else
  printf 'ERRO: instale Docker ou Podman para usar o ambiente de compilação isolado.\n' >&2
  exit 1
fi

AVAILABLE_KIB="$(df -Pk "$ROOT" | awk 'NR==2 {print $4}')"
REQUIRED_KIB=$((40 * 1024 * 1024))
if [[ -z "$AVAILABLE_KIB" || "$AVAILABLE_KIB" -lt "$REQUIRED_KIB" ]]; then
  printf 'ERRO: são necessários pelo menos 40 GiB livres no disco do projeto.\n' >&2
  exit 1
fi

printf '[FORJA] Construindo ambiente Arch + repositórios EndeavourOS...\n'
"$ENGINE" build -t "$IMAGE" "$ROOT"

printf '[FORJA] Iniciando compilação dentro do container...\n'
"$ENGINE" run --rm --privileged \
  --user 1000:1000 \
  -v "$ROOT:/workspace" \
  -w /workspace \
  "$IMAGE"
