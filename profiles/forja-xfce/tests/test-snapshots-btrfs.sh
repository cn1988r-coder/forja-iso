#!/usr/bin/env bash
set -Eeuo pipefail

[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
for cmd in truncate mkfs.btrfs mount umount btrfs snapper systemctl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Comando ausente: $cmd" >&2; exit 1; }
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$SCRIPT_DIR/../forja-packages/forja-snapshots/forja-snapshot-setup"
PACMAN_HOOK="$SCRIPT_DIR/../forja-packages/forja-snapshots/forja-pacman-snapshot"
WORK="$(mktemp -d /tmp/forja-btrfs-snapshot-test.XXXXXX)"
IMAGE="$WORK/btrfs.img"
TOP="$WORK/top"
ROOT="$WORK/root"
GRUB_STUB="$WORK/grub-mkconfig"
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

install -d "$ROOT/usr/lib/systemd/system" "$ROOT/boot/grub"
for unit in snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service; do
  source="/usr/lib/systemd/system/$unit"
  [[ -s "$source" ]] || source="/lib/systemd/system/$unit"
  [[ -s "$source" ]] || { echo "Unidade não encontrada no build host: $unit" >&2; exit 1; }
  install -m644 "$source" "$ROOT/usr/lib/systemd/system/$unit"
done

cat > "$GRUB_STUB" <<'STUB'
#!/usr/bin/env bash
set -Eeuo pipefail
while (($#)); do
  if [[ "$1" == "-o" ]]; then
    output="$2"
    shift 2
  else
    shift
  fi
done
mkdir -p "$(dirname "$output")"
printf '# Forja CI GRUB config stub\n' > "$output"
STUB
chmod +x "$GRUB_STUB"

FORJA_SNAPSHOT_ROOT="$ROOT" GRUB_MKCONFIG="$GRUB_STUB" bash "$SETUP" --boot
test -s "$ROOT/etc/snapper/configs/root"
test -d "$ROOT/.snapshots"
test -s "$ROOT/boot/grub/grub.cfg"
test -L "$ROOT/etc/systemd/system/timers.target.wants/snapper-timeline.timer"
test -L "$ROOT/etc/systemd/system/timers.target.wants/snapper-cleanup.timer"
test -L "$ROOT/etc/systemd/system/multi-user.target.wants/grub-btrfsd.service"

printf 'before snapshot\n' > "$ROOT/forja-snapshot-test.txt"
snapper -c root --root "$ROOT" create --description "Forja CI snapshot"
list="$(snapper -c root --root "$ROOT" list --columns number,description)"
grep -q "Forja CI snapshot" <<<"$list"

FORJA_SNAPSHOT_ROOT="$ROOT" FORJA_SNAPSHOT_STATE_DIR="$WORK/state" bash "$PACMAN_HOOK" pre
test -s "$WORK/state/pre-transaction"
printf 'after pre snapshot\n' >> "$ROOT/forja-snapshot-test.txt"
FORJA_SNAPSHOT_ROOT="$ROOT" FORJA_SNAPSHOT_STATE_DIR="$WORK/state" bash "$PACMAN_HOOK" post
test ! -e "$WORK/state/pre-transaction"
list="$(snapper -c root --root "$ROOT" list --columns number,type,description)"
grep -q "Forja: antes de transação Pacman" <<<"$list"
grep -q "Forja: depois de transação Pacman" <<<"$list"

btrfs subvolume list "$TOP" | grep -q '/.snapshots/'
echo "PASS: setup Forja, timers, GRUB hook, snapshot real e par pre/post validados em Btrfs."
