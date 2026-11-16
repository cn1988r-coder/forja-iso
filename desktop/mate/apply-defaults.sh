#!/usr/bin/env bash
set -euo pipefail

# Apply safe MATE defaults for the current user.
# Every setting is checked against the installed schema before writing,
# so absent optional schemas/keys do not break image construction.

set_if_available() {
    local schema="$1" key="$2" value="$3"
    if ! gsettings list-schemas | grep -Fxq "$schema"; then
        printf 'SKIP schema unavailable: %s\n' "$schema"
        return 0
    fi
    if ! gsettings list-keys "$schema" | grep -Fxq "$key"; then
        printf 'SKIP key unavailable: %s.%s\n' "$schema" "$key"
        return 0
    fi
    gsettings set "$schema" "$key" "$value"
    printf 'SET %s.%s\n' "$schema" "$key"
}

# Copy Forja defaults into the current user's profile without overwriting
# existing personal configuration files. The skel directory must remain
# alongside this script in the source tree/package.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$SCRIPT_DIR/skel/.config" && -n "${HOME:-}" ]]; then
    install -d "$HOME/.config"
    cp -an "$SCRIPT_DIR/skel/.config/." "$HOME/.config/"
    printf 'COPIED default user configuration from %s/skel/.config\n' "$SCRIPT_DIR"
else
    printf 'SKIP user config copy: skel/.config or HOME unavailable\n'
fi

command -v gsettings >/dev/null 2>&1 || {
    echo "gsettings is unavailable; install the MATE schemas before applying defaults." >&2
    exit 1
}

set_if_available org.mate.interface gtk-theme "'Materia-dark'"
set_if_available org.mate.interface icon-theme "'Papirus-Dark'"
set_if_available org.mate.interface font-name "'DejaVu Sans 10'"
set_if_available org.mate.background show-desktop-icons "false"
set_if_available org.mate.background background-fade "false"
set_if_available org.mate.Marco.general compositing-manager "false"

# Replace the stock MATE menu applet with Brisk Menu for this user.
# Do not create a duplicate if Brisk is already present.
brisk_metadata="$(find /usr/share/mate-panel -type f -iname "*brisk*.mate-panel-applet" -print -quit 2>/dev/null || true)"
if command -v dconf >/dev/null 2>&1 && [[ -n "$brisk_metadata" ]]; then
    object_ids="$(gsettings get org.mate.panel.general object-id-list 2>/dev/null || true)"
    if [[ -n "$object_ids" ]]; then
        object_ids="${object_ids//\'menu-bar\'/\'brisk-menu\'}"
        if [[ "$object_ids" != *"'brisk-menu'"* ]]; then
            object_ids="${object_ids%]}, 'brisk-menu']"
        fi
        gsettings set org.mate.panel.general object-id-list "$object_ids"
        dconf write /org/mate/panel/objects/brisk-menu/object-type "'applet'"
        dconf write /org/mate/panel/objects/brisk-menu/applet-iid "'BriskMenuFactory::BriskMenu'"
        dconf write /org/mate/panel/objects/brisk-menu/toplevel-id "'top'"
        dconf write /org/mate/panel/objects/brisk-menu/position "0"
        dconf write /org/mate/panel/objects/brisk-menu/locked "true"
        printf 'SET Brisk Menu as the MATE panel menu applet\n'
    fi
fi
