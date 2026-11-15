#!/usr/bin/env bash
# Install the Ubuntu MATE desktop profile and Forja Software on Ubuntu only.
set -Eeuo pipefail

[[ "$EUID" -eq 0 ]] || { echo "Execute com sudo." >&2; exit 1; }
ROOT="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$ROOT/packages.ubuntu"
PROFILE="$ROOT/apply-ubuntu-mate.sh"
[[ -f "$MANIFEST" && -f "$PROFILE" ]] || { echo "Manifesto ou perfil MATE ausente." >&2; exit 1; }

mapfile -t packages < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$MANIFEST")
apt-get update
apt-get install -y "${packages[@]}"

install -Dm755 "$PROFILE" /usr/lib/forja/apply-ubuntu-mate.sh
install -d /etc/xdg/autostart
cat > /etc/xdg/autostart/forja-ubuntu-mate-visual.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Forja MATE visual profile
Comment=Apply the Forja theme, icons and cursor
Exec=/usr/lib/forja/apply-ubuntu-mate.sh
Terminal=false
OnlyShowIn=MATE;
X-GNOME-Autostart-enabled=true
DESKTOP
chmod 644 /etc/xdg/autostart/forja-ubuntu-mate-visual.desktop

if [[ -x "$ROOT/../../forja-pamac-ubuntu/install.sh" ]]; then
  "$ROOT/../../forja-pamac-ubuntu/install.sh"
else
  echo "Forja Software não está ao lado do módulo MATE; instale-o separadamente."
fi

echo "Perfil Ubuntu MATE instalado. A aparência será aplicada no próximo login MATE."
