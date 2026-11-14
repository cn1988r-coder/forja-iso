#!/usr/bin/env bash
set -Eeuo pipefail
: "${FORJA_KERNEL:?Defina FORJA_KERNEL}"
if [[ "${FORJA_DISTRIBUTION:-manjaro}" != manjaro || "${FORJA_DESKTOP:-mate}" != mate ]]; then
  echo "Esta Forja gera exclusivamente Manjaro MATE." >&2
  exit 2
fi
exec bash /forja-ci/build-manjaro.sh
