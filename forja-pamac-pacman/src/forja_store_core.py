"""Parsing and source helpers for Forja Store. Kept independent from GTK for testing."""
import re

APPSTREAM_CATEGORIES = {
    "internet": ["Network", "WebBrowser"],
    "office": ["Office", "Finance"],
    "graphics": ["Graphics"],
    "multimedia": ["AudioVideo", "Audio", "Video"],
    "games": ["Game"],
    "system": ["System", "Settings", "Utility", "FileTools"],
}
ALL_APPSTREAM_CATEGORIES = [
    "AudioVideo", "Audio", "Video", "Development", "Education", "Game",
    "Graphics", "Network", "Office", "Science", "Settings", "System",
    "Utility", "WebBrowser", "Finance", "FileTools", "Security", "Viewer",
]

def parse_appstream(output, available_packages=None):
    """Parse appstreamcli --details output into installable desktop applications."""
    available = set(available_packages) if available_packages is not None else None
    results = []
    blocks = re.split(r"(?m)(?=^Identifier:\s*)", output)
    for block in blocks:
        fields = {}
        for line in block.splitlines():
            if ": " in line:
                key, value = line.split(": ", 1)
                fields.setdefault(key.strip(), value.strip())
        identifier = fields.get("Identifier", "")
        if "[desktop-application]" not in identifier:
            continue
        component_id = identifier.split()[0]
        name = fields.get("Name", "").strip()
        summary = fields.get("Summary", "").strip()
        if not name:
            continue
        package = fields.get("Package", "").split(",")[0].strip()
        bundle = fields.get("Bundle", "").strip()
        if package:
            if available is not None and package not in available:
                continue
            source = "repo"
            target = package
            remote = ""
        elif bundle.startswith("flatpak:app/"):
            parts = bundle.split("/")
            if len(parts) < 2:
                continue
            source = "flatpak"
            target = parts[1]
            remote = "flathub"
        else:
            continue
        icon = fields.get("Icon", "application-x-executable")
        icon = icon.split(":", 1)[-1].removesuffix(".png").removesuffix(".svg")
        version = fields.get("Version", "")
        results.append({
            "name": name, "package": target,
            "summary": summary or "Aplicativo disponível",
            "source": source, "icon": icon or "application-x-executable",
            "app_id": component_id, "version": version, "remote": remote,
        })
    return deduplicate(results)

def parse_pacman_search(output, source="repo"):
    results = []
    current = None
    for line in output.splitlines():
        if line and not line[0].isspace():
            match = re.match(r"^(?:[^/\s]+/)?([^\s]+)\s+([^\s]+)", line)
            if match:
                current = {
                    "name": match.group(1), "package": match.group(1),
                    "summary": "Pacote disponível", "source": source,
                    "icon": "application-x-executable", "app_id": "",
                    "version": match.group(2), "remote": "",
                }
                results.append(current)
            else:
                current = None
        elif current and line.strip():
            current["summary"] = line.strip()
            current = None
    return results

def parse_flatpak_search(output):
    results = []
    for line in output.splitlines():
        if not line.strip():
            continue
        columns = line.rstrip().split("\t") if "\t" in line else re.split(r"\s{2,}", line.strip())
        if len(columns) < 2:
            continue
        app_id, name = columns[0].strip(), columns[1].strip()
        if app_id.lower() in ("application", "app id", "id") or "." not in app_id:
            continue
        description = columns[2].strip() if len(columns) > 2 else ""
        remotes = columns[3].strip() if len(columns) > 3 else "flathub"
        remote = next((item.strip() for item in re.split(r"[,; ]+", remotes) if item.strip()), "flathub")
        results.append({
            "name": name or app_id, "package": app_id,
            "summary": description or "Aplicativo Flatpak",
            "source": "flatpak", "icon": "application-x-executable",
            "app_id": app_id, "version": "", "remote": remote,
        })
    return deduplicate(results)

def deduplicate(results):
    unique = []
    seen = set()
    for item in results:
        key = (item["package"], item["source"], item.get("remote", ""))
        if key not in seen:
            seen.add(key)
            unique.append(item)
    return unique

def parse_yay_updates(result):
    """yay -Qua returns 1 with empty output when no AUR updates exist."""
    output = (result.stdout or "").strip()
    error = (result.stderr or "").strip()
    if result.returncode == 0:
        return [line for line in output.splitlines() if line.strip()], False
    if result.returncode == 1 and not output and not error:
        return [], False
    return [line for line in output.splitlines() if line.strip()], True

def parse_checkupdates(result):
    output = (result.stdout or "").strip()
    error = (result.stderr or "").strip()
    # Pamac checkupdates returns 100 when updates are available.
    if result.returncode in (0, 2, 100) and not error:
        return [line for line in output.splitlines() if line.strip()], False
    return [line for line in output.splitlines() if line.strip()], True

def parse_flatpak_updates(result):
    output = (result.stdout or "").strip()
    if result.returncode != 0 or (result.stderr or "").strip():
        return [line for line in output.splitlines() if line.strip()], True
    lines = []
    for line in output.splitlines():
        value = line.strip()
        if not value or value.lower() in ("application", "ref", "name"):
            continue
        if value.lower().startswith(("application ", "ref ", "name ")):
            continue
        lines.append(value)
    return lines, False
