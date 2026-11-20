# VENOM OS XFCE 1.0

## Scope

The Community XFCE edition is based on Manjaro and preserves the upstream Community XFCE desktop layout and behavior while replacing vendor branding with VENOM OS identity.

The desktop uses one bottom panel at 100% width and 40 px height, with the upstream plugin order, Whisker menu, Docklike, system tray, audio, power, notifications, clipboard and two-line clock. The dark theme, Papient Dark icon theme, Bibata cursor and Noto Nerd fonts are installed and selected.

Firefox and Pamac GTK are included. Ferdium and IPTVnator are installed on first login through Pamac AUR support as `ferdium-bin` and `iptvnator-bin`.

## Installer

Calamares is included in the Live image. The Manjaro module sequence is configured in `manjaro/venom-xfce/live-overlay/etc/calamares/settings.conf`; VENOM branding and artwork are in the adjacent `branding/venom` directory. The Live application menu provides **Install VENOM OS**. MHWD integration is enabled.

## Package signing

The Community Stable repository is configured as `community-stable`. The build workflow imports and locally signs the full fingerprint published in the upstream Community keyring repository using Manjaro's `additional-trusted-gpg` input. Signature enforcement remains enabled.

## Validation and build policy

The strict validator checks package selections, desktop settings, panel geometry and plugin order, theme/font assets, Calamares sequence and branding, repository configuration, and the PGP trust setup.

Push events run validation only. The build job is restricted to explicit manual dispatch. No ISO build is authorized until every mandatory validation is green.

Static validation, a successful ISO build, successful Live boot and successful installation are separate evidence levels. They must never be conflated.
