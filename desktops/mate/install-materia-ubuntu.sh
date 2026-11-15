#!/usr/bin/env bash
# Build and install the official Materia GTK theme at a pinned upstream commit.
set -Eeuo pipefail

[[ "$EUID" -eq 0 ]] || { echo "Execute com sudo." >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Git não está instalado." >&2; exit 1; }
command -v meson >/dev/null 2>&1 || { echo "Meson não está instalado." >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm não está instalado." >&2; exit 1; }

readonly SOURCE_URL="https://github.com/nana-4/materia-theme.git"
readonly SOURCE_COMMIT="d7f59a37ef51f893c28b55dc344146e04b2cd52c"
WORK="$(mktemp -d /tmp/forja-materia.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

git init "$WORK/source"
git -C "$WORK/source" remote add origin "$SOURCE_URL"
git -C "$WORK/source" fetch --depth 1 origin "$SOURCE_COMMIT"
git -C "$WORK/source" checkout --detach FETCH_HEAD
actual="$(git -C "$WORK/source" rev-parse HEAD)"
[[ "$actual" == "$SOURCE_COMMIT" ]] || {
  echo "A revisão Materia recebida não corresponde à revisão fixada." >&2
  exit 1
}

cd "$WORK/source"
meson setup _build --prefix=/usr -Dcolors=dark -Dsizes=default
meson install -C _build

test -d /usr/share/themes/Materia-dark
echo "Tema Materia-dark instalado a partir da revisão upstream verificada."
