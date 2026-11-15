#!/usr/bin/env bash
set -Eeuo pipefail
: "${FORJA_KERNEL:?Defina FORJA_KERNEL}"
if [[ "${FORJA_DISTRIBUTION:-manjaro}" != manjaro ]]; then
  echo "Esta rotina de nuvem aceita somente a base Manjaro." >&2
  exit 2
fi
case "${FORJA_DESKTOP:-mate}" in
  mate|xfce) ;;
  *) echo "Desktop inválido: use mate ou xfce." >&2; exit 2 ;;
esac
exec bash /forja-ci/build-manjaro.sh
