#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }

grep -Fq 'Arch Linux oficial' "$ROOT/README.md" ||
  fail "base Arch Linux oficial não documentada"
grep -Fq 'MATE + LightDM' "$ROOT/README.md" ||
  fail "desktop único MATE + LightDM não documentado"
grep -Fq 'Português do Brasil' "$ROOT/README.md" ||
  fail "idioma único não documentado"
grep -Fq 'Brasil ABNT2' "$ROOT/README.md" ||
  fail "teclado ABNT2 não documentado"
grep -Fq 'C + GTK4' "$ROOT/README.md" ||
  fail "tecnologia do instalador não documentada"
grep -Fq 'offline' "$ROOT/README.md" ||
  fail "requisito de instalação offline não documentado"

"$ROOT/scripts/validate-build.sh"
