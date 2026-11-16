#!/usr/bin/env bash
set -Eeuo pipefail

# Executado dentro do rootfs após a instalação dos pacotes.
source /etc/mkinitcpio.conf
source /tmp/forja-mkinitcpio.conf
_forja_hooks="${HOOKS[*]}"

_tmp_config="$(mktemp)"
trap 'rm -f "$_tmp_config"' EXIT
awk -v hooks="$_forja_hooks" '
  /^[[:space:]]*HOOKS[[:space:]]*=\(/ {
    count++
    print "HOOKS=(" hooks ")"
    if ($0 !~ /\)/) skipping=1
    next
  }
  skipping {
    if ($0 ~ /\)/) skipping=0
    next
  }
  { print }
  END {
    if (count != 1) {
      print "Forja OS: esperado exatamente um vetor HOOKS ativo em /etc/mkinitcpio.conf." > "/dev/stderr"
      exit 1
    }
  }
' /etc/mkinitcpio.conf > "$_tmp_config"
cat "$_tmp_config" > /etc/mkinitcpio.conf
rm -f /tmp/forja-mkinitcpio.conf
