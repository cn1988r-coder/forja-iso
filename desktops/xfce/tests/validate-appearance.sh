#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd -- "$ROOT/../.." && pwd)"

for script in "$ROOT/apply-forja-layout.sh" "$ROOT/install-branding.sh" "$ROOT/plymouth/forja-mkinitcpio.conf" "$REPO_ROOT/build-manjaro.sh"; do
  bash -n "$script"
done

for package in \
  adw-gtk-theme materia-gtk-theme papirus-icon-theme papirus-folders \
  bibata-cursor-theme noto-fonts ttf-jetbrains-mono gtk3 libnotify \
  gsettings-desktop-schemas appstream archlinux-appstream-data flatpak base-devel git \
  xfce4-panel dockbarx xfce4-dockbarx-plugin xfce4-whiskermenu-plugin \
  xfce4-pulseaudio-plugin xfce4-power-manager xfce4-notifyd \
  xfce4-clipman-plugin networkmanager network-manager-applet bluez bluez-utils blueman; do
  grep -Fxq "$package" "$ROOT/packages.manjaro" || {
    printf 'Pacote obrigatório ausente no perfil XFCE da Forja: %s\n' "$package" >&2
    exit 1
  }
done

grep -q 'GTK_THEME="adw-gtk3-dark"' "$ROOT/apply-forja-layout.sh"
grep -q 'ICON_THEME="Papirus-Dark"' "$ROOT/apply-forja-layout.sh"
grep -q 'CURSOR_THEME="Bibata-Modern-Classic"' "$ROOT/apply-forja-layout.sh"
grep -q 'set_prop xfwm4 /general/theme string "Materia-dark"' "$ROOT/apply-forja-layout.sh"
grep -q 'set_prop xfwm4 /general/use_compositing bool true' "$ROOT/apply-forja-layout.sh"

# Panel XML must follow the native Xfconf schema: panels array contains panel-1.
grep -q '<property name="panels" type="array">' "$ROOT/panel-default.xml"
grep -q '<property name="panel-1" type="empty">' "$ROOT/panel-default.xml"
grep -q 'value="dockbarx"' "$ROOT/panel-default.xml"
! grep -q 'value="tasklist"' "$ROOT/panel-default.xml"
! grep -q 'panel-2' "$ROOT/panel-default.xml"
grep -q 'value="whiskermenu"' "$ROOT/panel-default.xml"
# Keep native XFCE indicators grouped on the right, with date/time last.
grep -q 'value="systray"' "$ROOT/panel-default.xml"
grep -q 'value="clock"' "$ROOT/panel-default.xml"
grep -q 'value="pulseaudio"' "$ROOT/panel-default.xml"
grep -q 'value="power-manager-plugin"' "$ROOT/panel-default.xml"
grep -q 'value="notification-plugin"' "$ROOT/panel-default.xml"
grep -q 'value="xfce4-clipman-plugin"' "$ROOT/panel-default.xml"
grep -q 'name="size-max" type="uint" value="20"' "$ROOT/panel-default.xml"
grep -q 'name="symbolic-icons" type="bool" value="true"' "$ROOT/panel-default.xml"
grep -q 'name="digital-format" type="string" value="%H:%M&#10;%d/%m/%Y"' "$ROOT/panel-default.xml"
grep -q 'name="tooltip-format" type="string" value="%A, %d de %B de %Y"' "$ROOT/panel-default.xml"
grep -q '#XfcePanelWindow button' "$ROOT/forja-gtk.css"
grep -q 'margin: 3px 3px' "$ROOT/forja-gtk.css"
grep -q 'border-radius: 7px' "$ROOT/forja-gtk.css"

