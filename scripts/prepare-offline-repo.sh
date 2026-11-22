#!/usr/bin/env bash
# Monta o repositorio autocontido que acompanha a ISO VENOM.
# Execute em um ambiente Arch Linux atualizado, como root.
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ "$EUID" -eq 0 ]] || { echo "Execute em Arch Linux como root." >&2; exit 1; }
command -v pacman >/dev/null || { echo "pacman ausente." >&2; exit 1; }
command -v repo-add >/dev/null || { echo "repo-add ausente (pacman)." >&2; exit 1; }

AUR_DIR="$ROOT/build/aur-packages"
OUT="$ROOT/build/offline-repo"
[[ -d "$AUR_DIR" ]] || { echo "Crie build/aur-packages e coloque os pacotes AUR compilados ali." >&2; exit 1; }
[[ ! -e "$OUT" ]] || { echo "$OUT já existe. Mova-o manualmente antes de gerar outro bundle; nada foi apagado." >&2; exit 1; }

declare -a AUR_FILES=("$AUR_DIR"/*.pkg.tar.zst)
[[ -f "${AUR_FILES[0]}" ]] || { echo "Nenhum .pkg.tar.zst encontrado em $AUR_DIR." >&2; exit 1; }
declare -A FOUND=()
for pkg in "${AUR_FILES[@]}"; do
  name="$(pacman -Qp --print-format '%n' "$pkg")"
  FOUND["$name"]=1
done
for required in archlinux-appstream-data-pamac libpamac-aur pamac-aur ferdium-bin; do
  [[ -n "${FOUND[$required]:-}" ]] || {
    echo "Pacote AUR obrigatório ausente: $required. Compile-o e coloque o arquivo em $AUR_DIR." >&2
    exit 1
  }
done

WORK="$(mktemp -d "$ROOT/work-offline-repo.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/repo"
DBPATH="$WORK/db"
mkdir -p "$STAGE" "$DBPATH"

for pkg in "${AUR_FILES[@]}"; do install -m 0644 "$pkg" "$STAGE/"; done
repo-add "$STAGE/venom.db.tar.gz" "$STAGE"/*.pkg.tar.zst

CONF="$WORK/pacman-build.conf"
cat > "$CONF" <<EOF
[options]
Architecture = auto
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional TrustAll

[venom]
SigLevel = Optional TrustAll
Server = file://$STAGE

[core]
Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch

[extra]
Include = /etc/pacman.d/mirrorlist
EOF

mapfile -t PACKAGES < <(
  cat "$ROOT/build/install-packages-xfce.x86_64" "$ROOT/build/install-packages-mate.x86_64" |
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' | sort -u
)
(("${#PACKAGES[@]}" > 0)) || { echo "Manifestos vazios." >&2; exit 1; }

echo "[VENOM] Sincronizando repositórios oficiais e resolvendo a união XFCE + MATE + AUR."
pacman --config "$CONF" --dbpath "$DBPATH" --cachedir "$STAGE" -Sy --noconfirm
pacman --config "$CONF" --dbpath "$DBPATH" --cachedir "$STAGE" -Sw --noconfirm --needed "${PACKAGES[@]}"

echo "[VENOM] Criando índice único com pacotes oficiais e AUR."
repo-add --remove "$STAGE/venom.db.tar.gz" "$STAGE"/*.pkg.tar.zst

VERIFY_CONF="$WORK/pacman-offline.conf"
VERIFY_DB="$WORK/verify-db"
mkdir -p "$VERIFY_DB"
cat > "$VERIFY_CONF" <<EOF
[options]
Architecture = auto
SigLevel = Optional TrustAll

[venom]
SigLevel = Optional TrustAll
Server = file://$STAGE
EOF

echo "[VENOM] Testando resolução sem acesso aos repositórios online."
pacman --config "$VERIFY_CONF" --dbpath "$VERIFY_DB" --cachedir "$STAGE" -Sy --noconfirm
pacman --config "$VERIFY_CONF" --dbpath "$VERIFY_DB" --cachedir "$STAGE" -Sp --noconfirm --needed "${PACKAGES[@]}" >/dev/null

mkdir -p "$(dirname "$OUT")"
cp -a "$STAGE" "$OUT"
(cd "$ROOT" && sha256sum build/install-packages-xfce.x86_64 build/install-packages-mate.x86_64) > "$OUT/venom-manifest.sha256"
echo "[VENOM] Bundle offline concluído: $OUT"
echo "[VENOM] Arquivos: $(find "$OUT" -maxdepth 1 -type f | wc -l)"
echo "[VENOM] Tamanho: $(du -sh "$OUT" | awk '{print $1}')"
