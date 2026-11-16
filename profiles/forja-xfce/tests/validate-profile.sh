#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROFILE="$ROOT/profiles/forja-xfce"
PACKAGES="$PROFILE/packages.x86_64"
DOCKBARX="$PROFILE/forja-packages/dockbarx/PKGBUILD"
DOCKBARX_INSTALL="$PROFILE/forja-packages/dockbarx/dockbarx.install"
DOCKBARX_PLUGIN="$PROFILE/forja-packages/xfce4-dockbarx-plugin/PKGBUILD"
RECOVERY="$PROFILE/forja-packages/forja-recovery"
SNAPSHOTS="$PROFILE/forja-packages/forja-snapshots"
PANEL="$ROOT/desktops/xfce/panel-default.xml"
required=("$PROFILE/profiledef.sh" "$PROFILE/prepare.sh" "$PROFILE/prepare-forja.sh" "$PROFILE/run_before_squashfs.sh" "$PROFILE/apply-forja-live.sh" "$PROFILE/README.md" "$DOCKBARX" "$DOCKBARX_INSTALL" "$DOCKBARX_PLUGIN" "$RECOVERY/PKGBUILD" "$RECOVERY/forja-recovery-cli" "$RECOVERY/forja-recovery-gui" "$RECOVERY/forja-recovery.desktop" "$RECOVERY/README.md" "$SNAPSHOTS/PKGBUILD" "$SNAPSHOTS/forja-snapshot-setup" "$SNAPSHOTS/forja-pacman-snapshot" "$SNAPSHOTS/forja-snapshot-pre.hook" "$SNAPSHOTS/forja-snapshot-post.hook" "$SNAPSHOTS/forja-snapshot-setup.service" "$PROFILE/tests/test-snapshots-btrfs.sh" "$ROOT/desktops/xfce/calamares/mount.conf" "$ROOT/desktops/xfce/calamares/partition.conf" "$ROOT/desktops/xfce/install-branding.sh" "$ROOT/desktops/xfce/apply-forja-layout.sh" "$PANEL" "$PROFILE/airootfs/usr/local/bin/forja-update" "$PROFILE/airootfs/usr/share/applications/forja-update.desktop")
for file in "${required[@]}"; do
  [[ -f "$file" ]] || { echo "FALHA: arquivo ausente: $file" >&2; exit 1; }
done
bash -n "$PROFILE/profiledef.sh"
bash -n "$PROFILE/prepare.sh"
bash -n "$PROFILE/prepare-forja.sh"
bash -n "$PROFILE/run_before_squashfs.sh"
bash -n "$PROFILE/apply-forja-live.sh"
python3 -m py_compile "$PROFILE/airootfs/usr/local/bin/forja-update"
rm -rf "$PROFILE/airootfs/usr/local/bin/__pycache__"
bash -n "$RECOVERY/PKGBUILD"
bash -n "$SNAPSHOTS/PKGBUILD"
bash -n "$SNAPSHOTS/forja-snapshot-setup"
bash -n "$SNAPSHOTS/forja-pacman-snapshot"
bash -n "$PROFILE/tests/test-snapshots-btrfs.sh"
python3 -m py_compile "$RECOVERY/forja-recovery-cli" "$RECOVERY/forja-recovery-gui"
rm -rf "$RECOVERY/__pycache__"
bash -n "$ROOT/desktops/xfce/profile.conf"
bash -n "$ROOT/desktops/xfce/install-branding.sh"
bash -n "$ROOT/desktops/xfce/apply-forja-layout.sh"
if grep -Eiq 'manjaro|mhwd|pacman-mirrors' "$PACKAGES"; then
  echo "FALHA: pacote exclusivo do Manjaro encontrado." >&2
  exit 1
fi
duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES" | awk '{print $1}' | sort | uniq -d)"
[[ -z "$duplicates" ]] || { echo "FALHA: pacotes duplicados: $duplicates" >&2; exit 1; }
for package in snapper inotify-tools gtk3 python-gobject base xorg-server arch-install-scripts mkinitcpio-archiso mkinitcpio-nfs-utils syslinux dracut eos-dracut linux xfce4 lightdm firefox papirus-icon-theme bibata-cursor-theme reflector curl; do
  grep -Fxq "$package" "$PACKAGES" || { echo "FALHA: pacote obrigatório ausente: $package" >&2; exit 1; }
done
grep -Fq 'value="dockbarx"' "$PANEL"
if grep -Eiq 'docklike|xfce4-docklike-plugin' "$PANEL" "$PACKAGES" "$ROOT/desktops/xfce/packages.arch"; then
  echo "FALHA: referência ativa a Docklike encontrada." >&2
  exit 1
