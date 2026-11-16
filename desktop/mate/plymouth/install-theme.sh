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

# Add Plymouth to the existing initramfs hook chain without discarding
# Archiso's special hooks or the target system's encryption/filesystem hooks.
mkinitcpio_conf="$TARGET_ROOT/etc/mkinitcpio.conf"
archiso_conf="$TARGET_ROOT/etc/mkinitcpio.conf.d/archiso.conf"
if [[ -f "$archiso_conf" ]]; then
    mkinitcpio_conf="$archiso_conf"
fi
if [[ -f "$mkinitcpio_conf" ]]; then
    hooks_line="$(grep -m1 '^HOOKS=' "$mkinitcpio_conf" || true)"
    if [[ -n "$hooks_line" && "$hooks_line" != *plymouth* ]]; then
        if [[ "$hooks_line" == *" udev"* ]]; then
            hooks_line="${hooks_line/ udev/ udev plymouth}"
        elif [[ "$hooks_line" == *" systemd"* ]]; then
            hooks_line="${hooks_line/ systemd/ plymouth systemd}"
        else
            echo "Não foi possível inserir o hook Plymouth em $mkinitcpio_conf" >&2
            exit 1
        fi
        sed -i "/^HOOKS=/c\\$hooks_line" "$mkinitcpio_conf"
    fi
else
    echo "Configuração mkinitcpio não encontrada em $TARGET_ROOT/etc." >&2
    exit 1
fi

# Brand the installed GRUB menu and request the Plymouth splash at boot.
grub_defaults="$TARGET_ROOT/etc/default/grub"
if [[ -f "$grub_defaults" ]]; then
    if grep -q '^GRUB_DISTRIBUTOR=' "$grub_defaults"; then
        sed -i 's|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR="Forja OS"|' "$grub_defaults"
    else
        printf '%s\n' 'GRUB_DISTRIBUTOR="Forja OS"' >> "$grub_defaults"
    fi
    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub_defaults"; then
        if ! grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub_defaults" | grep -q 'quiet'; then
            sed -i -E '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"[[:space:]]*$/ quiet splash"/' "$grub_defaults"
        elif ! grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub_defaults" | grep -q 'splash'; then
            sed -i -E '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"[[:space:]]*$/ splash"/' "$grub_defaults"
        fi
    else
        printf '%s\n' 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' >> "$grub_defaults"
    fi
fi

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme forja
fi
echo "Plymouth Forja OS configurado em $TARGET_ROOT"
