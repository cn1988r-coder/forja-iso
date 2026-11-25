#!/usr/bin/env bash
# Validate the staged Calamares payload before Archiso installs the complete
# runtime into the final airootfs. A GUI launch here is invalid because the
# Qt/KDE runtime packages are installed later by mkarchiso.
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="$ROOT/build/airootfs"
LOG="$ROOT/out/calamares-ui.log"
CALAMARES="$ROOTFS/usr/bin/calamares"
mkdir -p "$ROOT/out"

fail() {
  echo "[VENOM] ERRO: $*" >&2
  exit 1
}

[[ -x "$CALAMARES" ]] || fail "Executável do Calamares ausente no payload: $CALAMARES"
[[ -s "$ROOTFS/etc/calamares/settings.conf" ]] || fail "settings.conf ausente."
[[ -d "$ROOTFS/usr/lib/calamares/modules" ]] || fail "Diretório de módulos ausente."
[[ -d "$ROOTFS/usr/share/calamares/branding/venom" ]] || fail "Branding VENOM ausente."

# Parse the ELF interpreter from readelf's wide program-header output.
# Avoid sed capture groups here: the previous expression was over-escaped
# and always returned an empty value on the GitHub runner.
command -v readelf >/dev/null 2>&1 || fail "readelf não encontrado."
readelf -h "$CALAMARES" >/dev/null 2>&1 || fail "O executável do Calamares não é um ELF válido."

INTERP="$(
  readelf -lW "$CALAMARES" |
    awk '
      /Requesting program interpreter:/ {
        sub(/^.*Requesting program interpreter: /, "")
        sub(/].*$/, "")
        print
        exit
      }
    '
)"

[[ -n "$INTERP" ]] || fail "O ELF do Calamares não declara um interpretador PT_INTERP."
[[ "$INTERP" == /* ]] || fail "Caminho de interpretador ELF inválido: $INTERP"
[[ -x "$INTERP" ]] || fail "Interpretador ELF não existe no container Arch de build: $INTERP"

# Confirm the core modules configured by VENOM have actually been staged.
for module in partition mount fstab users bootloader services-systemd; do
  [[ -d "$ROOTFS/usr/lib/calamares/modules/$module" ]] || fail "Módulo Calamares ausente: $module"
done

{
  echo "VENOM_CALAMARES_PAYLOAD_VALID"
  echo "Executable: $CALAMARES"
  echo "ELF interpreter: $INTERP"
  echo "Configured settings: $ROOTFS/etc/calamares/settings.conf"
  echo "Core modules: partition mount fstab users bootloader services-systemd"
  echo "GUI launch deferred until the complete Archiso runtime exists."
} | tee "$LOG"

echo "[VENOM] Payload do Calamares validado. O teste gráfico será feito no sistema Live completo."
