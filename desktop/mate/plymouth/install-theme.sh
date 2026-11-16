#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_ROOT="${1:-/}"
LOGO_SOURCE="${2:-/usr/share/forja/branding/forja-flame.svg}"
THEME_DIR="$TARGET_ROOT/usr/share/plymouth/themes/forja"
SPINNER_DIR="$TARGET_ROOT/usr/share/plymouth/themes/spinner"

[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
[[ -d "$SPINNER_DIR" ]] || { echo "Tema spinner do Plymouth não encontrado: $SPINNER_DIR" >&2; exit 1; }
[[ -s "$LOGO_SOURCE" ]] || { echo "Logo da Forja não encontrado: $LOGO_SOURCE" >&2; exit 1; }
command -v rsvg-convert >/dev/null 2>&1 || { echo "rsvg-convert (librsvg) não encontrado." >&2; exit 1; }

install -d "$THEME_DIR" "$TARGET_ROOT/etc/plymouth"
cp -a "$SPINNER_DIR/." "$THEME_DIR/"
install -m 0644 "$(dirname -- "${BASH_SOURCE[0]}")/forja.plymouth" "$THEME_DIR/forja.plymouth"

tmp_svg="$(mktemp)"
trap 'rm -f "$tmp_svg"' EXIT
sed 's/fill="#050505"/fill="#f2f2f2"/' "$LOGO_SOURCE" > "$tmp_svg"
rsvg-convert -w 256 -h 256 "$tmp_svg" > "$THEME_DIR/watermark.png"

cat > "$TARGET_ROOT/etc/plymouth/plymouthd.conf" <<'EOF'
[Daemon]
Theme=forja
ShowDelay=0
DeviceScale=1
EOF

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme forja
fi
echo "Tema de inicialização Forja OS instalado em $THEME_DIR"
