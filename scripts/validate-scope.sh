#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$ROOT/README.md"
AUDIT="$ROOT/docs/ENDEAVOUROS-AUDIT.md"

fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

[[ -f "$README" ]] || fail "README.md ausente"
[[ -f "$AUDIT" ]] || fail "auditoria do framework EndeavourOS ausente"

grep -Fq 'EndeavourOS Linux' "$README" || fail "base EndeavourOS não registrada"
grep -Fq 'MATE como único ambiente gráfico' "$README" || fail "MATE único não registrado"
grep -Fq 'Materia Dark' "$README" || fail "Materia Dark não registrado"
grep -Fq 'Papirus' "$README" || fail "Papirus não registrado"
grep -Fq 'Bibata' "$README" || fail "Bibata não registrado"
grep -Fq 'preto puro (#000000)' "$README" || fail "fundo preto não registrado"
grep -Fq 'Firefox' "$README" || fail "Firefox não registrado"
grep -Fq 'Ferdium' "$README" || fail "Ferdium não registrado"
grep -Fq 'Shelly' "$README" || fail "Shelly não registrado"

if grep -Eiq 'Shellia|eos-settings-plasma|KDE Plasma' "$README"; then
  fail "README contém nome antigo ou desktop conflitante"
fi

grep -Fq 'Calamares' "$README" || fail "preservação do Calamares não registrada"
grep -Fq 'nenhuma ISO foi compilada' "$README" || fail "estado de compilação não está explícito"

pass "escopo da Forja OS consistente"
pass "auditoria técnica do framework presente"
printf 'AVISO: esta checagem não compila nem testa uma ISO.\n'
