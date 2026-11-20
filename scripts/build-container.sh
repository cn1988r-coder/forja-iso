#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="venom-os-validator"
if command -v docker >/dev/null 2>&1; then ENGINE=docker; elif command -v podman >/dev/null 2>&1; then ENGINE=podman; else printf 'ERRO: Docker ou Podman não encontrado.\n' >&2; exit 1; fi
printf '[VENOM] Construindo ambiente baseado somente no Arch Linux oficial.\n'
"$ENGINE" build -t "$IMAGE" "$ROOT"
printf '[VENOM] Executando somente validações estáticas. Nenhuma ISO será gerada.\n'
"$ENGINE" run --rm -v "$ROOT:/workspace:ro" -w /workspace "$IMAGE"
