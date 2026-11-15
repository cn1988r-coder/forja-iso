# Forja Software for Ubuntu MATE

Forja Software is an independent Pamac-inspired software center for Ubuntu. It uses the Ubuntu package system (APT/DPKG) and the Flatpak client. It is not Pamac and does not use pacman.

## Features implemented in this Ubuntu-only component

- One GTK4 application with a combined catalogue and source filter for Ubuntu APT and system Flatpak.
- Search by package/application name, ID and short description.
- Views for all available items, installed items and available updates.
- Install, remove and update individual APT packages.
- Install and remove system Flatpak applications from remotes already configured on the machine.
- Separate APT and Flatpak update actions in the MATE panel indicator.
- Privileged operations use pkexec and a restricted helper.

The catalogue is sourced from the machine's configured APT repositories and configured system Flatpak remotes. Forja does not host packages, add third-party repositories, add Flathub automatically, or install Snap.

## Continuous updates without changing Ubuntu release

APT updates use `apt-get update` and `apt-get --with-new-pkgs upgrade`. This updates packages and allows newly required dependencies without automatically removing installed packages. It does not run `full-upgrade`, `dist-upgrade` or `do-release-upgrade`.

Flatpak applications update through the system Flatpak installation. The installed Ubuntu LTS release series remains unchanged. This is continuous package maintenance within a fixed LTS release, not a rolling-release distribution. Ubuntu LTS releases have a finite support lifetime; the manager never silently changes the system to a newer release.

## Runtime dependencies

See `packages.ubuntu`. Flatpak is optional at runtime, but required for Flatpak catalogue and transactions. If Flatpak or configured system remotes are absent, APT remains usable.

## Installation files

- `src/forja-store`: GTK4 software center.
- `src/forja-apt-transaction`: restricted privileged APT and system Flatpak transaction helper.
- `src/forja-update-indicator`: Ayatana indicator for MATE panel.
- `install.sh`: installs the applications, helper, launchers and MATE autostart entry.

## Validation status

Source-level checks do not prove operation on a real Ubuntu installation. Before shipping in an ISO, run the installer in a clean Ubuntu MATE VM, then test APT search/install/remove/update, Flatpak search/install/remove/update, pkexec cancellation, panel autostart and reboot persistence. Do not label it production-ready until these tests pass.

## License

Independent implementation inspired by Pamac's user experience. No Pamac source code is copied or redistributed.
