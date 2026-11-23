#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 https://code.manjaro.org/profiles/iso-profiles.git "$TMP/iso-profiles"
cp -a "$ROOT/manjaro/venom-mate" "$TMP/iso-profiles/manjaro/venom-mate"
VENOM_PROFILE_DIR="$TMP/iso-profiles/manjaro/venom-mate" bash "$ROOT/scripts/prepare-manjaro-profile.sh"
VENOM_PROFILE_DIR="$TMP/iso-profiles/manjaro/venom-mate" bash "$ROOT/scripts/validate-manjaro-profile.sh"
grep -Fxq 'calamares' "$TMP/iso-profiles/shared/Packages-Live"
for path in Packages-Root Packages-Live Packages-Mhwd; do
  [[ -e "$TMP/iso-profiles/manjaro/venom-mate/$path" ]] || { echo "Symlink oficial quebrado: $path" >&2; exit 1; }
done
[[ -d "$TMP/iso-profiles/manjaro/venom-mate/root-overlay" ]]
[[ -e "$TMP/iso-profiles/manjaro/venom-mate/root-overlay/etc/dconf/db/local.d/00-venom" ]]
[[ -e "$TMP/iso-profiles/manjaro/venom-mate/desktop-overlay/etc/dconf/db/local.d/00-venom" ]]
[[ -e "$TMP/iso-profiles/manjaro/venom-mate/live-overlay/etc/pam.d" ]]
[[ -e "$TMP/iso-profiles/manjaro/venom-mate/live-overlay/etc/skel/.config/manjaro" ]]
echo "Integração estrutural com iso-profiles oficial Manjaro: APROVADA."
