#!/usr/bin/env bash
set -Eeuo pipefail

# VENOM OS: snapshots nativos Btrfs.
# Requer /.snapshots montado como subvolume Btrfs separado, no mesmo filesystem
# do sistema. Nunca formata discos nem altera partições.

SNAPSHOT_DIR="${SNAPSHOT_DIR:-/.snapshots}"
KEEP="${KEEP:-10}"

die() { echo "ERRO: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Execute com sudo."
command -v btrfs >/dev/null 2>&1 || die "Instale btrfs-progs."
command -v findmnt >/dev/null 2>&1 || die "findmnt não encontrado."
[[ "$(findmnt -n -o FSTYPE /)" == "btrfs" ]] || die "A raiz do sistema não está em Btrfs."
mountpoint -q "$SNAPSHOT_DIR" || die "$SNAPSHOT_DIR precisa ser um ponto de montagem separado."
[[ "$(findmnt -n -o FSTYPE "$SNAPSHOT_DIR")" == "btrfs" ]] || die "$SNAPSHOT_DIR não está em Btrfs."
[[ "$(findmnt -n -o SOURCE / | sed 's/\[.*\]$//')" == "$(findmnt -n -o SOURCE "$SNAPSHOT_DIR" | sed 's/\[.*\]$//')" ]] || die "A pasta de snapshots precisa estar no mesmo filesystem Btrfs da raiz."

ROOT_ID="$(btrfs subvolume show / | awk '/Subvolume ID:/ {print $3; exit}')"
DEST_ID="$(btrfs subvolume show "$SNAPSHOT_DIR" | awk '/Subvolume ID:/ {print $3; exit}')"
[[ -n "$ROOT_ID" && -n "$DEST_ID" ]] || die "Não foi possível identificar os subvolumes."
[[ "$ROOT_ID" != "$DEST_ID" ]] || die "$SNAPSHOT_DIR não pode estar dentro do subvolume raiz. Monte um subvolume separado."

ACTION="${1:-create}"
case "$ACTION" in
  create)
    NAME="venom-root-$(date +%Y%m%d-%H%M%S)"
    btrfs subvolume snapshot -r / "$SNAPSHOT_DIR/$NAME"
    echo "Snapshot Btrfs criado: $SNAPSHOT_DIR/$NAME"
    ;;
  list)
    btrfs subvolume list "$SNAPSHOT_DIR"
    ;;
  cleanup)
    [[ "$KEEP" =~ ^[0-9]+$ ]] || die "KEEP precisa ser um número."
    mapfile -t SNAPSHOTS < <(find "$SNAPSHOT_DIR" -mindepth 1 -maxdepth 1 -type d -name 'venom-root-*' -printf '%f\n' | sort)
    COUNT="${#SNAPSHOTS[@]}"
    REMOVE=$(( COUNT > KEEP ? COUNT - KEEP : 0 ))
    for ((i=0; i<REMOVE; i++)); do
      btrfs subvolume delete "$SNAPSHOT_DIR/${SNAPSHOTS[$i]}"
    done
    echo "Limpeza concluída. Mantidos: $((COUNT-REMOVE)) snapshots."
    ;;
  *)
    echo "Uso: $0 {create|list|cleanup}"
    echo "Limpeza: KEEP=10 sudo $0 cleanup"
    exit 2
    ;;
esac
