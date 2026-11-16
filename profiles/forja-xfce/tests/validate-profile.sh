#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo "FALHA: validação interrompida na linha ${LINENO}: ${BASH_COMMAND} (código ${rc})" >&2' ERR
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROFILE="$ROOT/profiles/forja-xfce"
PACKAGES="$PROFILE/packages.x86_64"
DOCKBARX="$PROFILE/forja-packages/dockbarx/PKGBUILD"
DOCKBARX_INSTALL="$PROFILE/forja-packages/dockbarx/dockbarx.install"
DOCKBARX_PLUGIN="$PROFILE/forja-packages/xfce4-dockbarx-plugin/PKGBUILD"
RECOVERY="$PROFILE/forja-packages/forja-recovery"
SNAPSHOTS="$PROFILE/forja-packages/forja-snapshots"
BIBATA="$PROFILE/forja-packages/bibata-cursor-theme/PKGBUILD"
PANEL="$ROOT/desktops/xfce/panel-default.xml"
required=("$PROFILE/profiledef.sh" "$PROFILE/prepare.sh" "$PROFILE/prepare-forja.sh" "$PROFILE/run_before_squashfs.sh" "$PROFILE/apply-forja-live.sh" "$PROFILE/README.md" "$DOCKBARX" "$DOCKBARX_INSTALL" "$DOCKBARX_PLUGIN" "$RECOVERY/PKGBUILD" "$RECOVERY/forja-recovery-cli" "$RECOVERY/forja-recovery-gui" "$RECOVERY/forja-recovery.desktop" "$RECOVERY/README.md" "$SNAPSHOTS/PKGBUILD" "$SNAPSHOTS/forja-snapshot-setup" "$SNAPSHOTS/forja-pacman-snapshot" "$SNAPSHOTS/forja-snapshot-pre.hook" "$SNAPSHOTS/forja-snapshot-setup.service" "$SNAPSHOTS/forja-timeshift-check.service" "$SNAPSHOTS/forja-timeshift-check.timer" "$BIBATA" "$PROFILE/tests/test-snapshots-btrfs.sh" "$ROOT/desktops/xfce/calamares/mount.conf" "$ROOT/desktops/xfce/calamares/partition.conf" "$ROOT/desktops/xfce/install-branding.sh" "$ROOT/desktops/xfce/apply-forja-layout.sh" "$PANEL" "$PROFILE/airootfs/usr/local/bin/forja-update" "$PROFILE/airootfs/usr/share/applications/forja-update.desktop")
for file in "${required[@]}"; do
  [[ -f "$file" ]] || { echo "FALHA: arquivo ausente: $file" >&2; exit 1; }
done
bash -n "$PROFILE/profiledef.sh" "$PROFILE/prepare.sh" "$PROFILE/prepare-forja.sh" "$PROFILE/run_before_squashfs.sh" "$PROFILE/apply-forja-live.sh"
bash -n "$SNAPSHOTS/PKGBUILD" "$SNAPSHOTS/forja-snapshot-setup" "$SNAPSHOTS/forja-pacman-snapshot"
bash -n "$PROFILE/tests/test-snapshots-btrfs.sh"
python3 -m py_compile "$RECOVERY/forja-recovery-cli" "$RECOVERY/forja-recovery-gui" "$PROFILE/airootfs/usr/local/bin/forja-update"
rm -rf "$RECOVERY/__pycache__" "$PROFILE/airootfs/usr/local/bin/__pycache__"
bash -n "$ROOT/desktops/xfce/profile.conf" "$ROOT/desktops/xfce/install-branding.sh" "$ROOT/desktops/xfce/apply-forja-layout.sh"
grep -Fq 'localedef -i pt_BR -f UTF-8 pt_BR.UTF-8' "$ROOT/desktops/xfce/install-branding.sh" || { echo "FALHA: locale pt_BR não é gerado no chroot Live." >&2; exit 1; }

if grep -Eiq 'manjaro|mhwd|pacman-mirrors' "$PACKAGES"; then
  echo "FALHA: pacote exclusivo do Manjaro encontrado." >&2; exit 1
fi
duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES" | awk '{print $1}' | sort | uniq -d)"
[[ -z "$duplicates" ]] || { echo "FALHA: pacotes duplicados: $duplicates" >&2; exit 1; }
for package in timeshift inotify-tools gtk3 python-gobject base xorg-server arch-install-scripts mkinitcpio-archiso mkinitcpio-nfs-utils syslinux dracut eos-dracut linux xfce4 lightdm firefox papirus-icon-theme reflector curl; do
  grep -Fxq "$package" "$PACKAGES" || { echo "FALHA: pacote obrigatório ausente: $package" >&2; exit 1; }
done
if grep -R -Eiq '(^|[[:space:]])snapper([[:space:]]|$)|snapper-' "$PACKAGES" "$SNAPSHOTS" "$RECOVERY"; then
  echo "FALHA: dependencia/referencia ativa ao Snapper encontrada." >&2; exit 1