fi
grep -Fq "depends=('dockbarx' 'xfce4-panel')" "$DOCKBARX_PLUGIN"
grep -Fq "sha256sums=('8df37a367d4454c590d29cbaea9f7a3ec09ddf13905943b3becc717241c275da')" "$DOCKBARX"
grep -Fq "sha256sums=('68d106b2446b89b90423cec00f24f999223fd289ad712bb807eb918670b91eec')" "$DOCKBARX_PLUGIN"
if grep -Eiq 'sha256sums=.*SKIP' "$DOCKBARX" "$DOCKBARX_PLUGIN"; then
  echo "FALHA: checksum SKIP não é permitido nas receitas DockbarX." >&2
  exit 1
fi
grep -Fq 'dockbarx-*.pkg.tar.zst' "$PROFILE/prepare.sh"
grep -Fq 'xfce4-dockbarx-plugin-[0-9]*.pkg.tar.zst' "$PROFILE/prepare.sh"
grep -Fq 'local_packages=(/root/packages/*.pkg.tar.zst)' "$PROFILE/prepare-forja.sh"
grep -Fq 'pacman -U --noconfirm --needed -- "${local_packages[@]}"' "$PROFILE/prepare-forja.sh"
grep -Fq 'for required in profiledef.sh prepare.sh run_before_squashfs.sh pacman.conf' "$PROFILE/prepare-forja.sh"
grep -Fq 'for required_dir in airootfs efiboot syslinux' "$PROFILE/prepare-forja.sh"
grep -Fq 'cp -a "$UPSTREAM_ROOT/efiboot" "$TARGET/"' "$PROFILE/prepare-forja.sh"
grep -Fq 'cp -a "$UPSTREAM_ROOT/syslinux" "$TARGET/"' "$PROFILE/prepare-forja.sh"
grep -Fq "forja-recovery-*.pkg.tar.zst" "$PROFILE/prepare.sh"
grep -Fq "forja-snapshots-*.pkg.tar.zst" "$PROFILE/prepare.sh"
grep -Fq "grub-btrfs" "$PROFILE/prepare.sh"
grep -Fq "shelly-bin-[0-9]*.pkg.tar.zst" "$PROFILE/prepare.sh"
grep -Fq "shelly-flatpak-backend-bin-[0-9]*.pkg.tar.zst" "$PROFILE/prepare.sh"
grep -Fq "forja-snapshot-setup.service" "$SNAPSHOTS/PKGBUILD"
grep -Fq "snapper-timeline.timer" "$SNAPSHOTS/forja-snapshot-setup"
grep -Fq "grub-btrfsd.service" "$SNAPSHOTS/forja-snapshot-setup"
grep -Fq "When = PreTransaction" "$SNAPSHOTS/forja-snapshot-pre.hook"
grep -Fq "When = PostTransaction" "$SNAPSHOTS/forja-snapshot-post.hook"
grep -Fq "subvolume: /@" "$ROOT/desktops/xfce/calamares/mount.conf"
grep -Fq "subvolume: /@home" "$ROOT/desktops/xfce/calamares/mount.conf"
grep -Fq "availableFileSystemTypes: [\"btrfs\"]" "$ROOT/desktops/xfce/calamares/partition.conf"
grep -Fq "forja-recovery-cli diagnose" "$RECOVERY/README.md"
if grep -Eiq "rm[[:space:]]+-rf|mkfs\\.|dd[[:space:]]+if=" "$RECOVERY/forja-recovery-cli" "$RECOVERY/forja-recovery-gui"; then
  echo "FALHA: operação destrutiva não permitida no núcleo inicial do Recovery." >&2
  exit 1
fi
grep -Fq 'cp -a "$PROFILE_DIR/airootfs/." "$TARGET/airootfs/"' "$PROFILE/prepare-forja.sh"
grep -Fq '"$TARGET/airootfs/root/liveuser.png"' "$PROFILE/prepare-forja.sh"
grep -Fq '(( ${#local_packages[@]} == 7 ))' "$PROFILE/prepare.sh"
grep -Fq '0bbb1280ccd373262561453d85201f2707483990' "$ROOT/.github/workflows/build-forja-iso.yml"
grep -Fq '0bbb1280ccd373262561453d85201f2707483990' "$ROOT/.github/workflows/preflight-forja-xfce.yml"
if grep -Fxq 'calamares' "$PACKAGES"; then
  echo "FALHA: Calamares não deve entrar sem branding e configuração Forja validados." >&2
  exit 1
fi
grep -Fq 'não instalará o sistema pelo Calamares' "$PROFILE/README.md"
grep -Fq "cn1988r-coder/forja-updates" "$PROFILE/airootfs/usr/local/bin/forja-update"
grep -Fq "forja-update --rollback" "$PROFILE/airootfs/usr/local/bin/forja-update"
if grep -Eq "forja-updates.*(pacman.conf|Server =)" "$PROFILE/airootfs/usr/local/bin/forja-update"; then echo "FALHA: Forja Updates não pode ser configurado como repositório pacman." >&2; exit 1; fi
echo "Validação estática do perfil Forja XFCE/EndeavourOS concluída (DockbarX, Recovery, Snapshots Btrfs e Forja Updates; sem ISO)."
