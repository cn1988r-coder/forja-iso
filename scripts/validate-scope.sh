#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$ROOT/README.md"
AUDIT="$ROOT/docs/ENDEAVOUROS-AUDIT.md"

fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

[[ -f "$README" ]] || fail "README.md ausente"
[[ -f "$AUDIT" ]] || fail "auditoria do framework EndeavourOS ausente"

grep -Fq 'Base técnica:** Arch Linux' "$README" || fail "base Arch Linux não registrada"
grep -Fq 'componentes upstream do EndeavourOS' "$README" || fail "dependência upstream do framework não está documentada"
grep -Fq 'MATE como único ambiente gráfico' "$README" || fail "MATE único não registrado"
grep -Fq 'Materia Dark' "$README" || fail "Materia Dark não registrado"
grep -Fq 'Papirus' "$README" || fail "Papirus não registrado"
grep -Fq 'Bibata' "$README" || fail "Bibata não registrado"
grep -Fq 'identidade escura monocromática' "$README" || fail "identidade monocromática não registrada"
grep -Fq 'Firefox' "$README" || fail "Firefox não registrado"
grep -Fq 'Ferdium' "$README" || fail "Ferdium não registrado"
grep -Fq 'Shelly' "$README" || fail "Shelly não registrado"

if grep -Eiq 'Shellia|eos-settings-plasma|KDE Plasma' "$README"; then
  fail "README contém nome antigo ou desktop conflitante"
fi

grep -Fq 'Calamares' "$README" || fail "preservação do Calamares não registrada"
grep -Fiq 'Nenhuma ISO foi aprovada' "$README" || fail "estado de validação da ISO não está explícito"

pass "escopo da VENOM OS consistente"
pass "auditoria técnica do framework presente"
bash "$ROOT/scripts/validate-build.sh"
printf 'AVISO: esta checagem não compila nem testa uma ISO.\n'
