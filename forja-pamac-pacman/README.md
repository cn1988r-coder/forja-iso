# Forja Update + Forja Software (Arch / Manjaro)

GTK interface inspired by the Pamac workflow, with a Pacman backend. This is a separate implementation and does not copy Pamac source code.

## Variants
- Arch Linux: blue accent.
- Manjaro: green accent.
- Both use pacman and the native repositories of the selected distribution.

## Components
- `forja-store`: GTK4 package browser with Installed, Search and Updates views.
- `forja-update-indicator`: Ayatana indicator for XFCE and MATE panels.
- `forja-pacman-transaction`: narrow privileged helper. It accepts only refresh-check, install, remove and full-upgrade actions; package names are validated.
- `pamac-inspired.svg`: custom P-shaped app/status icon, not the original Pamac artwork.

## Safety
Updates are checked with `checkupdates` from pacman-contrib. The application never runs `pacman -Sy` by itself. System upgrades always use `pacman -Syu` to avoid partial upgrades. Privileged operations are requested through PolicyKit.

## Status
The installer is now staged into the Manjaro MATE ISO desktop overlay, with its runtime dependencies and panel autostart entry. CI checks Python syntax, transaction mapping, package-name validation, installer shell syntax, and the Manjaro builder preflight. The GTK interface and panel indicator still require a booted ISO test on a live Manjaro MATE session; they are not yet certified as runtime-tested. Arch integration remains separate.