# Parse the Xfconf XML and verify that native indicators are grouped at the right.
python3 - "$ROOT/panel-default.xml" <<'PY'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
plugins = root.find("./property[@name='plugins']")
panels = root.find("./property[@name='panels']/property[@name='panel-1']")
assert plugins is not None and panels is not None
expected = {
    "1": "whiskermenu",
    "2": "dockbarx",
    "3": "xfce4-clipman-plugin",
    "4": "showdesktop",
    "5": "separator",
    "6": "systray",
    "7": "pulseaudio",
    "8": "power-manager-plugin",
    "9": "notification-plugin",
    "10": "clock",
}
for plugin_id, plugin_name in expected.items():
    node = plugins.find(f"./property[@name='plugin-{plugin_id}']")
    assert node is not None and node.attrib.get("value") == plugin_name, (plugin_id, plugin_name)
ids = [node.attrib["value"] for node in panels.findall("./property[@name='plugin-ids']/value")]
assert ids == list(expected), ids
separator = plugins.find("./property[@name='plugin-5']")
assert separator.find("./property[@name='expand']").attrib["value"] == "true"
clock = plugins.find("./property[@name='plugin-10']")
assert clock.find("./property[@name='digital-format']").attrib["value"] == "%H:%M\n%d/%m/%Y"
PY
grep -q 'value="showdesktop"' "$ROOT/panel-default.xml"
grep -q 'name="size-max" type="uint" value="20"' "$ROOT/panel-default.xml"
grep -q 'name="symbolic-icons" type="bool" value="true"' "$ROOT/panel-default.xml"
grep -q 'name="digital-format" type="string" value="%H:%M&#10;%d/%m/%Y"' "$ROOT/panel-default.xml"
grep -q 'name="tooltip-format" type="string" value="%A, %d de %B de %Y"' "$ROOT/panel-default.xml"
! grep -q 'value="tasklist"' "$ROOT/panel-default.xml"
! grep -q 'value="notification-plugin".*value="clock"' "$ROOT/panel-default.xml"
# DockbarX packages are sourced from the signed BigCommunity repository.
grep -q '>community-stable community-keyring' "$ROOT/packages.manjaro"
grep -q '>community-extra dockbarx' "$ROOT/packages.manjaro"
grep -q '>community-extra xfce4-dockbarx-plugin' "$ROOT/packages.manjaro"
grep -q '\[community-extra\]' "$REPO_ROOT/build-manjaro.sh"
grep -q '\[community-stable\]' "$REPO_ROOT/build-manjaro.sh"
grep -q 'https://repo.communitybig.org/\$repo/\$arch' "$REPO_ROOT/build-manjaro.sh"
! grep -Rqi 'docklike' "$ROOT" --exclude='validate-appearance.sh'

# Plymouth: tema Forja, hook mkinitcpio e parâmetros silenciosos do GRUB.
grep -q '^custom_boot_args=(quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 systemd.show_status=false rd.systemd.show_status=false)$' "$ROOT/profile.conf"
test -s "$ROOT/plymouth/forja.plymouth"
test -s "$ROOT/plymouth/forja.script"
grep -q 'Name=Forja OS' "$ROOT/plymouth/forja.plymouth"
grep -q 'Image.Text("FORJA OS"' "$ROOT/plymouth/forja.script"
grep -q 'Plymouth.SetRefreshFunction' "$ROOT/plymouth/forja.script"
grep -q 'HOOKS+=( "plymouth" )' "$ROOT/plymouth/forja-mkinitcpio.conf" || grep -q 'plymouth' "$ROOT/plymouth/forja-mkinitcpio.conf"
grep -q 'quiet splash loglevel=3' "$ROOT/plymouth/forja-grub"
test -s "$ROOT/forja-plymouth/PKGBUILD"
grep -q 'forja-plymouth' "$REPO_ROOT/build-manjaro.sh"
grep -q 'forja-mkinitcpio.conf' "$REPO_ROOT/build-manjaro.sh"
grep -q 'plymouth forja-plymouth' "$REPO_ROOT/build-manjaro.sh"
grep -q 'forja-plymouth' "$REPO_ROOT/build-manjaro.sh"

