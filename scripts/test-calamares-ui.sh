#!/usr/bin/env bash
# Open the real staged Calamares UI in a virtual X server before ISO creation.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="$ROOT/build/airootfs"
LOG="$ROOT/out/calamares-ui.log"
mkdir -p "$ROOT/out"
[[ -x "$ROOTFS/usr/bin/calamares" ]] || { echo "Calamares ausente no rootfs." >&2; exit 1; }
[[ -s "$ROOTFS/etc/calamares/settings.conf" ]] || { echo "settings.conf ausente." >&2; exit 1; }

for tool in xvfb-run dbus-run-session xwininfo timeout; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Ferramenta de teste ausente: $tool" >&2; exit 1; }
done

# Ensure every mount target exists in the staged rootfs before mounting.
# Minimal airootfs trees may not contain /tmp yet, which would make mount fail.
install -d -m 1777 "$ROOTFS/tmp"
install -d "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run"

# The chroot must see devices, procfs, sysfs, runtime sockets and the X11 socket.
mount --bind /tmp "$ROOTFS/tmp"
mount --rbind /dev "$ROOTFS/dev"
mount --make-rslave "$ROOTFS/dev"
mount -t proc proc "$ROOTFS/proc"
mount --rbind /sys "$ROOTFS/sys"
mount --make-rslave "$ROOTFS/sys"
mount --rbind /run "$ROOTFS/run"
mount --make-rslave "$ROOTFS/run"
cleanup() {
  umount -R "$ROOTFS/run" 2>/dev/null || true
  umount -R "$ROOTFS/sys" 2>/dev/null || true
  umount "$ROOTFS/proc" 2>/dev/null || true
  umount -R "$ROOTFS/dev" 2>/dev/null || true
  umount "$ROOTFS/tmp" 2>/dev/null || true
}
trap cleanup EXIT

export VENOM_ROOTFS="$ROOTFS" VENOM_LOG="$LOG"
xvfb-run -a dbus-run-session -- bash -Eeuo pipefail -c '
  chroot "$VENOM_ROOTFS" /usr/bin/calamares -d >"$VENOM_LOG" 2>&1 &
  app_pid=$!
  finish() {
    kill "$app_pid" 2>/dev/null || true
    wait "$app_pid" 2>/dev/null || true
  }
  trap finish EXIT
  for attempt in $(seq 1 30); do
    if ! kill -0 "$app_pid" 2>/dev/null; then
      cat "$VENOM_LOG"
      echo "Calamares encerrou antes de abrir a janela." >&2
      exit 1
    fi
    if xwininfo -root -tree 2>/dev/null | grep -Eiq "Calamares|VENOM"; then
      echo "VENOM_CALAMARES_WINDOW_OPEN"
      exit 0
    fi
    sleep 1
  done
  cat "$VENOM_LOG"
  xwininfo -root -tree || true
  echo "A janela do Calamares não apareceu no Xvfb." >&2
  exit 1
'
echo "[VENOM] Interface gráfica do Calamares abriu no Xvfb."
