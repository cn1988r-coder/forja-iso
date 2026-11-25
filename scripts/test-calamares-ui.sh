#!/usr/bin/env bash
# Validate the staged Calamares payload before Archiso installs the complete
# runtime into its final airootfs. A GUI launch here is invalid: this tree does
# not yet contain the Qt/KDE runtime packages installed later by mkarchiso.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="$ROOT/build/airootfs"
LOG="$ROOT/out/calamares-ui.log"
mkdir -p "$ROOT/out"

fail() { echo "[VENOM] ERRO: $*" >&2; exit 1; }

[[ -x "$ROOTFS/usr/bin/calamares" ]] || fail "Executável do Calamares ausente no payload."
[[ -s "$ROOTFS/etc/calamares/settings.conf" ]] || fail "settings.conf ausente."
[[ -d "$ROOTFS/usr/lib/calamares/modules" ]] || fail "Diretório de módulos ausente."
[[ -d "$ROOTFS/usr/share/calamares/branding/venom" ]] || fail "Branding VENOM ausente."

# Confirm the staged ELF has a valid interpreter declaration. Do not execute
# it in chroot yet: runtime libraries are installed by mkarchiso afterwards.
command -v readelf >/dev/null 2>&1 || fail "readelf não encontrado."
INTERP="$(readelf -l "$ROOTFS/usr/bin/calamares" | sed -n 's/.*Requesting program interpreter: \\(.*\\)]/\\1/p')"
[[ -n "$INTERP" ]] || fail "Não foi possível identificar o interpretador ELF do Calamares."
[[ -x "$INTERP" ]] || fail "Interpretador ELF ausente no container de build: $INTERP"

# Check that the core modules configured by VENOM have actually been staged.
for module in partition mount fstab users bootloader services-systemd; do
  [[ -d "$ROOTFS/usr/lib/calamares/modules/$module" ]] || fail "Módulo Calamares ausente: $module"
done

{
  echo "VENOM_CALAMARES_PAYLOAD_VALID"
  echo "Executable: $ROOTFS/usr/bin/calamares"
  echo "ELF interpreter: $INTERP"
  echo "Configured settings: $ROOTFS/etc/calamares/settings.conf"
  echo "Core modules: partition mount fstab users bootloader services-systemd"
  echo "GUI launch deferred until the complete Archiso runtime exists."
} | tee "$LOG"

echo "[VENOM] Payload do Calamares validado. O teste gráfico será feito no sistema Live completo."
