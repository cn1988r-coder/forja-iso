#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-work}"
ROOTFS="$SCRIPT_DIR/$WORK_DIR/x86_64/airootfs"

[[ -x "$SCRIPT_DIR/run_before_squashfs-upstream.sh" ]] || {
  echo "Erro: hook original do EndeavourOS não encontrado." >&2
  exit 1
}
[[ -d "$ROOTFS" ]] || {
  echo "Erro: airootfs de trabalho não encontrado em $ROOTFS." >&2
  exit 1
}

# Preserve all upstream live-user, keyring, mirror and offline-package setup.
bash "$SCRIPT_DIR/run_before_squashfs-upstream.sh"

# Apply Forja branding only after EndeavourOS has created the liveuser account.
arch-chroot "$ROOTFS" /bin/bash /root/apply-forja-live.sh
