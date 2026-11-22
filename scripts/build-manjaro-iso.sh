#!/usr/bin/env bash
# A geração completa fica bloqueada até aprovação explícita.
set -Eeuo pipefail
if [[ "${VENOM_ISO_APPROVED:-}" != "YES" ]]; then
  echo "Compilação bloqueada. Defina VENOM_ISO_APPROVED=YES somente após validar o perfil e receber autorização do usuário." >&2
  exit 64
fi
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/validate-manjaro-build.sh"
PROFILE_ROOT="/usr/share/manjaro-tools/iso-profiles"
cd "$PROFILE_ROOT"
sudo buildiso -p venom-mate -b stable
