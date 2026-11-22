#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "${VENOM_ISO_BUILD_AUTHORIZED:-}" != "YES" ]]; then
  printf 'BLOQUEADO: a geração da ISO exige autorização expressa do usuário.\n' >&2
  exit 2
fi

[[ "$EUID" -eq 0 ]] || {
  printf 'ERRO: execute este script somente no ambiente Arch isolado de build.\n' >&2
  exit 1
}

for tool in pacman mkarchiso meson ninja gcc pkg-config; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'ERRO: ferramenta obrigatória ausente: %s\n' "$tool" >&2
    exit 1
  }
done

[[ -f build/profiledef.sh && -f build/packages.x86_64 ]] || {
  printf 'ERRO: perfil Archiso VENOM ausente ou incompleto.\n' >&2
  exit 1
}

scripts/validate-arch-profile.sh

WORK="$ROOT/work"
PROFILE="$WORK/profile"
INSTALL_ROOT="$WORK/installer-root"
INSTALL_BUILD="$WORK/installer-build"
OUT="$ROOT/out"

rm -rf "$PROFILE" "$INSTALL_ROOT" "$INSTALL_BUILD"
mkdir -p "$PROFILE" "$OUT"

printf '[VENOM] Preparando perfil e compilando o instalador TUI ncurses.\n'
cp -a "$ROOT/build/." "$PROFILE/"
meson setup "$INSTALL_BUILD" "$ROOT/installer"
meson compile -C "$INSTALL_BUILD"
DESTDIR="$INSTALL_ROOT" meson install -C "$INSTALL_BUILD"
cp -a "$INSTALL_ROOT/." "$PROFILE/airootfs/"

printf '[VENOM] Incluindo os manifestos das duas edicoes. Os pacotes serao instalados diretamente dos repositorios oficiais Arch Linux.\\n'
install -D "$ROOT/build/install-packages-xfce.x86_64" "$PROFILE/airootfs/usr/share/venom/install-packages-xfce.x86_64"
install -D "$ROOT/build/install-packages-mate.x86_64" "$PROFILE/airootfs/usr/share/venom/install-packages-mate.x86_64"
install -d "$PROFILE/airootfs/usr/share/venom/install-overlay"
cp -a "$ROOT/build/install-overlay/." "$PROFILE/airootfs/usr/share/venom/install-overlay/"

printf '[VENOM] Construindo ISO com Archiso oficial.\n'
mkarchiso -v -w "$WORK/archiso" -o "$OUT" "$PROFILE"

ISO="$(find "$OUT" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$ISO" ]] || {
  printf 'ERRO: Archiso terminou sem gerar arquivo ISO.\n' >&2
  exit 1
}

sha256sum "$ISO" | tee "$ISO.sha256"
printf '[VENOM] ISO criada: %s\n' "$ISO"
