#!/usr/bin/env bash
set -Eeuo pipefail

[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
for cmd in truncate mkfs.btrfs mount umount btrfs snapper; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Comando ausente: $cmd" >&2; exit 1; }
done

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

# Exercise the same Snapper config creation used by Forja's first-boot setup.
snapper -c root --root "$ROOT" create-config /
test -s "$ROOT/etc/snapper/configs/root"
test -d "$ROOT/.snapshots"

# Create a real numbered snapshot and verify that Snapper can enumerate it.
printf 'before snapshot\n' > "$ROOT/forja-snapshot-test.txt"
snapper -c root --root "$ROOT" create --description "Forja CI snapshot"
list="$(snapper -c root --root "$ROOT" list --columns number,description)"
grep -q "Forja CI snapshot" <<<"$list"

# Exercise the pre/post pair used by the Pacman transaction hooks.
pre="$(snapper -c root --root "$ROOT" create --type pre --print-number --description "Forja CI pre")"
[[ "$pre" =~ ^[0-9]+$ ]]
printf 'after pre snapshot\n' >> "$ROOT/forja-snapshot-test.txt"
snapper -c root --root "$ROOT" create --type post --pre-number "$pre" --description "Forja CI post"
list="$(snapper -c root --root "$ROOT" list --columns number,type,description)"
grep -q "Forja CI pre" <<<"$list"
grep -q "Forja CI post" <<<"$list"

# Confirm that Btrfs really stored snapshot subvolumes, not merely Snapper metadata.
btrfs subvolume list "$TOP" | grep -q '/.snapshots/'
echo "PASS: Btrfs subvolume, Snapper config, numbered snapshot and pre/post pair validated."