# Tray applets are supplied by their packages and autostart through XDG.
grep -q 'network-manager-applet' "$ROOT/packages.manjaro"
grep -q 'blueman' "$ROOT/packages.manjaro"
grep -q "'NetworkManager'" "$REPO_ROOT/build-manjaro.sh"
grep -q "'bluetooth'" "$REPO_ROOT/build-manjaro.sh"

# The Forja desktop must never inherit the upstream Manjaro XFCE profile.
grep -q 'TARGET="$PROFILE_ROOT/manjaro/forja-xfce"' "$REPO_ROOT/build-manjaro.sh"
grep -q 'desktops/xfce/profile.conf' "$REPO_ROOT/build-manjaro.sh"
! grep -q 'BASE_PROFILE="$PROFILE_ROOT/manjaro/\$DESKTOP"' "$REPO_ROOT/build-manjaro.sh"
! grep -q 'cp -a "$BASE_PROFILE/.' "$REPO_ROOT/build-manjaro.sh"
grep -q 'rm -rf "$TARGET/live-overlay/etc/skel/.config/xfce4"' "$REPO_ROOT/build-manjaro.sh"

grep -q 'etc/xdg/xfce4/panel/default.xml' "$ROOT/install-branding.sh"
grep -q 'etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml' "$ROOT/install-branding.sh"
grep -q 'panel-default.xml' "$ROOT/install-branding.sh"
! grep -qi 'docklike' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml' "$ROOT/install-branding.sh"
grep -q 'forja-black-wallpaper.svg' "$ROOT/install-branding.sh"
for stock_wallpaper in manjaro-wallpapers-18.0 wallpapers-2018 wallpapers-juhraya illyria-wallpaper manjaro-xfce-settings manjaro-xfce-minimal-settings; do
  grep -q "$stock_wallpaper" "$REPO_ROOT/build-manjaro.sh" || {
    printf 'Pacote de wallpaper/preset XFCE não está excluído: %s\n' "$stock_wallpaper" >&2
    exit 1
  }
done
grep -q 'forja-papirus-folders.service' "$REPO_ROOT/build-manjaro.sh"
grep -q 'papirus-folders -C grey --theme Papirus-Dark' "$REPO_ROOT/build-manjaro.sh"
grep -q 'for overlay_name in desktop-overlay live-overlay' "$REPO_ROOT/build-manjaro.sh"

grep -q 'polkit-gnome' "$ROOT/packages.manjaro"

grep -q '#000000' "$ROOT/forja-black-wallpaper.svg"
grep -q '/usr/share/backgrounds/forja-black.svg' "$ROOT/forja-xfce-desktop.xml"
! grep -RqiE 'forja-xfce-wallpaper|xfce-wallpaper.svg' "$ROOT"


grep -q 'button-title.*Forja OS' "$ROOT/panel-default.xml"
grep -q 'show-button-title.*true' "$ROOT/panel-default.xml"
grep -q 'show-button-icon.*false' "$ROOT/panel-default.xml"
! grep -q 'name="button-icon"' "$ROOT/panel-default.xml"
grep -q 'position-search-alternate.*true' "$ROOT/panel-default.xml"
grep -q 'position-categories-alternate.*true' "$ROOT/panel-default.xml"
grep -q 'menu-width.*480' "$ROOT/panel-default.xml"
grep -q 'menu-height.*500' "$ROOT/panel-default.xml"
grep -q 'Forja OS 2026: Whisker compact' "$ROOT/forja-gtk.css"
grep -q 'box-shadow: 0 14px 38px' "$ROOT/forja-gtk.css"
grep -q 'min-height: 30px' "$ROOT/forja-gtk.css"
grep -q 'whiskermenu-1.rc' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/gtk-3.0/gtk.css' "$ROOT/install-branding.sh"
! grep -q 'etc/xdg/gtk-3.0/gtk.css' "$ROOT/install-branding.sh"
grep -q '#whiskermenu-button:checked' "$ROOT/forja-gtk.css"
grep -Eq 'box-shadow:[[:space:]]*inset[[:space:]]*0[[:space:]]+-2px[[:space:]]+0' "$ROOT/forja-gtk.css"
grep -q '#whiskermenu-window .category-button:checked' "$ROOT/forja-gtk.css"
grep -q '#whiskermenu-window .search-area' "$ROOT/forja-gtk.css"


