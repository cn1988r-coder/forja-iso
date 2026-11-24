#!/usr/bin/env bash
# Prepare the Calamares installer and offline AUR payload inside the Archiso
# root tree. This script is invoked only by the explicit ISO build command.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ $EUID -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }

for tool in git cmake ninja; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Ferramenta ausente: $tool" >&2; exit 1; }
done

# Apply the approved XFCE visual profile to both live and installed systems.
bash scripts/setup-xfce-windows-dark.sh --root build/airootfs
bash scripts/setup-xfce-windows-dark.sh --root build/install-overlay

AUR_REPO="${AUR_REPO:-/tmp/venom-aur-repo}"
[[ -s "$AUR_REPO/venom-aur.db" ]] || { echo "Repositório AUR local não preparado." >&2; exit 1; }

install -d build/airootfs/usr/share/venom/aur-repo
cp -a "$AUR_REPO/." build/airootfs/usr/share/venom/aur-repo/
install -Dm644 build/install-packages.x86_64 build/airootfs/usr/share/venom/install-packages.x86_64
install -d build/airootfs/usr/share/venom/install-overlay
cp -a build/install-overlay/. build/airootfs/usr/share/venom/install-overlay/

CALAMARES_SRC="${RUNNER_TEMP:-/tmp}/venom-calamares-src"
CALAMARES_BUILD="${RUNNER_TEMP:-/tmp}/venom-calamares-build"
rm -rf "$CALAMARES_SRC" "$CALAMARES_BUILD"
git clone --filter=blob:none --no-checkout https://github.com/calamares/calamares.git "$CALAMARES_SRC"
git -C "$CALAMARES_SRC" fetch --depth=1 origin refs/tags/v3.3.14:refs/tags/v3.3.14
TAG_OBJECT="$(git -C "$CALAMARES_SRC" rev-parse refs/tags/v3.3.14)"
TAG_COMMIT="$(git -C "$CALAMARES_SRC" rev-parse 'refs/tags/v3.3.14^{}')"
[[ "$TAG_OBJECT" == "e3a5e603af8202e426adb171475b79357a5b1431" ]] || { echo "Tag Calamares inesperada." >&2; exit 1; }
[[ "$TAG_COMMIT" == "21ea803527735cfaf54fa6059e71d1ef65004864" ]] || { echo "Commit Calamares inesperado." >&2; exit 1; }
git -C "$CALAMARES_SRC" checkout --detach "$TAG_COMMIT"

cmake -S "$CALAMARES_SRC" -B "$CALAMARES_BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
  -DWITH_QT6=ON -DWITH_PYTHON=ON -DWITH_PYBIND11=ON -DWITH_QML=ON \
  -DBUILD_SCHEMA_TESTING=OFF -DBUILD_CRASH_REPORTING=OFF -DINSTALL_CONFIG=OFF
cmake --build "$CALAMARES_BUILD" --parallel "${MAKEFLAGS_JOBS:-2}"
DESTDIR="$ROOT/build/airootfs" cmake --install "$CALAMARES_BUILD"

install -Dm644 installer/settings.conf build/airootfs/etc/calamares/settings.conf
install -Dm644 installer/branding/branding.desc build/airootfs/usr/share/calamares/branding/venom/branding.desc
install -d build/airootfs/usr/lib/calamares/modules
cp -a installer/modules/venominstall build/airootfs/usr/lib/calamares/modules/
install -Dm644 installer/venom-installer.desktop build/airootfs/usr/share/applications/venom-installer.desktop

install -d build/airootfs/etc/calamares/modules
for module in bootloader displaymanager fstab grubcfg initcpiocfg keyboard locale localecfg mount partition services-systemd users venominstall; do
  install -Dm644 "installer/modules/$module/$module.conf" "build/airootfs/etc/calamares/modules/$module.conf"
done

echo "[VENOM] Payload Calamares, repositório AUR e overlay de instalação preparados."
