#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }

[[ -s "$ROOT/README.md" ]] || fail "README ausente"
grep -Fq 'Arch Linux oficial' "$ROOT/README.md" || fail "base Arch não registrada"
grep -Fq 'Archiso oficial' "$ROOT/README.md" || fail "Archiso não registrado"
grep -Fq 'MATE como único desktop' "$ROOT/README.md" || fail "MATE não registrado"
grep -Fq 'LightDM' "$ROOT/README.md" || fail "LightDM não registrado"
grep -Fq 'VENON' "$ROOT/README.md" || fail "separação do repositório VENON não registrada"

bash "$ROOT/scripts/validate-build.sh"
printf 'AVISO: escopo e sintaxe estática não comprovam ISO instalável.\n'
