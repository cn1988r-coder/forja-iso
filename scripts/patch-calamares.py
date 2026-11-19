#!/usr/bin/env python3
"""Apply the Forja OS branding and focused users-step fixes to the pinned EOS Calamares source."""
from pathlib import Path
import re
import sys

source = Path(sys.argv[1])
branding = Path(__file__).resolve().parent.parent / "build/calamares/branding/forja"
target_branding = source / "data/eos/branding/forja"
target_branding.mkdir(parents=True, exist_ok=True)
for item in branding.iterdir():
    if item.is_file():
        (target_branding / item.name).write_bytes(item.read_bytes())

settings = source / "data/eos/settings_offline.conf"
text = settings.read_text()
if "branding: endeavouros" not in text:
    raise SystemExit("Não foi encontrada a identidade upstream esperada em settings_offline.conf.")
settings.write_text(text.replace("branding: endeavouros", "branding: forja", 1))

# The EOS config lists wheel twice, once as a string and once as a system-group
# mapping. Keep the explicit mapping, which creates the group when needed.
for name in ("usersq.conf", "users.conf"):
    path = source / "data/eos/modules" / name
    if not path.exists():
        continue
    text = path.read_text()
    text = re.sub(r"(?m)^    - wheel\\n(?=    - rfkill\\n)", "", text, count=1)
    path.write_text(text)

# Keep the QML validator aligned with the C++ validator: both expressions
# must validate the entire value, not merely a matching suffix/sub-string.
for name in ("usersq-qt6.qml", "usersq.qml"):
    path = source / "src/modules/usersq" / name
    if not path.exists():
        continue
    text = path.read_text()
    text = text.replace(
        "regularExpression: /[a-z_][a-z0-9_-]*[$]?$/",
        "regularExpression: /^[a-z_][a-z0-9_-]*[$]?$/",
    )
    text = text.replace(
        "regularExpression: /[a-zA-Z0-9][-a-zA-Z0-9_]+/",
        "regularExpression: /^[a-zA-Z0-9][-a-zA-Z0-9_]*$/",
    )
    if name == "usersq-qt6.qml":
        text = text.replace('readonly property color unfilledFieldColor: "#3A3F45"', 'readonly property color unfilledFieldColor: "#202a36"')
        text = text.replace('readonly property color positiveFieldColor: "#4E5661"', 'readonly property color positiveFieldColor: "#26394b"')
        text = text.replace('readonly property color negativeFieldColor: "#7F3F3F"', 'readonly property color negativeFieldColor: "#63343b"')
        text = text.replace('readonly property color unfilledFieldOutlineColor: "#5C6370"', 'readonly property color unfilledFieldOutlineColor: "#40546b"')
        text = text.replace('readonly property color positiveFieldOutlineColor: "#7F9F7F"', 'readonly property color positiveFieldOutlineColor: "#4b91c8"')
        text = text.replace('readonly property color negativeFieldOutlineColor: "#BF616A"', 'readonly property color negativeFieldOutlineColor: "#d56b78"')
        text = text.replace('readonly property color commentsColor: "#ffffff"', 'readonly property color commentsColor: "#b8c4d2"')
    path.write_text(text)

# Fail closed if any expected QML validator was not patched.
qml = (source / "src/modules/usersq/usersq-qt6.qml").read_text()
if "regularExpression: /^[a-z_][a-z0-9_-]*[$]?$/ " in qml:
    raise SystemExit("A expressão de usuário ainda contém um espaço inesperado.")
if "regularExpression: /[a-z_][a-z0-9_-]*[$]?$/" in qml:
    raise SystemExit("A validação QML do login não foi ancorada.")
if "regularExpression: /[a-zA-Z0-9][-a-zA-Z0-9_]+/" in qml:
    raise SystemExit("A validação QML do hostname não foi ancorada.")
