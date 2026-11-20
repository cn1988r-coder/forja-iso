#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

required=(
  "$ROOT/build/profiledef.sh"
  "$ROOT/build/pacman.conf"
  "$ROOT/build/packages.x86_64"
  "$ROOT/build/packages.mate"
  "$ROOT/build/airootfs/etc/locale.conf"
  "$ROOT/build/airootfs/etc/locale.gen"
  "$ROOT/build/airootfs/etc/vconsole.conf"
  "$ROOT/build/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf"
  "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom"
  "$ROOT/scripts/build-venom-iso.sh"
  "$ROOT/scripts/build-container.sh"
  "$ROOT/installer/meson.build"
  "$ROOT/installer/src/main.c"
  "$ROOT/installer/README.md"
)

for file in "${required[@]}"; do
  [[ -f "$file" ]] || fail "arquivo necessário ausente: $file"
done

for script in "$ROOT"/scripts/*.sh "$ROOT"/build/profiledef.sh; do
  bash -n "$script" || fail "sintaxe inválida: $script"
done

# The dollar signs are literal Pacman variables in pacman.conf, not shell variables.
grep -Fq "Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch" "$ROOT/build/pacman.conf" || fail "mirror oficial Arch ausente"
grep -Fq 'LANG=pt_BR.UTF-8' "$ROOT/build/airootfs/etc/locale.conf" || fail "locale PT-BR ausente"
grep -Fq 'pt_BR.UTF-8 UTF-8' "$ROOT/build/airootfs/etc/locale.gen" || fail "locale pt_BR não habilitado"
grep -Fxq 'KEYMAP=br-abnt2' "$ROOT/build/airootfs/etc/vconsole.conf" || fail "teclado ABNT2 ausente"
grep -Fq 'Option "XkbLayout" "br"' "$ROOT/build/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf" || fail "layout X11 Brasil ausente"
grep -Fq 'Option "XkbVariant" "abnt2"' "$ROOT/build/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf" || fail "variante ABNT2 ausente"

for package in mate-session-manager mate-panel mate-applets blueman network-manager-applet mate-media; do
  grep -Fxq "$package" "$ROOT/build/packages.mate" || fail "pacote MATE ausente: $package"
done

grep -Fq "project('venom-installer', 'c'" "$ROOT/installer/meson.build" || fail "projeto Meson do instalador ausente"
grep -Fq 'gtk4' "$ROOT/installer/meson.build" || fail "dependência GTK4 ausente"
grep -Fq 'Instalação ainda bloqueada' "$ROOT/installer/src/main.c" || fail "bloqueio de segurança do protótipo ausente"
grep -Fq 'if: false' "$ROOT/.github/workflows/build-iso.yml" || fail "workflow de ISO não está bloqueado"

pass "arquivos obrigatórios e sintaxe dos scripts"
pass "Arch oficial, locale pt_BR.UTF-8 e teclado Brasil ABNT2"
pass "pacotes e indicadores MATE presentes"
pass "estrutura C + GTK4 presente; instalação continua bloqueada"
pass "workflow de compilação ISO permanece bloqueado"

printf 'PENDENTE: perfil Archiso completo, backend do instalador e testes em VM.\n'
printf 'ISO: nenhuma compilação executada por este validador.\n'