# Whisker identity must stay monochrome and visually aligned with Adwaita Dark.
grep -q 'fill="#171717"' "$ROOT/forja-flame.svg"
grep -q 'fill="#dededb"' "$ROOT/forja-flame.svg"
! grep -q 'linearGradient\|stop-color=' "$ROOT/forja-flame.svg"
grep -q '@define-color forja_bg #242424' "$ROOT/forja-gtk.css"
grep -q '@define-color forja_surface #303030' "$ROOT/forja-gtk.css"
grep -q '@define-color forja_text #ffffff' "$ROOT/forja-gtk.css"
! grep -qiE '#[0-9a-f]*(00a|08f|f80|f00)' "$ROOT/forja-gtk.css"

# Update badge is intentionally white with a gray check; pending updates use a gray X.


# Btrfs: pacote presente no sistema Live/instalado, padrão do Calamares e compressão zstd.
grep -q 'btrfs-progs' "$REPO_ROOT/build-manjaro.sh"
grep -q 'TARGET/rootfs/etc/calamares/modules/partition.conf' "$REPO_ROOT/build-manjaro.sh"
grep -q 'TARGET/rootfs/etc/calamares/modules/mount.conf' "$REPO_ROOT/build-manjaro.sh"
grep -q '^defaultFileSystemType: "btrfs"$' "$ROOT/calamares/partition.conf"
grep -q 'availableFileSystemTypes: \["btrfs", "ext4", "f2fs"\]' "$ROOT/calamares/partition.conf"
grep -q 'compress=zstd:1' "$ROOT/calamares/mount.conf"
test ! -e "$REPO_ROOT/forja-pamac-pacman"
! grep -RqiE "Forja Store|FORJA_SKIP_STORE_INSTALL" "$REPO_ROOT" --exclude-dir=.git --exclude=validate-appearance.sh
echo "Forja XFCE: aparência e painel DockbarX; Shelly package recipe present."
grep -q '>community-extra dockbarx' "$ROOT/packages.manjaro"
grep -q '>community-extra xfce4-dockbarx-plugin' "$ROOT/packages.manjaro"
grep -q '\[community-extra\]' "$REPO_ROOT/build-manjaro.sh"
grep -q 'https://repo.communitybig.org/\$repo/\$arch' "$REPO_ROOT/build-manjaro.sh"
! grep -Rqi 'docklike' "$ROOT" --exclude='validate-appearance.sh'

# Plymouth: tema Forja, hook mkinitcpio e parâmetros silenciosos do GRUB.
grep -q '^custom_boot_args=(quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 systemd.show_status=false rd.systemd.show_status=false)$' "$ROOT/profile.conf"
test -s "$ROOT/plymouth/forja.plymouth"
test -s "$ROOT/plymouth/forja.script"
grep -q 'Name=Forja OS' "$ROOT/plymouth/forja.plymouth"
grep -q 'Image.Text("FORJA OS"' "$ROOT/plymouth/forja.script"
grep -q 'Plymouth.SetRefreshFunction' "$ROOT/plymouth/forja.script"
grep -q 'HOOKS+=( "plymouth" )' "$ROOT/plymouth/forja-mkinitcpio.conf" || grep -q 'plymouth' "$ROOT/plymouth/forja-mkinitcpio.conf"
grep -q 'quiet splash loglevel=3' "$ROOT/plymouth/forja-grub"
grep -q 'forja-mkinitcpio.conf' "$REPO_ROOT/build-manjaro.sh"
grep -q 'TARGET/rootfs/etc/default/grub' "$REPO_ROOT/build-manjaro.sh"
grep -q 'usr/share/plymouth/themes/forja' "$ROOT/install-branding.sh"

