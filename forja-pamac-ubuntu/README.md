# Forja Software

A Pamac-inspired software manager for the Ubuntu LTS edition of Forja.

This is a new Ubuntu frontend, not a binary copy of Pamac. The Pamac project is GPL-3.0 and uses libalpm/libpamac, which is specific to Arch-family package management. Forja Software keeps the GTK-style application workflow while using Ubuntu's native APT and python-apt interfaces.

## Intended experience

- Modern GTK4 window with search, package list, installed packages and updates.
- Install, remove and update actions backed by APT.
- A separate panel indicator for XFCE and MATE, using Ayatana AppIndicator.
- Notifications when updates are available.
- Ubuntu official repositories only. No Mint repositories, PPAs or Arch components.
- Ubuntu LTS release policy remains controlled by the base.

## Current status

This directory is the initial source prototype. It is not a finished or validated package. It must be built and tested on Ubuntu 26.04 LTS before being added to the ISO manifests.

## Runtime dependencies

- python3
- python3-apt
- python3-gi
- gir1.2-gtk-4.0
- gir1.2-ayatanaappindicator3-0.1
- policykit-1

The Pamac project is GPL-3.0. This initial Forja implementation is a separate APT frontend inspired by Pamac's user experience; it does not copy Pamac source files. If Pamac source code is incorporated later, preserve its GPL-3.0 notices and comply with the license.
