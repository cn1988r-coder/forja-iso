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

for tool in pacman repo-add mkarchiso meson ninja gcc pkg-config; do
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
PKG_CACHE="$WORK/offline-packages"
OFFLINE_REPO="$WORK/offline-repo"
OUT="$ROOT/out"

rm -rf "$PROFILE" "$INSTALL_ROOT" "$INSTALL_BUILD" "$PKG_CACHE" "$OFFLINE_REPO"
mkdir -p "$PROFILE" "$OUT" "$PKG_CACHE" "$OFFLINE_REPO"

printf '[VENOM] Preparando perfil e compilando o instalador TUI ncurses.\n'
cp -a "$ROOT/build/." "$PROFILE/"
meson setup "$INSTALL_BUILD" "$ROOT/installer"
meson compile -C "$INSTALL_BUILD"
DESTDIR="$INSTALL_ROOT" meson install -C "$INSTALL_BUILD"
cp -a "$INSTALL_ROOT/." "$PROFILE/airootfs/"

printf '[VENOM] Baixando pacotes e dependencias para as duas edicoes.\\n'
declare -A PACKAGE_SET=()
for manifest in "$ROOT/build/install-packages-xfce.x86_64" "$ROOT/build/install-packages-mate.x86_64"; do
  [[ -s "$manifest" ]] || { printf 'ERRO: manifesto ausente: %s\\n' "$manifest" >&2; exit 1; }
  while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
    PACKAGE_SET["$package"]=1
  done < "$manifest"
done
mapfile -t ALL_PACKAGES < <(printf '%s\\n' "${!PACKAGE_SET[@]}" | sort)
(("${#ALL_PACKAGES[@]}" > 0)) || { printf 'ERRO: manifestos sem pacotes.\\n' >&2; exit 1; }
pacman -Sw --noconfirm --cachedir "$PKG_CACHE" --config "$ROOT/build/pacman.conf" "${ALL_PACKAGES[@]}"
shopt -s nullglob
PACKAGE_FILES=("$PKG_CACHE"/*.pkg.tar.zst)
(("${#PACKAGE_FILES[@]}" > 0)) || { printf 'ERRO: nenhum pacote foi baixado para o repositorio offline.\\n' >&2; exit 1; }
repo-add "$OFFLINE_REPO/venom.db.tar.gz" "${PACKAGE_FILES[@]}"
install -d "$PROFILE/airootfs/usr/share/venom/repo"
cp -a "$PKG_CACHE/." "$PROFILE/airootfs/usr/share/venom/repo/"
cp -a "$OFFLINE_REPO/." "$PROFILE/airootfs/usr/share/venom/repo/"
printf '[VENOM] Repositorio offline local criado com %s pacotes.\\n' "${#PACKAGE_FILES[@]}"

printf '[VENOM] Construindo ISO com Archiso oficial.\\n'
mkarchiso -v -w "$WORK/archiso" -o "$OUT" "$PROFILE"

ISO="$(find "$OUT" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$ISO" ]] || {
  printf 'ERRO: Archiso terminou sem gerar arquivo ISO.\n' >&2
  exit 1
}

sha256sum "$ISO" | tee "$ISO.sha256"
printf '[VENOM] ISO criada: %s\n' "$ISO"