# Tray applets are supplied by their packages and autostart through XDG.
grep -q 'network-manager-applet' "$ROOT/packages.manjaro"
grep -q 'blueman' "$ROOT/packages.manjaro"
grep -q "'NetworkManager'" "$REPO_ROOT/build-manjaro.sh"
grep -q "'bluetooth'" "$REPO_ROOT/build-manjaro.sh"

# The Forja desktop must never inherit the upstream Manjaro XFCE profile.
grep -q 'TARGET="$PROFILE_ROOT/manjaro/forja-xfce"' "$REPO_ROOT/build-manjaro.sh"
grep -q 'desktops/xfce/profile.conf' "$REPO_ROOT/build-manjaro.sh"
! grep -q 'BASE_PROFILE="$PROFILE_ROOT/manjaro/\$DESKTOP"' "$REPO_ROOT/build-manjaro.sh"
! grep -q 'cp -a "$BASE_PROFILE/.' "$REPO_ROOT/build-manjaro.sh"
grep -q 'rm -rf "$TARGET/live-overlay/etc/skel/.config/xfce4"' "$REPO_ROOT/build-manjaro.sh"

grep -q 'etc/xdg/xfce4/panel/default.xml' "$ROOT/install-branding.sh"
grep -q 'etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml' "$ROOT/install-branding.sh"
grep -q 'panel-default.xml' "$ROOT/install-branding.sh"
! grep -qi 'docklike' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml' "$ROOT/install-branding.sh"
grep -q 'forja-black-wallpaper.svg' "$ROOT/install-branding.sh"
for stock_wallpaper in manjaro-wallpapers-18.0 wallpapers-2018 wallpapers-juhraya illyria-wallpaper manjaro-xfce-settings manjaro-xfce-minimal-settings; do
  grep -q "$stock_wallpaper" "$REPO_ROOT/build-manjaro.sh" || {
    printf 'Pacote de wallpaper/preset XFCE não está excluído: %s\n' "$stock_wallpaper" >&2
    exit 1
  }
done
grep -q 'forja-papirus-folders.service' "$REPO_ROOT/build-manjaro.sh"
grep -q 'papirus-folders -C grey --theme Papirus-Dark' "$REPO_ROOT/build-manjaro.sh"
grep -q 'for overlay_name in desktop-overlay live-overlay' "$REPO_ROOT/build-manjaro.sh"

grep -q 'polkit-gnome' "$ROOT/packages.manjaro"

grep -q '#000000' "$ROOT/forja-black-wallpaper.svg"
grep -q '/usr/share/backgrounds/forja-black.svg' "$ROOT/forja-xfce-desktop.xml"
! grep -RqiE 'forja-xfce-wallpaper|xfce-wallpaper.svg' "$ROOT"


! grep -q 'name="button-icon"' "$ROOT/panel-default.xml"
grep -q 'show-button-icon.*false' "$ROOT/panel-default.xml"
grep -q 'position-search-alternate.*true' "$ROOT/panel-default.xml"
grep -q 'position-categories-alternate.*true' "$ROOT/panel-default.xml"
grep -q 'menu-width.*480' "$ROOT/panel-default.xml"
grep -q 'menu-height.*500' "$ROOT/panel-default.xml"
grep -q 'Forja OS 2026: Whisker compact' "$ROOT/forja-gtk.css"
grep -q 'box-shadow: 0 14px 38px' "$ROOT/forja-gtk.css"
grep -q 'min-height: 30px' "$ROOT/forja-gtk.css"
grep -q 'whiskermenu-1.rc' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/gtk-3.0/gtk.css' "$ROOT/install-branding.sh"
! grep -q 'etc/xdg/gtk-3.0/gtk.css' "$ROOT/install-branding.sh"
grep -q '#whiskermenu-button:checked' "$ROOT/forja-gtk.css"
grep -Eq 'box-shadow:[[:space:]]*inset[[:space:]]*0[[:space:]]+-2px[[:space:]]+0' "$ROOT/forja-gtk.css"
grep -q '#whiskermenu-window .category-button:checked' "$ROOT/forja-gtk.css"
grep -q '#whiskermenu-window .search-area' "$ROOT/forja-gtk.css"


