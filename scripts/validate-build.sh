#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

for file in \
  "$ROOT/scripts/build-forja-iso.sh" \
  "$ROOT/build/packages.mate" \
  "$ROOT/build/airootfs/etc/dconf/profile/user" \
  "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja" \
  "$ROOT/build/airootfs/etc/lightdm/lightdm.conf.d/10-forja-live.conf" \
  "$ROOT/build/airootfs/etc/skel/.config/gtk-3.0/settings.ini" \
  "$ROOT/build/airootfs/etc/skel/.config/gtk-4.0/settings.ini"; do
  [[ -f "$file" ]] || fail "arquivo necessário ausente: $file"
done

bash -n "$ROOT/scripts/build-forja-iso.sh" || fail "erro de sintaxe no script de compilação"

grep -Fq 'EOS_COMMIT="90376d8f52ab19e19073eed33d6f36c46ec7c409"' "$ROOT/scripts/build-forja-iso.sh" || fail "framework EndeavourOS sem revisão fixada"
grep -Fq 'PKGBUILDS_COMMIT="474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd"' "$ROOT/scripts/build-forja-iso.sh" || fail "receita Calamares sem revisão fixada"
grep -Fq 'SHELLY_COMMIT="6840658b19d72205c38bd320c1cef6ff3076bc7c"' "$ROOT/scripts/build-forja-iso.sh" || fail "Shelly sem revisão fixada"

grep -Fxq 'mate-session-manager' "$ROOT/build/packages.mate" || fail "pacote MATE ausente"
grep -Fxq 'lightdm' "$ROOT/build/packages.mate" || fail "LightDM ausente"
grep -Fxq 'materia-gtk-theme' "$ROOT/build/packages.mate" || fail "Materia ausente"
grep -Fxq 'papirus-icon-theme' "$ROOT/build/packages.mate" || fail "Papirus ausente"
grep -Fq "picture-filename=''" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja" || fail "configuração de fundo vazio ausente"
grep -Fq "primary-color='#000000'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja" || fail "fundo preto não configurado"

if grep -Eiq '^(plasma|kde|sddm|dolphin|konsole)(-|$)' "$ROOT/build/packages.mate"; then
  fail "pacotes KDE encontrados na lista MATE"
fi

pass "arquivos e escopo do build presentes"
pass "sintaxe Bash do compilador válida"
printf 'AVISO: esta validação estática não executa makepkg, mkarchiso ou testes de VM.\n'
