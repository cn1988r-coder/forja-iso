# BuildMaker LXQt Dark

A lightweight LXQt desktop profile with a complete custom dark visual identity. LXQt remains the desktop environment; Openbox is its lightweight window manager. No KDE Plasma, SDDM, XFCE session, or MATE session is installed.

## Interface
- One full-width 40 px bottom panel, left-aligned application menu and task list, system tray and clock at the right.
- Native LXQt application menu with search, categories and favorites; application launchers use installed desktop entries.
- Dark GTK theme, dark Qt palette, Papirus-Dark icons and Bibata-Modern-Ice cursor.
- LightDM with LightDM GTK Greeter, using a matching dark greeter.
- No blur, transparency, compositor effects or heavy animations.
- Pamac, Firefox and Calamares are installed and exposed through their desktop entries.

## Apply
Run `sudo bash scripts/install-lxqt-dark.sh` on the target Manjaro system or from the live-session customization stage. The script is idempotent and writes defaults into `/etc/skel` as well as the current user's configuration.

## Notes
The greeter is LightDM GTK Greeter, not SDDM. The desktop is LXQt, not XFCE/MATE/KDE. Theme settings are applied to GTK and Qt applications; applications with their own rendering engines may need app-specific theme settings.
