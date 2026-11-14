#!/usr/bin/env bash
set -Eeuo pipefail
WORK="${1:-/tmp/forja-manjaro}"
PKG_SRC="$WORK/shelly-build"
PKG_OUT="$WORK/shelly-packages"
REPO_ROOT="$WORK/shelly-repo"
REPO_DIR="$REPO_ROOT/forja-shelly/x86_64"
mkdir -p "$PKG_SRC" "$PKG_OUT" "$REPO_DIR"

echo "== Preparando Shelly-ALPM a partir do upstream verificado =="
BUILD_PACKAGES=(base-devel sudo git libarchive curl sqlite gnupg pkgconf gtk4 clang gettext flatpak ripgrep go-md2man binutils pacman-contrib python python-pip)
MISSING_BUILD_PACKAGES=()
for package in "${BUILD_PACKAGES[@]}"; do
  if ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" >/dev/null 2>&1; then
    MISSING_BUILD_PACKAGES+=("$package")
  fi
done
if (("${#MISSING_BUILD_PACKAGES[@]}")); then
  printf "ERRO: dependências necessárias para compilar Shelly/Bibata ausentes: %s\\n" "${MISSING_BUILD_PACKAGES[*]}" >&2
  exit 11
fi
pacman -S --needed --noconfirm "${BUILD_PACKAGES[@]}"

cp -a /forja-ci/eu-project-iso-main/ci/shelly/. "$PKG_SRC/"
curl -fsSL --retry 5 --retry-all-errors https://ziglang.org/download/index.json -o "$WORK/zig-index.json"
readarray -t ZIG_META < <(python - "$WORK/zig-index.json" <<'PY'
import json,sys
data=json.load(open(sys.argv[1],encoding="utf-8"))
entry=data["0.17.1"]["x86_64-linux"]
print(entry["tarball"])
print(entry["shasum"])
PY
)
ZIG_URL="${ZIG_META[0]}"
if [[ "$ZIG_URL" != http://* && "$ZIG_URL" != https://* ]]; then
  ZIG_URL="https://ziglang.org/download/0.17.1/$ZIG_URL"
fi
ZIG_ARCHIVE="$WORK/$(basename "$ZIG_URL")"
curl -fL --retry 5 --retry-all-errors "$ZIG_URL" -o "$ZIG_ARCHIVE"
printf '%s  %s\n' "${ZIG_META[1]}" "$ZIG_ARCHIVE" | sha256sum -c -
tar -xf "$ZIG_ARCHIVE" -C "$WORK"
ZIG_DIR="$WORK/zig-x86_64-linux-0.17.1"
test -x "$ZIG_DIR/zig"
"$ZIG_DIR/zig" version | grep -Fx '0.17.1'

# Bibata's source PKGBUILD calls ctgen, provided by Python's clickgen.
# makepkg --nodeps is intentional for the isolated AUR build, so install this
# build-only dependency explicitly in a private venv and verify the CLI first.
CLICKGEN_VENV="$WORK/clickgen-venv"
python -m venv "$CLICKGEN_VENV"
"$CLICKGEN_VENV/bin/python" -m pip install --disable-pip-version-check --no-cache-dir 'clickgen>=2.1.8'
"$CLICKGEN_VENV/bin/ctgen" --help >/dev/null

if ! id shellybuild >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash shellybuild
fi
chown -R shellybuild:shellybuild "$PKG_SRC" "$PKG_OUT"
su -s /bin/bash shellybuild -c "cd '$PKG_SRC' && PATH='$ZIG_DIR':\$PATH PKGDEST='$PKG_OUT' SHELLY_LIBALPM=true makepkg --nodeps --noconfirm"

# Build only Bibata from AUR. Papirus Dark is installed from Manjaro's
# official repositories; its built-in folder icons are kept unchanged.
aur_package="bibata-cursor-theme"
aur_src="$WORK/aur-$aur_package"
git clone --depth 1 "https://aur.archlinux.org/$aur_package.git" "$aur_src"
chown -R shellybuild:shellybuild "$aur_src"
su -s /bin/bash shellybuild -c "cd '$aur_src' && PATH='$CLICKGEN_VENV/bin':\$PATH PKGDEST='$PKG_OUT' makepkg --nodeps --noconfirm"

mapfile -t BUILT_PACKAGES < <(find "$PKG_OUT" -maxdepth 1 -type f -name '*.pkg.tar.zst' -print | sort)
declare -A BUILT_NAMES=()
for pkg in "${BUILT_PACKAGES[@]}"; do
  name="$(pacman -Qp --print-format '%n' "$pkg")"
  BUILT_NAMES["$name"]=1
done
for required in shelly shelly-flatpak-backend bibata-cursor-theme; do
  if [[ -z "${BUILT_NAMES[$required]:-}" ]]; then
    echo "ERRO: pacote obrigatório não foi gerado: $required" >&2
    printf '%s\\n' "${BUILT_PACKAGES[@]}" >&2
    exit 50
  fi
done
for pkg in "${BUILT_PACKAGES[@]}"; do
  pacman -Qp "$pkg"
  bsdtar -tf "$pkg" >/dev/null
  cp "$pkg" "$REPO_DIR/"
done
repo-add "$REPO_DIR/forja-shelly.db.tar.gz" "$REPO_DIR"/*.pkg.tar.zst

PACMAN_CONF="$WORK/shelly-pacman.conf"
cp /etc/pacman.conf "$PACMAN_CONF"
cat >> "$PACMAN_CONF" <<'REPO'

[forja-shelly]
SigLevel = Optional TrustAll
Server = http://127.0.0.1:8765/$repo/$arch
REPO

python -m http.server 8765 --bind 0.0.0.0 --directory "$REPO_ROOT" > "$WORK/shelly-http.log" 2>&1 &
HTTP_PID=$!
printf '%s\n' "$HTTP_PID" > "$WORK/shelly-http.pid"
for _ in {1..10}; do
  if curl -fsS "http://127.0.0.1:8765/forja-shelly/x86_64/forja-shelly.db" >/dev/null; then break; fi
  sleep 1
done
kill -0 "$HTTP_PID"
pacman --config "$PACMAN_CONF" -Sy --noconfirm
pacman --config "$PACMAN_CONF" -Si shelly >/dev/null
pacman --config "$PACMAN_CONF" -Si shelly-flatpak-backend >/dev/null
pacman --config "$PACMAN_CONF" -Si bibata-cursor-theme >/dev/null
echo "Shelly-ALPM 3.2.1, backend Flatpak e Bibata compilados, empacotados e publicados no repositório HTTP local."
