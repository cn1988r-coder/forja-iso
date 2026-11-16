# Forja OS XFCE on EndeavourOS

This is the first profile layer for building Forja XFCE on top of the official
EndeavourOS modified Archiso project. It does not replace or modify the Manjaro
builder or the upstream EndeavourOS checkout.

## Current scope

- EndeavourOS/Archiso profile definition and boot modes.
- Initial Arch + EndeavourOS package set for XFCE, LightDM and Forja visual assets.
- Preparation script that creates a separate `forja-xfce-profile` directory from
  an existing EndeavourOS-ISO checkout.
- Live-session integration hook for the Forja XFCE defaults.

## Preparation

1. Clone the official EndeavourOS-ISO repository.
2. Run `prepare-forja.sh` from this directory, setting
   `ENDEAVOUROS_ISO_DIR` to the upstream checkout if it is not the current directory.
3. Review the generated `forja-xfce-profile` directory before building.

The profile wraps the upstream `run_before_squashfs.sh`: it runs the original EndeavourOS
live-user preparation first, then executes the Forja XFCE live-session hook in the
prepared airootfs before squashfs creation.

## Important incomplete items

- The upstream EndeavourOS live-session currently has KDE-oriented assets and
  package assumptions. They still need to be removed or replaced in the Forja profile.
- The Calamares package is not currently provided by the upstream package list;
  use a compatible EndeavourOS Calamares build and test its XFCE branding/configuration.
- Shelly and other Forja-specific applications need verified Arch/EndeavourOS package
  builds before being added to the image.
- Plymouth/dracut integration is not included until the dracut configuration and
  boot behavior can be validated.
- Package availability and dependency resolution must be checked on an EndeavourOS
  build host before any ISO build.

No ISO build is started by these scripts.
