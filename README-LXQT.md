# BuildMaker LXQt Dark

A lightweight LXQt desktop profile with a complete custom dark visual identity. LXQt remains the desktop environment; Openbox is its lightweight window manager. No KDE Plasma, SDDM, XFCE session, or MATE session is installed.

## Interface
- One full-width 46 px bottom panel.
- Fancy Menu with search, categories and favorites.
- Grouped taskbar: windows from the same application share one task button.
- System monitor, tray, volume, network and clock on the right.
- Dark graphite/black styling with electric-blue accents, Papirus-Dark icons and Bibata-Modern-Ice cursor.
- LightDM with LightDM GTK Greeter.
- No blur, transparency, compositor effects or heavy animations.
- Pamac, Firefox and Calamares are included in the desktop package profile.

## Personalize the panel
The panel uses LXQt's native graphical editor. It is not a fixed, unchangeable bar.

- Right-click an empty area of the panel and open **Manage Widgets** to add, remove or reorder panel items.
- To move an individual widget, right-click it and choose **Move**; then place it where you want on the panel.
- Use **Configure Panel** to change the panel's position, length, height and appearance.
- Keep the panel unlocked while editing. Use **Lock This Panel** only after finishing, to prevent accidental changes.
- Add application launchers to the **Quick Launch** area by dragging application icons onto it. Remove unwanted launchers from their context menu.

The widget list also supports drag-and-drop ordering and the up/down controls. These are standard LXQt panel features, so changes are made visually without editing configuration files or using the terminal.

## Apply
Run `sudo bash scripts/install-lxqt-dark.sh` on the target Manjaro/Arch system or from the live-session customization stage. The script is idempotent and writes defaults into `/etc/skel` as well as the current user's configuration.

## Notes
The greeter is LightDM GTK Greeter, not SDDM. The desktop is LXQt, not XFCE/MATE/KDE. Calamares still requires its own validated configuration and installer-module setup before the ISO can be considered install-ready.
