#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TUI="$ROOT/installer/src/tui.c"
BACKEND="$ROOT/build/airootfs/usr/lib/venom/install-system"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }

grep -Fq 'g_strdup("pt_BR.UTF-8")' "$TUI" || fail "idioma pt_BR.UTF-8 não está fixo no instalador"
grep -Fq 'g_strdup("br-abnt2")' "$TUI" || fail "teclado br-abnt2 não está fixo no instalador"
grep -Fq 'pt_BR.UTF-8' "$BACKEND" || fail "backend não valida pt_BR.UTF-8"
grep -Fq 'br-abnt2' "$BACKEND" || fail "backend não valida br-abnt2"
grep -Fq 'America/Sao_Paulo' "$BACKEND" || fail "fuso America/Sao_Paulo não é aplicado"
! grep -Fq 'const char *const locales[]' "$TUI" || fail "menu de idioma ainda permite escolhas não autorizadas"
! grep -Fq 'const char *const keyboards[]' "$TUI" || fail "menu de teclado ainda permite escolhas não autorizadas"
! grep -Fq 'preflight_argv' "$TUI" || fail "preflight de rede duplicado permanece no frontend"

sync_line="$(grep -nFx 'pacman -Sy --noconfirm' "$BACKEND" | cut -d: -f1)"
wipe_line="$(grep -nF 'wipefs --all --force' "$BACKEND" | cut -d: -f1)"
[[ -n "$sync_line" && -n "$wipe_line" && "$sync_line" -lt "$wipe_line" ]] ||
  fail "sincronização dos repositórios precisa ocorrer antes de apagar o disco"

! grep -Fq '\narch-chroot' "$BACKEND" ||
  fail "comandos arch-chroot ainda estão concatenados por sequência literal \\n"
grep -Fq 'arch-chroot "$MNT" dconf update' "$BACKEND" || fail "dconf update ausente"
grep -Fq 'arch-chroot "$MNT" mkinitcpio -P' "$BACKEND" || fail "mkinitcpio não é executado"
grep -Fq 'systemctl enable NetworkManager.service bluetooth.service lightdm.service' "$BACKEND" ||
  fail "serviços essenciais não são habilitados"

printf 'OK: idioma, teclado, fuso, ordem segura de sincronização e comandos do backend.\n'
