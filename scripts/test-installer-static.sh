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
resolve_line="$(grep -nF 'pacman -Sp --noconfirm --needed' "$BACKEND" | cut -d: -f1)"
[[ -n "$sync_line" && -n "$resolve_line" && -n "$wipe_line" && "$sync_line" -lt "$resolve_line" && "$resolve_line" -lt "$wipe_line" ]] ||
  fail "todos os pacotes precisam ser resolvidos antes de apagar o disco"
wipe_line="$(grep -nF 'wipefs --all --force' "$BACKEND" | cut -d: -f1)"
[[ -n "$sync_line" && -n "$wipe_line" && "$sync_line" -lt "$wipe_line" ]] ||
  fail "sincronização dos repositórios precisa ocorrer antes de apagar o disco"

! grep -Fq '\narch-chroot' "$BACKEND" ||
  fail "comandos arch-chroot ainda estão concatenados por sequência literal \\n"
grep -Fq 'arch-chroot "$MNT" dconf update' "$BACKEND" || fail "dconf update ausente"
grep -Fq 'arch-chroot "$MNT" mkinitcpio -P' "$BACKEND" || fail "mkinitcpio não é executado"
grep -Fq 'systemctl enable NetworkManager.service bluetooth.service lightdm.service' "$BACKEND" ||
  fail "serviços essenciais não são habilitados"


SERVICE="$ROOT/build/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf"
INITRAMFS="$ROOT/build/airootfs/etc/mkinitcpio.conf.d/archiso.conf"
GRUB="$ROOT/build/grub/grub.cfg"
SYSLINUX="$ROOT/build/syslinux/archiso_sys-linux.cfg"

grep -Fxq 'StandardOutput=tty' "$SERVICE" || fail "saida do instalador TUI nao esta ligada ao terminal"
grep -Fxq 'StandardError=tty' "$SERVICE" || fail "erros do instalador TUI nao estao ligados ao terminal"
grep -Fq 'mount "$P1" "$MNT/boot/efi"' "$BACKEND" || fail "particao EFI nao e montada em /boot/efi"
grep -Fq 'grub-install --target=x86_64-efi --efi-directory=/boot/efi' "$BACKEND" || fail "GRUB UEFI nao usa o ponto de montagem EFI"
grep -Fq 'Iniciar instalador VENOM OS' "$GRUB" || fail "entrada GRUB nao identifica o instalador"
grep -Fq 'Instalador VENOM OS' "$SYSLINUX" || fail "entrada Syslinux nao identifica o instalador"
! grep -Eiq 'archiso_pxe_(nbd|http|nfs)' "$INITRAMFS" || fail "hooks PXE sem dependencias foram mantidos na midia USB"
! grep -Fq 'StandardOutput=journal' "$SERVICE" || fail "TUI esta sendo enviada ao journal em vez do terminal"
! grep -Fq 'Nenhuma operacao de disco e executada nesta versao' "$TUI" || fail "mensagem antiga contradiz o backend conectado"
! grep -Fq 'Requisitos da instalacao offline' "$TUI" || fail "rotulo offline contradiz o backend online"

printf 'OK: TUI, boot, EFI, idioma, teclado, fuso e backend estaticamente verificados.\n'

grep -Fxq dconf "$ROOT/build/install-packages-xfce.x86_64" || fail "dconf ausente na edicao XFCE"
grep -Fxq dconf "$ROOT/build/install-packages-mate.x86_64" || fail "dconf ausente na edicao MATE"
