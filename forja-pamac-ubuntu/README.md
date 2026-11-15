# Forja Software for Ubuntu LTS

Ubuntu-focused adaptation of the Pamac-style software manager. The intended interface follows Pamac's application layout; the package backend is native to Ubuntu.

## Supported software sources

- **Ubuntu APT repositories:** primary source for package search, installation, removal and system updates. APT must use the mirrors and repositories configured on the user's Ubuntu installation, including enabled Ubuntu LTS updates and security pockets.
- **Flatpak:** optional second source for applications, using Flatpak remotes already configured by the user or distribution. The application must show the source clearly and must not silently add third-party remotes.
- **Snap: not supported.** Do not install snapd, show Snap packages, or expose Snap actions or services.

## Separation of responsibilities

The Forja repository stores source code and release artifacts only. It is not an APT repository, package mirror, Flatpak remote, or update server.

APT package metadata and downloads come from the Ubuntu repositories and mirrors configured on the target system. Flatpak metadata and downloads come only from the Flatpak remotes configured on that system.

## Implementation notes

The APT backend must use APT/python-apt for package metadata and transactions. System upgrades must use the normal APT transaction path and must not perform partial upgrades. Flatpak support must use the system Flatpak installation and configured remotes, without adding Flathub or another remote automatically.

The visual target is the original Pamac experience: application browsing, categories, search, package details, installed applications, updates and a panel update indicator. This is a compatibility project, not a claim that the current prototype already implements every screen or backend.

## Current status

The current Ubuntu frontend is an early prototype. It currently queries APT only. Flatpak integration, the complete Pamac-style UI, build integration and runtime testing are still pending. It has not been validated on Ubuntu and must not yet be included in a released ISO.

## Runtime dependencies

See packages.ubuntu. Snap-related packages and services are intentionally excluded.

## Licensing

Pamac is GPL-3.0. This prototype currently uses an independent APT frontend and does not copy Pamac source files. If Pamac source code is incorporated later, retain its GPL-3.0 notices and comply with the license.