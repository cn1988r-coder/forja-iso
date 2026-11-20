#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

for path in \
  Dockerfile \
  build/archiso/profiledef.sh \
  build/archiso/packages.x86_64 \
  build/archiso/pacman.conf \
  build/archiso/airootfs/etc/os-release \
  scripts/build-venom-iso.sh \
  scripts/build-container.sh; do
  [[ -s "$ROOT/$path" ]] || fail "arquivo obrigatório ausente: $path"
done

grep -Fq 'FROM archlinux:latest' "$ROOT/Dockerfile" || fail "container não usa Arch Linux oficial"
grep -Fq '/usr/share/archiso/configs/releng' "$ROOT/scripts/build-venom-iso.sh" || fail "perfil oficial Archiso não é usado como origem"
grep -Fq 'mkarchiso -v' "$ROOT/scripts/build-venom-iso.sh" || fail "mkarchiso oficial não é chamado"
grep -Fq 'ID_LIKE=arch' "$ROOT/build/archiso/airootfs/etc/os-release" || fail "identidade da base Arch ausente"
grep -Fq 'iso_name="venom"' "$ROOT/build/archiso/profiledef.sh" || fail "nome da ISO não é VENOM"

if grep -Eiq 'endeavouros|data/eos|EndeavourOS' \
  "$ROOT/Dockerfile" \
  "$ROOT/scripts/build-venom-iso.sh" \
  "$ROOT/scripts/build-container.sh" \
  "$ROOT/build/archiso/pacman.conf" \
  "$ROOT/build/archiso/packages.x86_64"; then
  fail "dependência antiga encontrada no caminho de construção"
fi

if grep -Eiq '^(endeavouros-|eos-)' "$ROOT/build/packages.arch" "$ROOT/build/packages.mate"; then
  fail "manifesto VENOM contém pacote da distribuição anterior"
fi

pass "perfil Archiso próprio e caminho de build direto definidos"
printf 'AVISO: esta verificação estática não compila a ISO nem valida boot ou instalação.\n'
