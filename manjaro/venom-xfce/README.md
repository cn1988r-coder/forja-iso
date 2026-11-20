# VENOM OS

This profile preserves the original XFCE panel layout, docklike panel, Whisker menu, workspace settings, keyboard shortcuts, Thunar settings, window-manager preferences, and XFCE session defaults. Those configuration files are carried in the VENOM OS overlay with vendor artwork, icons, launchers, and wallpaper references removed or replaced.

Retained applications:
- Firefox
- Pamac GTK
- Ferdium, installed on first login as `ferdium-bin` from the AUR
- IPTVnator, installed on first login as `iptvnator-bin` from the AUR

Ferdium and IPTVnator are installed through Pamac's AUR support during first login. The dark theme remains enabled. The current signed package source is used for the XFCE panel plugin and required trust package only. No obsolete repository URL is configured.

The ISO is branded **VENOM OS XFCE 1.0**. The GitHub Actions workflow validates the profile before compiling it and publishes the artifact as `VENOM-OS-XFCE-1.0`.

This test ISO does not include Calamares. The final VENOM OS installer remains a separate project component.
