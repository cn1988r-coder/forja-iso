#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v buildiso >/dev/null 2>&1 || {
  printf 'ERRO: buildiso não encontrado. Execute em um ambiente de construção Manjaro com manjaro-tools-iso instalado.\n' >&2
  exit 1
}

[[ -s manjaro/venom-mate/profile.conf ]] || {
  printf 'ERRO: perfil Manjaro VENOM MATE não encontrado.\n' >&2
  exit 1
}

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/manjaro-tools"
mkdir -p "$config_dir"
printf 'run_dir=%s\\n' "$ROOT" > "$config_dir/iso-profiles.conf"

printf '[VENOM] Construindo perfil Manjaro MATE com buildiso oficial.\\n'
exec buildiso -f -p venom-mate -b stable -k linux618
