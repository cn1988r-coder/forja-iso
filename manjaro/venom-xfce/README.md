# VENOM OS XFCE 1.0

This is the Manjaro-based VENOM OS XFCE Community edition. Its desktop configuration follows the upstream Community XFCE layout and behavior, with VENOM identity replacing the upstream product artwork and launchers.

## Desktop

- One bottom panel, 100% width and 40 px height.
- Original Community plugin order, Whisker menu, Docklike, tray, audio, power, notifications, clipboard and two-line date/time.
- Community dark GTK/XFWM theme, Papient Dark icons, Bibata cursor and Noto Nerd fonts.
- Firefox and Pamac GTK.
- Ferdium and IPTVnator are installed at first login through Pamac AUR support as `ferdium-bin` and `iptvnator-bin`.

The profile vendors the selected upstream Community XFCE settings and XFWM4 decoration assets, retaining the upstream license. It installs the required GTK theme, icon, cursor and font packages without importing the upstream package's BigLinux-specific session hooks. Upstream configuration licensing is retained in `UPSTREAM-LICENSES`.

## Installer

Calamares is included in the Live session. Its Manjaro installation sequence is configured in `live-overlay/etc/calamares/settings.conf`, with VENOM OS branding under `live-overlay/etc/calamares/branding/venom`. The application menu contains **Install VENOM OS**. MHWD integration is enabled in the profile.

## Package signatures

The Community Stable repository uses its actual database name, `community-stable`. The workflow trusts the full signing-key fingerprint published by the upstream Community keyring repository through Manjaro's `additional-trusted-gpg` mechanism. Package signature checking remains enabled; TrustAll is not used.

## Release gate

`scripts/validate-venom-xfce.sh` is the strict pre-build gate. Pushes run validation only. The ISO build job is gated behind an explicit manual workflow dispatch and must not be started until every required check is green.

A successful static validation does not prove that an ISO boots or that installation has been tested. Build output, artifact hashes and any runtime test results must be reported separately.
