#!/usr/bin/env bash
set -Eeuo pipefail

# VENOM OS: snapshots e restauração integral pelo Timeshift em BTRFS.
# A restauração usa o fluxo nativo do Timeshift e NÃO ignora a reinstalação do GRUB.
# O Timeshift deve estar configurado em BTRFS e o sistema deve usar GRUB2.

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
  restore)
    echo "RESTAURAÇÃO INTEGRAL: selecione o snapshot desejado no Timeshift."
    echo "Não use a opção de ignorar a reinstalação do GRUB."
    echo "Em sistemas UEFI, confirme que a partição EFI (/boot/efi) está mapeada."
    echo "O Timeshift executará a restauração BTRFS e o procedimento de reinstalação do GRUB2."
    timeshift --restore
    ;;
  *)
    echo "Uso:"
    echo "  sudo $0 create [comentário]"
    echo "  sudo $0 list"
    echo "  sudo $0 restore"
    exit 2
    ;;
esac
