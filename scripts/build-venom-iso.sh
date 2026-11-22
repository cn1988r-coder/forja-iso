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

for tool in pacman mkarchiso meson ninja gcc pkg-config xorriso; do
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
bash scripts/validate-offline-repo.sh

WORK="$ROOT/work"
PROFILE="$WORK/profile"
INSTALL_ROOT="$WORK/installer-root"
INSTALL_BUILD="$WORK/installer-build"
OUT="$ROOT/out"

rm -rf "$PROFILE" "$INSTALL_ROOT" "$INSTALL_BUILD"
mkdir -p "$PROFILE" "$OUT"

printf '[VENOM] Preparando perfil e compilando o único instalador TUI ncurses.\n'
tar --exclude='./offline-repo' -C "$ROOT/build" -cf - . | tar -C "$PROFILE" -xf -
meson setup "$INSTALL_BUILD" "$ROOT/installer"
meson compile -C "$INSTALL_BUILD"
DESTDIR="$INSTALL_ROOT" meson install -C "$INSTALL_BUILD"
cp -a "$INSTALL_ROOT/." "$PROFILE/airootfs/"

printf '[VENOM] Incluindo pacotes offline das duas edições.\n'
OFFLINE_SOURCE="$ROOT/build/offline-repo"
[[ -s "$OFFLINE_SOURCE/offline.db" ]] || {
  printf 'ERRO: build/offline-repo/offline.db ausente. Prepare o bundle offline antes de compilar a ISO.\n' >&2
  exit 1
}
[[ -n "$(find "$OFFLINE_SOURCE" -maxdepth 1 -type f -name '*.pkg.tar.*' -print -quit)" ]] || {
  printf 'ERRO: nenhum pacote foi encontrado no bundle offline.\n' >&2
  exit 1
}
install -d "$PROFILE/airootfs/usr/share/venom/offline-repo"
cp -a "$OFFLINE_SOURCE/." "$PROFILE/airootfs/usr/share/venom/offline-repo/"
install -D "$ROOT/build/install-packages-xfce.x86_64" "$PROFILE/airootfs/usr/share/venom/install-packages-xfce.x86_64"
install -D "$ROOT/build/install-packages-mate.x86_64" "$PROFILE/airootfs/usr/share/venom/install-packages-mate.x86_64"
install -d "$PROFILE/airootfs/usr/share/venom/install-overlay"
cp -a "$ROOT/build/install-overlay/." "$PROFILE/airootfs/usr/share/venom/install-overlay/"
install -D -m 0755 "$ROOT/installer/scripts/configure-btrfs-snapshots.sh" "$PROFILE/airootfs/usr/lib/venom/configure-btrfs-snapshots.sh"

printf '[VENOM] Construindo ISO com Archiso oficial.\n'
mkarchiso -v -w "$WORK/archiso" -o "$OUT" "$PROFILE"

ISO="$(find "$OUT" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$ISO" ]] || {
  printf 'ERRO: Archiso terminou sem gerar arquivo ISO.\n' >&2
  exit 1
}

# Impede publicar uma ISO BIOS sem o arquivo que o ISOLINUX procura.
SYSLINUX_CFG="$(mktemp)"
trap 'rm -f "$SYSLINUX_CFG"' EXIT
if ! xorriso -osirrox on -indev "$ISO" -extract /syslinux/isolinux.cfg "$SYSLINUX_CFG" >/dev/null 2>&1; then
  printf 'ERRO: a ISO não contém /syslinux/isolinux.cfg; boot BIOS não está pronto.\n' >&2
  exit 1
fi
grep -Eq '^[[:space:]]*DEFAULT[[:space:]]+venom([[:space:]]|$)' "$SYSLINUX_CFG" || {
  printf 'ERRO: isolinux.cfg não seleciona o único instalador TUI VENOM.\n' >&2
  exit 1
}
grep -Fq 'archiso_sys-linux.cfg' "$SYSLINUX_CFG" || {
  printf 'ERRO: isolinux.cfg não inclui a configuração de kernel do Archiso.\n' >&2
  exit 1
}
printf '[VENOM] Configuração BIOS do ISOLINUX verificada dentro da ISO.\n'

sha256sum "$ISO" | tee "$ISO.sha256"
printf '[VENOM] ISO criada e verificada: %s\n' "$ISO"
