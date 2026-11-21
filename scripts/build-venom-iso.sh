#!/usr/bin/env bash
set -Eeuo pipefail
cat >&2 <<'MSG'
COMPILACAO BLOQUEADA.
Esta branch é somente histórica e não representa uma edição ativa.
A VENOM MATE oficial usa Arch Linux e está em optimize/venom-iso-size.
Nenhum workflow Manjaro ou buildiso pode ser executado nesta branch.
MSG
exit 1