fi
grep -Fq 'value="dockbarx"' "$PANEL"
grep -Fq 'value="p=11;x=0;y=0"' "$PANEL" || { echo "FALHA: painel XFCE não está centralizado na borda inferior." >&2; exit 1; }
if grep -Eiq 'docklike|xfce4-docklike-plugin' "$PANEL" "$PACKAGES" "$ROOT/desktops/xfce/packages.arch"; then
  echo "FALHA: referência ativa a Docklike encontrada." >&2; exit 1
fi
grep -Fq "depends=('dockbarx' 'xfce4-panel')" "$DOCKBARX_PLUGIN"
grep -Fq "sha256sums=('8df37a367d4454c590d29cbaea9f7a3ec09ddf13905943b3becc717241c275da')" "$DOCKBARX"
grep -Fq "sha256sums=('68d106b2446b89b90423cec00f24f999223fd289ad712bb807eb918670b91eec')" "$DOCKBARX_PLUGIN"
if grep -Eiq 'sha256sums=.*SKIP' "$DOCKBARX" "$DOCKBARX_PLUGIN"; then
  echo "FALHA: checksum SKIP não é permitido nas receitas DockbarX." >&2; exit 1
fi
grep -Fq 'dockbarx-*.pkg.tar.zst' "$PROFILE/prepare.sh"
grep -Fq 'xfce4-dockbarx-plugin-[0-9]*.pkg.tar.zst' "$PROFILE/prepare.sh"
grep -Fq 'local_packages=(/root/packages/*.pkg.tar.zst)' "$PROFILE/prepare-forja.sh"
grep -Fq 'pacman -U --noconfirm --needed -- "${local_packages[@]}"' "$PROFILE/prepare-forja.sh"
grep -Fq "forja-recovery-*.pkg.tar.zst" "$PROFILE/prepare.sh"
grep -Fq "forja-snapshots-*.pkg.tar.zst" "$PROFILE/prepare.sh"
grep -Fxq "grub-btrfs" "$PACKAGES"
grep -Fq "forja-snapshot-setup.service" "$SNAPSHOTS/PKGBUILD"
grep -Fq "forja-timeshift-check.timer" "$SNAPSHOTS/PKGBUILD"
grep -Fq "timeshift --check --scripted" "$SNAPSHOTS/forja-timeshift-check.service"
grep -Fq "When = PreTransaction" "$SNAPSHOTS/forja-snapshot-pre.hook"
grep -Fq "timeshift --create" "$SNAPSHOTS/forja-pacman-snapshot"
grep -Fq "subvolume: /@" "$ROOT/desktops/xfce/calamares/mount.conf"
grep -Fq "subvolume: /@home" "$ROOT/desktops/xfce/calamares/mount.conf"
if grep -Eq 'subvolume: /@(cache|log)' "$ROOT/desktops/xfce/calamares/mount.conf"; then
  echo "FALHA: subvolumes extras incompatíveis com layout simples Timeshift." >&2; exit 1
fi
grep -Fq 'availableFileSystemTypes: ["btrfs"]' "$ROOT/desktops/xfce/calamares/partition.conf"
grep -Fq 'timeshift-gtk' "$RECOVERY/forja-recovery-cli"
grep -Fq 'Timeshift' "$RECOVERY/README.md"
if grep -Eiq "rm[[:space:]]+-rf|mkfs\.|dd[[:space:]]+if=" "$RECOVERY/forja-recovery-cli" "$RECOVERY/forja-recovery-gui"; then
  echo "FALHA: operação destrutiva encontrada no Recovery." >&2; exit 1
fi
grep -Fq '(( ${#local_packages[@]} == 7 ))' "$PROFILE/prepare.sh"
grep -Fq 'bibata-cursor-theme-*.pkg.tar.zst' "$PROFILE/prepare.sh"
grep -Fq "172e33c4ae415278384dcecc7d1a9b7a024266bc944bc751fd86532be1cc6251" "$BIBATA"
grep -Fq '0bbb1280ccd373262561453d85201f2707483990' "$ROOT/.github/workflows/build-forja-iso.yml"
grep -Fq '0bbb1280ccd373262561453d85201f2707483990' "$ROOT/.github/workflows/preflight-forja-xfce.yml"
if grep -Fxq 'calamares' "$PACKAGES"; then
  echo "FALHA: Calamares não deve entrar sem branding e configuração Forja validados." >&2; exit 1
fi
grep -Fq 'não instala o sistema' "$PROFILE/README.md"
grep -Fq "cn1988r-coder/forja-updates" "$PROFILE/airootfs/usr/local/bin/forja-update"
grep -Fq "forja-update --rollback" "$PROFILE/airootfs/usr/local/bin/forja-update"
echo "Validação estática Forja XFCE concluída: Timeshift, GRUB-Btrfs, Recovery e Btrfs; sem ISO."
