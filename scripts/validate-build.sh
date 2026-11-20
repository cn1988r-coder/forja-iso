#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }
required=(
 "$ROOT/build/profiledef.sh" "$ROOT/build/pacman.conf" "$ROOT/build/packages.x86_64"
 "$ROOT/build/packages.mate" "$ROOT/build/airootfs/etc/locale.conf"
 "$ROOT/build/airootfs/etc/locale.gen" "$ROOT/build/airootfs/etc/vconsole.conf"
 "$ROOT/build/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf"
 "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom"
 "$ROOT/scripts/build-venom-iso.sh" "$ROOT/scripts/build-container.sh"
)
for file in "${required[@]}"; do [[ -f "$file" ]] || fail "arquivo necessário ausente: $file"; done
bash -n "$ROOT/scripts/build-venom-iso.sh"
bash -n "$ROOT/scripts/build-container.sh"
bash -n "$ROOT/scripts/validate-scope.sh"
bash -n "$ROOT/build/profiledef.sh"
grep -Fq 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' "$ROOT/build/pacman.conf" || fail "mirror oficial Arch ausente"
grep -Fq 'LANG=pt_BR.UTF-8' "$ROOT/build/airootfs/etc/locale.conf" || fail "locale PT-BR ausente"
grep -Fq 'pt_BR.UTF-8 UTF-8' "$ROOT/build/airootfs/etc/locale.gen" || fail "locale pt_BR não habilitado"
grep -Fq 'KEYMAP=br-abnt2' "$ROOT/build/airootfs/etc/vconsole.conf" || fail "teclado ABNT2 ausente"
grep -Fq 'Option "XkbLayout" "br"' "$ROOT/build/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf" || fail "layout X11 Brasil ausente"
grep -Fq 'Option "XkbVariant" "abnt2"' "$ROOT/build/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf" || fail "variante ABNT2 ausente"
for package in mate-session-manager mate-panel mate-applets blueman network-manager-applet mate-media; do
 grep -Fxq "$package" "$ROOT/build/packages.mate" || fail "pacote MATE ausente: $package"
done
pass "arquivos básicos e sintaxe dos scripts"
pass "locale Português do Brasil e teclado Brasil ABNT2"
pass "pacotes dos indicadores MATE presentes nos manifests"
pass "manifesto Archiso e mirror oficial configurados"
printf 'PENDENTE: perfil Archiso completo, instalador C/GTK4 e testes em VM.\n'
printf 'ISO: compilação não executada.\n'
