#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
grep -Fq 'Arch Linux oficial' "$ROOT/README.md" || fail "base Arch Linux oficial não documentada"
grep -Fq 'MATE' "$ROOT/README.md" || fail "desktop MATE não documentado"
grep -Fq 'LightDM' "$ROOT/README.md" || fail "LightDM não documentado"
grep -Fq 'Português do Brasil' "$ROOT/README.md" || fail "idioma padrão não documentado"
grep -Fq 'Brasil ABNT2' "$ROOT/README.md" || fail "teclado padrão não documentado"
grep -Fq 'C + GTK4' "$ROOT/README.md" || fail "tecnologia do instalador não documentada"
bash "$ROOT/scripts/validate-build.sh"
