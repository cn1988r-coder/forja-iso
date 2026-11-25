#!/usr/bin/env bash
# Explicit build entry point. Never called by static validation or on push.
# Usage: sudo ./build.sh   (ou ./build.sh — ele re-executa com sudo)
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Resolve caminho absoluto do próprio script ANTES de qualquer cd/exec
# ---------------------------------------------------------------------------
SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
ROOT="$(cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)"
cd "$ROOT"

# ---------------------------------------------------------------------------
# Re-executa como root, preservando ambiente e argumentos
# ---------------------------------------------------------------------------
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "ERRO: é necessário root ou sudo instalado." >&2
        exit 1
    fi
    exec sudo -E -- bash "$SCRIPT_PATH" "$@"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die() { printf 'ERRO: %s\n' "$*" >&2; exit 1; }
log() { printf '[VENOM] %s\n' "$*"; }

cleanup() {
    local rc=$?
    if (( rc != 0 )); then
        printf '[VENOM] Falha (código %d). work/ preservado para inspeção.\n' "$rc" >&2
    fi
    return $rc
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Pré-requisitos
# ---------------------------------------------------------------------------
mkdir -p out

for tool in pacman mkarchiso git cmake ninja repo-add sha256sum find install ln; do
    command -v "$tool" >/dev/null 2>&1 \
        || die "'$tool' não encontrado no ambiente Arch de construção."
done

[[ -s build/profiledef.sh ]]       || die "build/profiledef.sh ausente ou vazio."
[[ -s build/packages.x86_64 ]]     || die "build/packages.x86_64 ausente ou vazio."
[[ -d build/airootfs ]]            || die "build/airootfs/ ausente."
[[ -f scripts/validate-xfce-profile.sh ]]     || die "script validate-xfce-profile.sh ausente."
[[ -f scripts/build-aur-packages.sh ]]        || die "script build-aur-packages.sh ausente."
[[ -f scripts/stage-installer-payload.sh ]]   || die "script stage-installer-payload.sh ausente."
[[ -f scripts/test-calamares-ui.sh ]]         || die "script test-calamares-ui.sh ausente."

# Espaço livre mínimo em $ROOT (mkarchiso precisa de folga)
AVAIL_KB="$(df -Pk "$ROOT" | awk 'NR==2 {print $4}')"
MIN_KB=$((6 * 1024 * 1024))   # 6 GiB
(( AVAIL_KB >= MIN_KB )) \
    || die "espaço insuficiente em $ROOT (livre: $((AVAIL_KB/1024)) MiB, mínimo: $((MIN_KB/1024)) MiB)."

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
rm -rf work
mkdir -p work

BUILD_ID="$(date -u +%Y%m%dT%H%M%SZ)"
BUILD_OUT="$ROOT/out/venom-$BUILD_ID"
mkdir -p "$BUILD_OUT"

MARKER="$BUILD_OUT/.build-start"
touch "$MARKER"

mkarchiso -v -w work -o "$BUILD_OUT" build

# Pega só ISO criado DEPOIS do marcador (evita pegar lixo antigo)
ISO="$(find "$BUILD_OUT" -maxdepth 1 -type f -name '*.iso' -newer "$MARKER" -print -quit)"
[[ -n "$ISO" && -s "$ISO" ]] || die "Archiso terminou sem gerar arquivo ISO válido."

# Grava sha256 de forma atômica (sem pipe que possa mascarar falha)
HASH_FILE="$ISO.sha256"
TMP_HASH="$(mktemp "${HASH_FILE}.XXXXXX")"
if ! sha256sum "$ISO" > "$TMP_HASH"; then
    rm -f "$TMP_HASH"
    die "falha ao calcular sha256 de $ISO"
fi
mv -f "$TMP_HASH" "$HASH_FILE"

rm -f "$MARKER"

log "ISO criada: $ISO"
log "Checksum:   $HASH_FILE"
