#!/usr/bin/env bash
set -Eeuo pipefail
cat >&2 <<'MSG'
COMPILACAO BLOQUEADA.
A VENOM OS ainda não possui instalador próprio implementado e validado.
O perfil Archiso também permanece em preparação.
Nenhuma ISO pode ser gerada sem autorização expressa do usuário.
Este script é intencionalmente uma barreira de segurança.
MSG
exit 1
