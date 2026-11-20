#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/manjaro/venom-mate"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

for f in profile.conf Packages-Root Packages-Desktop Packages-Live Packages-Mhwd; do
  [[ -s "$PROFILE/$f" ]] || fail "arquivo de perfil ausente: $f"
done
[[ -s "$PROFILE/desktop-overlay/usr/local/bin/manjaro-mate-dark-complete.sh" ]] || fail "script original ausente do overlay"
[[ -s "$PROFILE/desktop-overlay/usr/share/applications/venom-mate-setup.desktop" ]] || fail "atalho do configurador ausente"
cmp -s "$ROOT/scripts/manjaro-mate-dark-complete.sh" "$PROFILE/desktop-overlay/usr/local/bin/manjaro-mate-dark-complete.sh" || fail "cópia do script diverge do original"
bash -n "$ROOT/scripts/manjaro-mate-dark-complete.sh" || fail "sintaxe do script original inválida"
bash -n "$ROOT/scripts/build-venom-iso.sh" || fail "sintaxe do construtor inválida"
! grep -Eiq 'calamares|archiso|endeavouros' "$PROFILE/Packages-Root" "$PROFILE/Packages-Desktop" "$PROFILE/Packages-Live" "$PROFILE/profile.conf" || fail "componente proibido no perfil ativo"
grep -Fxq 'mate' "$PROFILE/Packages-Desktop" || fail "grupo MATE ausente"
grep -Fxq 'mate-extra' "$PROFILE/Packages-Desktop" || fail "grupo MATE Extra ausente"
grep -Fxq 'lightdm' "$PROFILE/Packages-Desktop" || fail "LightDM ausente"
grep -Fq 'displaymanager="lightdm"' "$PROFILE/profile.conf" || fail "LightDM não selecionado"
grep -Fq 'Manjaro Linux' "$ROOT/README.md" || fail "base Manjaro não documentada"
pass "perfil Manjaro MATE, LightDM e pacotes"
pass "script DeepSeek preservado byte a byte no overlay"
pass "nenhum Calamares, Archiso ou EndeavourOS no perfil ativo"
