#!/usr/bin/env bash
# Verifica o bundle local sem consultar repositórios externos.
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$ROOT/build/offline-repo"
[[ -s "$REPO/offline.db" ]] || { echo "Índice offline.db ausente." >&2; exit 1; }
compgen -G "$REPO/*.pkg.tar.*" >/dev/null || { echo "Nenhum pacote no repositório offline." >&2; exit 1; }
if [[ -s "$REPO/venom-manifest.sha256" ]]; then
  (cd "$ROOT" && sha256sum -c "$REPO/venom-manifest.sha256")
else
  echo "Assinatura de manifestos ausente no bundle offline." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/db"
CONF="$TMP/pacman.conf"
cat > "$CONF" <<EOF
[options]
Architecture = auto
SigLevel = Optional TrustAll

[iso-offline]
SigLevel = Optional TrustAll
Server = file://$REPO
EOF

mapfile -t PACKAGES < <(
  cat "$ROOT/build/install-packages-xfce.x86_64" "$ROOT/build/install-packages-mate.x86_64" |
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' | sort -u
)
pacman --config "$CONF" --dbpath "$TMP/db" --cachedir "$REPO" -Sy --noconfirm
pacman --config "$CONF" --dbpath "$TMP/db" --cachedir "$REPO" -Sp --noconfirm --needed "${PACKAGES[@]}" >/dev/null
echo "OK: todos os pacotes e dependências das edições XFCE/MATE estão disponíveis offline."
