# VENOM OS XFCE

## Scope

Preserve the original XFCE desktop structure and layout: panel, docklike plugin, Whisker menu, workspace settings, keyboard shortcuts, Thunar settings, window-manager preferences, and session defaults. The configuration files are carried in the VENOM OS overlay after removing vendor artwork, icons, launchers, and wallpaper references.

Retained applications: Firefox and Pamac GTK. IPTVnator is installed on first login from the AUR as `iptvnator-bin`.

Other bundled applications and vendor identity packages are excluded. The dark theme remains enabled. The operating-system identity, validation job, compilation job, and published artifact use only the name VENOM OS.

The current signed package source is used only for the XFCE panel plugin and required trust packages. The obsolete `repo.biglinux.com.br` URL is not used.

## Installer

This test image does not include Calamares. The final VENOM OS installer is a separate component and must not be replaced with a third-party installer.

## Test status

A successful static validation is not proof that the ISO compiles or boots. The workflow must complete before an ISO artifact can be reported.