# Whisker identity must stay monochrome and visually aligned with Adwaita Dark.
grep -q 'fill="#171717"' "$ROOT/forja-flame.svg"
grep -q 'fill="#dededb"' "$ROOT/forja-flame.svg"
! grep -q 'linearGradient\|stop-color=' "$ROOT/forja-flame.svg"
grep -q '@define-color forja_bg #242424' "$ROOT/forja-gtk.css"
grep -q '@define-color forja_surface #303030' "$ROOT/forja-gtk.css"
grep -q '@define-color forja_text #ffffff' "$ROOT/forja-gtk.css"
! grep -qiE '#[0-9a-f]*(00a|08f|f80|f00)' "$ROOT/forja-gtk.css"

# Update badge is intentionally white with a gray check; pending updates use a gray X.


# Btrfs: pacote presente no sistema Live/instalado, padrão do Calamares e compressão zstd.
grep -q 'btrfs-progs' "$REPO_ROOT/build-manjaro.sh"
grep -q 'TARGET/rootfs/etc/calamares/modules/partition.conf' "$REPO_ROOT/build-manjaro.sh"
grep -q 'TARGET/rootfs/etc/calamares/modules/mount.conf' "$REPO_ROOT/build-manjaro.sh"
grep -q '^defaultFileSystemType: "btrfs"$' "$ROOT/calamares/partition.conf"
grep -q 'availableFileSystemTypes: \["btrfs", "ext4", "f2fs"\]' "$ROOT/calamares/partition.conf"
grep -q 'compress=zstd:1' "$ROOT/calamares/mount.conf"
echo "Forja XFCE: perfil sem Pamac; receita Shelly 3.3.0 e autostart presentes."
# Shelly UI must be installed as a system-wide XFCE session autostart entry.
test -s "$ROOT/shelly-autostart.desktop"
grep -q '^Exec=/usr/bin/shelly-ui$' "$ROOT/shelly-autostart.desktop"
grep -q '^X-GNOME-Autostart-enabled=true$' "$ROOT/shelly-autostart.desktop"
grep -q 'shelly-autostart.desktop' "$ROOT/install-branding.sh"
grep -q 'etc/xdg/autostart/shelly.desktop' "$ROOT/install-branding.sh"

# Português brasileiro: locale gerado durante a montagem e definido globalmente.
grep -q '^LANG=pt_BR.UTF-8$' "$ROOT/install-branding.sh"
grep -q '^LANGUAGE=pt_BR:pt:en$' "$ROOT/install-branding.sh"
grep -q '^pt_BR.UTF-8 UTF-8$' "$ROOT/install-branding.sh"
grep -q 'localedef --prefix="$DEST" -i pt_BR -f UTF-8 pt_BR.UTF-8' "$ROOT/install-branding.sh"
grep -q 'localedef --prefix="$DEST" -i en_US -f UTF-8 en_US.UTF-8' "$ROOT/install-branding.sh"

# Plymouth: hook deve ser inserido imediatamente após udev ou systemd.
grep -q 'Theme=forja' "$ROOT/plymouth/plymouthd.conf"
grep -q 'splash' "$ROOT/profile.conf"
grep -q 'quiet splash loglevel=3' "$ROOT/plymouth/forja-grub"
grep -q 'if [[ "$_forja_plymouth_added" -eq 0 && ( "$_forja_hook" == "udev" || "$_forja_hook" == "systemd" ) ]]' "$ROOT/plymouth/forja-mkinitcpio.conf"
! grep -q 'append.*plymouth.*fallback' "$ROOT/plymouth/forja-mkinitcpio.conf"

echo "Forja XFCE: locale pt_BR, Plymouth, painel e Shelly configurados."
