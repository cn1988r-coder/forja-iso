#!/usr/bin/env bash
set -Eeuo pipefail

[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
for cmd in truncate mkfs.btrfs mount umount btrfs; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Comando ausente: $cmd" >&2; exit 1; }
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$SCRIPT_DIR/../forja-packages/forja-snapshots/forja-snapshot-setup"
PACMAN_HOOK="$SCRIPT_DIR/../forja-packages/forja-snapshots/forja-pacman-snapshot"
WORK="$(mktemp -d /tmp/forja-btrfs-snapshot-test.XXXXXX)"
IMAGE="$WORK/btrfs.img"
TOP="$WORK/top"
ROOT="$WORK/root"
cleanup() {
  umount "$ROOT" 2>/dev/null || true
  umount "$TOP" 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT
mkdir -p "$TOP" "$ROOT"
truncate -s 1G "$IMAGE"
mkfs.btrfs -q -f "$IMAGE"
mount -o loop,subvolid=5 "$IMAGE" "$TOP"
btrfs subvolume create "$TOP/@"
mount -o loop,subvol=@ "$IMAGE" "$ROOT"

printf 'Forja Btrfs snapshot test\n' > "$ROOT/snapshot-test.txt"
btrfs subvolume snapshot "$ROOT" "$TOP/@forja-test-snapshot"
grep -Fq 'Forja Btrfs snapshot test' "$TOP/@forja-test-snapshot/snapshot-test.txt"
printf 'modified after snapshot\n' >> "$ROOT/snapshot-test.txt"
! grep -Fq 'modified after snapshot' "$TOP/@forja-test-snapshot/snapshot-test.txt"

subvolumes="$(btrfs subvolume list "$TOP")"
grep -Fq '/@' <<<"$subvolumes"
grep -Fq '/@forja-test-snapshot' <<<"$subvolumes"

bash -n "$SETUP"
bash -n "$PACMAN_HOOK"
grep -Fq 'timeshift --create' "$PACMAN_HOOK"
grep -Fq '"btrfs_mode": "true"' "$SETUP"
grep -Fq 'FSROOT' "$SETUP" || grep -Fq 'root_subvol' "$SETUP"
grep -Fq 'grub-btrfsd.service' "$SETUP"

echo "PASS: Btrfs criou snapshot de subvolume real e preservou o estado anterior."
echo "NOTA: este teste valida o mecanismo Btrfs e a sintaxe da integracao; o fluxo Timeshift/GRUB/restore ainda exige VM."
