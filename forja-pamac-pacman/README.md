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
Initial source implementation. It has not yet been built or tested on live Arch or Manjaro installations. The current ISO builders and desktop manifests still need to be wired to install and enable these components.
