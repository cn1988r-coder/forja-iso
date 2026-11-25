#!/usr/bin/env bash
# Explicit build entry point. Never called by static validation or on push.
# Usage: sudo ./build.sh   (ou ./build.sh — re-executa com sudo)
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Resolve caminho absoluto do próprio script ANTES de cd/exec
# ---------------------------------------------------------------------------
SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
ROOT="$(cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)"
cd "$ROOT"

# ---------------------------------------------------------------------------
# Re-executa como root, preservando PATH e argumentos
# ---------------------------------------------------------------------------
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 || {
        printf 'ERRO: é necessário root ou sudo instalado.\n' >&2
        exit 1
    }
    exec sudo -E env "PATH=$PATH" bash "$SCRIPT_PATH" "$@"
fi

# ---------------------------------------------------------------------------
# Helpers e estado de limpeza
# ---------------------------------------------------------------------------
die() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
log() { printf '[VENOM] %s\n' "$*"; }

BUILD_MARKER=""
LOCK_FD=9
LOCK_FILE="$ROOT/.venom-build.lock"

cleanup() {
    local rc=$?
    if [[ -n "${BUILD_MARKER:-}" && -f "$BUILD_MARKER" ]]; then
        rm -f "$BUILD_MARKER"
    fi
    if (( rc != 0 )); then
        printf '[VENOM] Falha (código %d). work/ preservado para inspeção.\n' "$rc" >&2
    fi
    exit "$rc"
}
trap cleanup EXIT

# Evita duas execuções simultâneas do build no mesmo workspace
exec 9>"$LOCK_FILE"
flock -n "$LOCK_FD" || die "Já existe um build em andamento ($LOCK_FILE)."

# ---------------------------------------------------------------------------
# Pré-requisitos
# ---------------------------------------------------------------------------
for tool in pacman mkarchiso git cmake ninja repo-add sha256sum find install ln df awk umount; do
    command -v "$tool" >/dev/null 2>&1 \
        || die "'$tool' não encontrado no ambiente Arch de construção."
done

# Perfil mínimo (validação profunda fica a cargo do validate-xfce-profile.sh)
[[ -s build/profiledef.sh ]]   || die "build/profiledef.sh ausente ou vazio."
[[ -s build/packages.x86_64 ]] || die "build/packages.x86_64 ausente ou vazio."
[[ -d build/airootfs ]]        || die "build/airootfs/ ausente."

# Scripts auxiliares obrigatórios
for s in validate-xfce-profile.sh build-aur-packages.sh \
         stage-installer-payload.sh test-calamares-ui.sh; do
    [[ -f "scripts/$s" ]] || die "script scripts/$s ausente."
done

# Serviço systemd que será habilitado
[[ -f build/airootfs/etc/systemd/system/venom-live-setup.service ]] \
    || die "venom-live-setup.service ausente em build/airootfs/etc/systemd/system/."

# Espaço livre mínimo configurável (padrão: 6 GiB)
MIN_GIB="${VENOM_MIN_FREE_GIB:-6}"
[[ "$MIN_GIB" =~ ^[0-9]+$ ]] || die "VENOM_MIN_FREE_GIB inválido: $MIN_GIB"
AVAIL_KB="$(df -Pk --output=avail "$ROOT" | awk 'NR==2 {print $1}')"
[[ "$AVAIL_KB" =~ ^[0-9]+$ ]] || die "não foi possível determinar espaço livre em $ROOT."
MIN_KB=$((MIN_GIB * 1024 * 1024))
(( AVAIL_KB >= MIN_KB )) \
    || die "espaço insuficiente em $ROOT (livre: $((AVAIL_KB/1024)) MiB, mínimo: $((MIN_KB/1024)) MiB)."

mkdir -p "$ROOT/out"

# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------
log "Etapa 1/6: validação estática do perfil."
bash scripts/validate-xfce-profile.sh

log "Etapa 2/6: preparação dos pacotes AUR declarados."
bash scripts/build-aur-packages.sh

log "Etapa 3/6: preparação do instalador Calamares e payload."
bash scripts/stage-installer-payload.sh

log "Etapa 4/6: validação do payload Calamares antes do Archiso."
bash scripts/test-calamares-ui.sh

log "Etapa 5/6: ativando venom-live-setup.service no multi-user.target."
install -d -m 0755 build/airootfs/etc/systemd/system/multi-user.target.wants
ln -sfn ../venom-live-setup.service \
    build/airootfs/etc/systemd/system/multi-user.target.wants/venom-live-setup.service

log "Etapa 6/6: geração da ISO com Archiso oficial."

# Limpa work/ com segurança (desmonta submontagens ativas dentro de work/)
if [[ -d "$ROOT/work" ]]; then
    while IFS= read -r mnt; do
        [[ -n "$mnt" ]] && umount -l "$mnt" 2>/dev/null || true
    done < <(awk -v w="$ROOT/work" '$2 == w || index($2, w "/") == 1 {print $2}' /proc/mounts | sort -r)
    rm -rf "$ROOT/work"
fi
mkdir -p "$ROOT/work"

BUILD_ID="$(date -u +%Y%m%dT%H%M%SZ)"
BUILD_OUT="$ROOT/out/venom-$BUILD_ID"
mkdir -p "$BUILD_OUT"

# Snapshot de ISOs existentes antes do mkarchiso
declare -A BEFORE_MAP=()
while IFS= read -r -d '' iso_path; do
    BEFORE_MAP["$(basename -- "$iso_path")"]=1
done < <(find "$BUILD_OUT" -maxdepth 1 -type f -name '*.iso' -print0 2>/dev/null)

BUILD_MARKER="$BUILD_OUT/.build-in-progress"
: > "$BUILD_MARKER"

mkarchiso -v -w "$ROOT/work" -o "$BUILD_OUT" "$ROOT/build"

# Localiza o novo arquivo .iso gerado
ISO=""
while IFS= read -r -d '' candidate; do
    base_name="$(basename -- "$candidate")"
    if [[ -z "${BEFORE_MAP[$base_name]:-}" && -s "$candidate" ]]; then
        ISO="$candidate"
        break
    fi
done < <(find "$BUILD_OUT" -maxdepth 1 -type f -name '*.iso' -print0 2>/dev/null)

[[ -n "$ISO" ]] || die "Archiso terminou sem gerar arquivo ISO novo/válido."

# Checksum atômico
HASH_FILE="$ISO.sha256"
TMP_HASH="$(mktemp "${HASH_FILE}.XXXXXX")"
if ! sha256sum "$ISO" > "$TMP_HASH"; then
    rm -f "$TMP_HASH"
    die "falha ao calcular sha256 de $ISO"
fi
mv -f "$TMP_HASH" "$HASH_FILE"

rm -f "$BUILD_MARKER"
BUILD_MARKER=""

log "ISO criada: $ISO"
log "Checksum:   $HASH_FILE"
