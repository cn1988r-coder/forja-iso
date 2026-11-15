#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Execute como root."; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESTDIR="${DESTDIR:-}"
target() { printf "%s%s" "$DESTDIR" "$1"; }
. /etc/os-release
case "${ID:-arch}" in
  manjaro) ICON="$ROOT/icons/forja-pamac-manjaro.svg" ;;
  arch) ICON="$ROOT/icons/forja-pamac-arch.svg" ;;
  *) echo "Esta instalação suporta somente Arch Linux e Manjaro."; exit 1 ;;
esac
install -d "$(target /usr/lib/forja)" "$(target /usr/bin)" \
  "$(target /usr/share/icons/hicolor/scalable/apps)" \
  "$(target /etc/xdg/autostart)" "$(target /usr/share/applications)" \
  "$(target /usr/share/polkit-1/actions)"
install -m 755 "$ROOT/src/forja-store" "$(target /usr/lib/forja/forja-store)"
install -m 755 "$ROOT/src/forja-update-indicator" "$(target /usr/lib/forja/forja-update-indicator)"
install -m 755 "$ROOT/src/forja-pacman-transaction" "$(target /usr/lib/forja/forja-pacman-transaction)"
install -m 755 "$ROOT/bin/forja-store" "$(target /usr/bin/forja-store)"
install -m 755 "$ROOT/bin/forja-update-indicator" "$(target /usr/bin/forja-update-indicator)"
install -m 644 "$ICON" "$(target "/usr/share/icons/hicolor/scalable/apps/$(basename "$ICON")")"
install -m 644 "$ROOT/forja-update-indicator.desktop" "$(target /etc/xdg/autostart/forja-update-indicator.desktop)"
install -m 644 "$ROOT/forja-software.desktop" "$(target /usr/share/applications/forja-software.desktop)"
cat > "$(target /usr/share/polkit-1/actions/br.forja.software.policy)" <<'POLICY'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN" "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <vendor>Forja</vendor>
  <action id="br.forja.software.pacman">
    <description>Gerenciar pacotes do sistema</description>
    <message>Autentique-se para gerenciar pacotes</message>
    <defaults><allow_any>auth_admin</allow_any><allow_inactive>auth_admin</allow_inactive><allow_active>auth_admin_keep</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/lib/forja/forja-pacman-transaction</annotate>
  </action>
</policyconfig>
POLICY
if [[ -z "$DESTDIR" ]]; then gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true; fi
echo "Forja Software instalado."
