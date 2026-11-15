#!/usr/bin/env bash
set -Eeuo pipefail
: "${FORJA_KERNEL:?Defina FORJA_KERNEL}"
if [[ "${FORJA_DISTRIBUTION:-manjaro}" != manjaro ]]; then
  echo "Esta rotina de nuvem aceita somente a base Manjaro." >&2
  exit 2
fi
case "${FORJA_DESKTOP:-xfce}" in
  xfce) ;;
  *) echo "Esta edição da Forja OS oferece somente XFCE." >&2; exit 2 ;;
esac
exec bash /forja-ci/build-manjaro.sh
