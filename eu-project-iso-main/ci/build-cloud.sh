#!/usr/bin/env bash
set -Eeuo pipefail
: "${FORJA_DISTRIBUTION:?Defina FORJA_DISTRIBUTION}"
: "${FORJA_DESKTOP:?Defina FORJA_DESKTOP}"
: "${FORJA_KERNEL:?Defina FORJA_KERNEL}"
case "$FORJA_DISTRIBUTION" in arch|manjaro) ;; *) echo "Distribuição inválida"; exit 2;; esac
exec bash "/forja-ci/build-$FORJA_DISTRIBUTION.sh"
