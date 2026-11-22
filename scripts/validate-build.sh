#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }

for tool in meson ninja pkg-config; do
  command -v "$tool" >/dev/null 2>&1 || fail "ferramenta de validação ausente: $tool"
done

"$ROOT/scripts/validate-arch-profile.sh"
"$ROOT/scripts/test-mate-panel.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

meson setup "$TMP_DIR/installer-build" "$ROOT/installer"
meson compile -C "$TMP_DIR/installer-build"
meson test -C "$TMP_DIR/installer-build" --print-errorlogs

printf 'OK: interface TUI ncurses compilada e testes unitários concluídos.\n'
printf 'PENDENTE: validar instalação offline e testes de VM BIOS/UEFI.\n'
printf 'ISO: nenhuma compilação executada por este validador.\n'
