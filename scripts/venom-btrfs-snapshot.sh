#!/usr/bin/env bash
set -Eeuo pipefail

# VENOM OS: criação e consulta de snapshots usando EXCLUSIVAMENTE Timeshift.
# O Timeshift deve estar previamente configurado em modo BTRFS.
# Este script não cria snapshots Btrfs manualmente nem altera partições.

die() { echo "ERRO: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Execute com sudo."
command -v timeshift >/dev/null 2>&1 || die "Timeshift não está instalado."
command -v jq >/dev/null 2>&1 || die "Instale jq."

CONFIG="/etc/timeshift/timeshift.json"
[[ -r "$CONFIG" ]] || die "Configure o Timeshift primeiro e selecione BTRFS como tipo de snapshot."

MODE="$(jq -r '.btrfs_mode // false' "$CONFIG")"
[[ "$MODE" == "true" ]] || die "O Timeshift não está configurado em modo BTRFS. Abra sudo timeshift-gtk, selecione BTRFS e conclua a configuração."

ACTION="${1:-create}"
case "$ACTION" in
  create)
    COMMENT="${2:-Snapshot do sistema VENOM OS}"
    timeshift --create --comments "$COMMENT" --tags O
    ;;
  list)
    timeshift --list
    ;;
  *)
    echo "Uso:"
    echo "  sudo $0 create [comentário]"
    echo "  sudo $0 list"
    exit 2
    ;;
esac
