#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${FORJA_PAMAC_OUTPUT:-/tmp/forja-pamac-output}"
UPSTREAM_COMMIT="363e794fef4f9f6a0e54757fd12155cf27e02cc3"
WORK="$(mktemp -d /tmp/forja-pamac-build.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

for command in curl tar python3 meson ninja valac pkg-config; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Dependência de compilação ausente: $command" >&2
    exit 10
  }
done

pkg-config --exists gtk4 libadwaita-1 pamac || {
  echo "Dependências GTK4, libadwaita ou libpamac ausentes no ambiente Manjaro." >&2
  exit 11
}

ARCHIVE="$WORK/pamac-upstream.tar.gz"
SOURCE="$WORK/pamac-source"
BUILD="$WORK/build"
mkdir -p "$SOURCE" "$OUTPUT/bin" "$OUTPUT/lib" "$OUTPUT/share"

echo "Obtendo Pamac upstream no commit fixo $UPSTREAM_COMMIT"
curl --fail --location --retry 3 --connect-timeout 20 \
  "https://github.com/manjaro/pamac/archive/$UPSTREAM_COMMIT.tar.gz" \
  --output "$ARCHIVE"
tar -xzf "$ARCHIVE" --strip-components=1 -C "$SOURCE"

cp "$ROOT/patches/forja-store.css" "$SOURCE/resources/style.css"

python3 - "$SOURCE" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])

def replace_once(path: str, old: str, new: str) -> None:
    file = root / path
    content = file.read_text()
    count = content.count(old)
    if count != 1:
        raise SystemExit(f"Patch não aplicado com segurança em {path}: esperado 1 ocorrência, encontrado {count}: {old!r}")
    file.write_text(content.replace(old, new, 1))

replace_once(
    "src/manager_window.vala",
    'about.application_name = "Pamac";',
    'about.application_name = "Forja Store";',
)
replace_once(
    "src/manager_window.vala",
    'about.application_icon = "system-software-install";',
    'about.application_icon = "forja-store";',
)
replace_once(
    "src/manager_window.vala",
    'about.comments = dgettext (null, "A Package Manager with Alpm, AUR, Flatpak and Snap support");',
    'about.comments = "Loja de aplicativos da Forja OS, baseada no Pamac, com suporte a repositórios, AUR e Flatpak.";'
)
replace_once(
    "resources/manager_window.ui",
    '<property name="width-request">361</property>',
    '<property name="width-request">760</property>',
)
replace_once(
    "resources/manager_window.ui",
    '<property name="height-request">295</property>',
    '<property name="height-request">520</property>',
)
replace_once(
    "resources/manager_window.ui",
    '<property name="icon-name">system-software-install</property>',
    '<property name="icon-name">forja-store</property>',
)
replace_once(
    "src/local_config.vala",
    'width = 950;',
    'width = 1050;',
)
replace_once(
    "src/local_config.vala",
    'height = 550;',
    'height = 700;',
)

# O código e o motor de transações continuam sendo do Pamac upstream.
# Somente a apresentação, os metadados visuais e o tamanho inicial são alterados.
PY

xmllint --noout "$SOURCE/resources/manager_window.ui" "$SOURCE/resources/package_row.ui"
meson setup "$BUILD" "$SOURCE" --prefix=/usr --sysconfdir=/etc --buildtype=release
meson compile -C "$BUILD" pamac-manager

BINARY="$BUILD/src/pamac-manager"
LIBRARY="$BUILD/src/libpamac-gtk.so"
[[ -x "$BINARY" ]] || { echo "O alvo pamac-manager não foi gerado." >&2; exit 20; }
[[ -f "$LIBRARY" ]] || { echo "A biblioteca libpamac-gtk.so não foi gerada." >&2; exit 21; }

if LD_LIBRARY_PATH="$BUILD/src" ldd "$BINARY" | grep -q 'not found'; then
  LD_LIBRARY_PATH="$BUILD/src" ldd "$BINARY" >&2
  echo "O binário Forja Store possui dependências não resolvidas." >&2
  exit 22
fi

install -m 755 "$BINARY" "$OUTPUT/bin/forja-store"
install -m 755 "$LIBRARY" "$OUTPUT/lib/libpamac-gtk.so"
tar -czf "$OUTPUT/share/pamac-11.7.5-forja-source.tar.gz" -C "$WORK" pamac-source
cat > "$OUTPUT/share/build-info.txt" <<INFO
Pamac upstream commit: $UPSTREAM_COMMIT
Pamac upstream version: 11.7.5
Forja UI: GTK4 + libadwaita
Backend: libpamac
Source archive: /usr/share/doc/forja-store/pamac-11.7.5-forja-source.tar.gz
INFO

if LD_LIBRARY_PATH="$OUTPUT/lib" ldd "$OUTPUT/bin/forja-store" | grep -q 'not found'; then
  LD_LIBRARY_PATH="$OUTPUT/lib" ldd "$OUTPUT/bin/forja-store" >&2
  echo "O binário final não resolve todas as bibliotecas." >&2
  exit 23
fi

echo "Forja Store compilada a partir do Pamac. Binário, biblioteca e fontes preparados em $OUTPUT."
