# VENOM OS Community MATE port

Base: `CommunityBigLinux/iso-profiles-big-comm`, profile `bigcommunity/xfce`.
Working branch: `feature/venom-bigcommunity-mate`.

This edition keeps the Manjaro ISO profile/build model and the existing BigCommunity Calamares integration, but replaces the desktop package selection with MATE. The XFCE package set and XFCE-specific desktop configuration are not carried into the new profile.

## Kept intentionally

- Manjaro base, live boot dependencies, MHWD driver support and ISO build tooling.
- MATE, MATE Extra, LightDM, NetworkManager applet, BlueZ/Blueman and PipeWire.
- The existing BigCommunity Calamares package integration and its repository signing key, because this is the currently available Calamares setup. Its branding assets are overlaid with VENOM OS artwork and dark colors.
- Calamares installation logic is not rewritten by this port.

## Removed from the desktop selection

The XFCE desktop packages and the BigLinux/BigCommunity application bundle, branded icon packs, wallpapers, and branded live/GRUB helpers are excluded. The BigLinux repository is retained only under the local repository label `venom-community` to retrieve the existing Calamares integration package and its signing key.

## VENOM defaults

- MATE session with LightDM.
- Adwaita-dark, Papirus-Dark, Bibata Modern Classic.
- Black/dark desktop background with layered VENOM wordmark.
- Gear icon as the generic MATE menu start icon.
- Black GRUB console and Plymouth spinner.
- Calamares branding uses VENOM OS name, a layered 3D-style SVG wordmark, and a dark blue/black palette.

## Validation/build gate

The workflow runs `scripts/validate-bigcommunity-mate.sh` first. The ISO build job has `needs: validate`, so compilation cannot start if static checks fail. A successful static validation is not a substitute for testing the Live session and a real Calamares installation; those still need post-build verification.
