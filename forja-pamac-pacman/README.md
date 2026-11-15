# Forja Update + Forja Software (Arch / Manjaro)

GTK interface inspired by the Pamac workflow, with native package backends.

## Repository sources and updates
- **Manjaro packages:** use only the repositories and mirror list configured by Manjaro (`pacman` / `pacman-mirrors`). Forja is not a package mirror.
- **Flatpak apps:** use the official Flathub remote (`https://dl.flathub.org/repo/flathub.flatpakrepo`). No Forja repository is added.
- **Arch packages:** use the repositories configured by Arch.
- System upgrades run `pacman -Syu`, followed by system Flatpak updates. The logged-in user's Flatpak installation is updated in the user session, without running it as root.
- Update checks use `checkupdates` for Pacman and Flatpak's configured remote update listing. No unsafe `pacman -Sy` partial-upgrade operation is used.

## Components
- `forja-store`: GTK4 package browser with Installed, Search and Updates views.
- `forja-update-indicator`: Ayatana indicator for XFCE and MATE panels.
- `forja-pacman-transaction`: restricted privileged helper for Pacman and system Flatpak transactions.
- `pamac-inspired.svg`: custom P-shaped app/status icon, not original Pamac artwork.

## Status
The Manjaro MATE image installs Flatpak and enables a first-boot system service that registers the official Flathub remote with signature verification enabled. CI validates Python syntax, transaction mapping, package-name validation, installer shell syntax and the Manjaro builder preflight. The GTK interface and panel indicator still require a booted ISO test; they are not certified as runtime-tested.
