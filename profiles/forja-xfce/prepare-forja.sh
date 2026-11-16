#!/usr/bin/env bash
set -Eeuo pipefail

PROFILE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$PROFILE_DIR/../.." && pwd)"
UPSTREAM_ROOT="${ENDEAVOUROS_ISO_DIR:-$PWD}"

[[ -f "$UPSTREAM_ROOT/mkarchiso" ]] || {
  echo "Erro: execute este script na raiz de um clone do EndeavourOS-ISO." >&2
  exit 1
}
[[ -f "$UPSTREAM_ROOT/profiledef.sh" && -d "$UPSTREAM_ROOT/airootfs" ]] || {
  echo "Erro: estrutura upstream incompleta." >&2
  exit 1
}

# Do not overwrite the upstream source checkout. Prepare a separate Forja profile
# directory so upstream files remain available for comparison and recovery.
TARGET="$UPSTREAM_ROOT/forja-xfce-profile"
if [[ -e "$TARGET" ]]; then
  echo "Erro: $TARGET já existe. Remova ou renomeie manualmente antes de preparar novamente." >&2
  exit 1
fi

mkdir -p "$TARGET"
cp -a "$PROFILE_DIR/." "$TARGET/"
cp -a "$REPO_ROOT/desktops/xfce" "$TARGET/forja-desktop-assets"

# Copy the upstream profile framework files, then replace only the profile-specific
# package list and profile definition with Forja's versions.
cp -a "$UPSTREAM_ROOT/airootfs" "$TARGET/"
cp -a "$UPSTREAM_ROOT/efiboot" "$TARGET/" 2>/dev/null || true
cp -a "$UPSTREAM_ROOT/syslinux" "$TARGET/" 2>/dev/null || true
cp -a "$UPSTREAM_ROOT/pacman.conf" "$TARGET/"
cp -a "$UPSTREAM_ROOT/mkarchiso" "$TARGET/"
cp -a "$UPSTREAM_ROOT/run_before_squashfs.sh" "$TARGET/"
cp -a "$UPSTREAM_ROOT/prepare.sh" "$TARGET/upstream-prepare.sh"
cp -a "$UPSTREAM_ROOT/profiledef.sh" "$TARGET/upstream-profiledef.sh"

chmod +x "$TARGET/prepare-forja.sh" "$TARGET/apply-forja-live.sh"
echo "Perfil Forja XFCE preparado em: $TARGET"
echo "A estrutura upstream original não foi alterada."
echo "Próxima etapa: integrar o hook Forja ao fluxo de preparação e validar os pacotes/serviços."
