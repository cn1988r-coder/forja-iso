# Desktop modules

Desktop packages and desktop-session configuration live here, separately from all operating-system bases. A base builder must not install a desktop's tools.

## XFCE

The XFCE module has independent package manifests for Arch Linux, Manjaro, and Ubuntu LTS. It includes XFCE Goodies and the Whisker Menu plugin, plus Firefox, Materia Dark, Papirus, and Bibata as desktop-level choices.

`apply-mint-layout.sh` configures the XFCE session with a full-width bottom panel, Whisker Menu at the left, a window list, system tray, clock, and show-desktop control. It deliberately leaves the distribution's default XFCE wallpaper unchanged; the Forja branding does not replace desktop backgrounds. Install it as `/usr/lib/forja/apply-xfce-mint-layout.sh` and install `forja-xfce-mint-layout.desktop` in `/etc/xdg/autostart/`.

## MATE

The Ubuntu MATE package manifest is independent of the Ubuntu base. The Manjaro MATE image includes `mate-backgrounds` and keeps the MATE desktop's native wallpaper instead of applying a Forja background.

## Integration status

These are desktop-module definitions. The current cloud ISO entry point and Manjaro builder still need refactoring before the selection can build all base/desktop combinations. The Ubuntu base builder remains base-only.
