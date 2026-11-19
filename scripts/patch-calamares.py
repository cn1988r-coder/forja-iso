#!/usr/bin/env python3
"""Apply the Forja OS branding and focused users-step fixes to pinned Calamares."""
from pathlib import Path
import re
import sys

source = Path(sys.argv[1])
branding = Path(__file__).resolve().parent / "branding/forja"
target_branding = source / "data/eos/branding/forja"
target_branding.mkdir(parents=True, exist_ok=True)
for item in branding.iterdir():
    if item.is_file():
        (target_branding / item.name).write_bytes(item.read_bytes())

settings = source / "data/eos/settings_offline.conf"
text = settings.read_text()
if "branding: endeavouros" not in text:
    raise SystemExit("Branding upstream esperado não encontrado em settings_offline.conf.")
settings.write_text(text.replace("branding: endeavouros", "branding: forja", 1))

# Keep only the explicit system-group mapping for wheel.
for name in ("usersq.conf", "users.conf"):
    path = source / "data/eos/modules" / name
    if not path.exists():
        continue
    text = path.read_text()
    text, count = re.subn(r"(?m)^    - wheel\n(?=    - rfkill\n)", "", text, count=1)
    if count != 1:
        raise SystemExit(f"Entrada duplicada de wheel não encontrada em {name}.")
    path.write_text(text)

# Anchor the QML expressions to match Calamares' full-string C++ validation.
for name in ("usersq-qt6.qml", "usersq.qml"):
    path = source / "src/modules/usersq" / name
    if not path.exists():
        continue
    text = path.read_text()
    old_user = "regularExpression: /[a-z_][a-z0-9_-]*[$]?$/"
    new_user = "regularExpression: /^[a-z_][a-z0-9_-]*[$]?$/"
    old_host = "regularExpression: /[a-zA-Z0-9][-a-zA-Z0-9_]+/"
    new_host = "regularExpression: /^[a-zA-Z0-9][-a-zA-Z0-9_]+$/"
    if old_user not in text or old_host not in text:
        raise SystemExit(f"Expressões de validação esperadas não encontradas em {name}.")
    text = text.replace(old_user, new_user, 1).replace(old_host, new_host, 1)
    text = text.replace("id: _userLoginField\\n", "id: _userLoginField\\n                maximumLength: 31\\n", 1)
    text = text.replace("id: _hostName\\n", "id: _hostName\\n                maximumLength: 63\\n", 1)
    text = text.replace('_userLoginField.text === "root"', '(_userLoginField.text === "root" || _userLoginField.text === "nobody")')
    text = text.replace('_hostName.text === "localhost"', '_hostName.text.toLowerCase() === "localhost"')
    text = text.replace("root is not allowed as username.", "root and nobody are reserved usernames.")
    if name == "usersq-qt6.qml":
        colors = {
            '#3A3F45': '#202a36',
            '#4E5661': '#26394b',
            '#7F3F3F': '#63343b',
            '#5C6370': '#40546b',
            '#7F9F7F': '#4b91c8',
            '#BF616A': '#d56b78',
        }
        for old, new in colors.items():
            text = text.replace(old, new)
        text = text.replace('commentsColor: "#ffffff"', 'commentsColor: "#b8c4d2"')
    path.write_text(text)

qml = (source / "src/modules/usersq/usersq-qt6.qml").read_text()
if "regularExpression: /[a-z_][a-z0-9_-]*[$]?$/" in qml:
    raise SystemExit("Validação QML do login não foi ancorada.")
if "regularExpression: /[a-zA-Z0-9][-a-zA-Z0-9_]+/" in qml:
    raise SystemExit("Validação QML do hostname não foi ancorada.")
