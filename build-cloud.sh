#!/usr/bin/env bash
set -Eeuo pipefail

cat >&2 <<'MESSAGE'
ERRO: o antigo build-cloud.sh pertencia ao fluxo Manjaro e não é um construtor
válido para a Forja OS EndeavourOS.

A base ativa da Forja OS é EndeavourOS/Arch Linux.
Use o perfil em profiles/forja-xfce e seu script prepare-forja.sh para preparar
uma cópia de trabalho do framework oficial EndeavourOS-ISO.

A preparação atual ainda não compila uma ISO. O construtor EndeavourOS só deverá
ser habilitado depois que o perfil, o Calamares, o dracut e as dependências
forem validados.
MESSAGE
exit 2
