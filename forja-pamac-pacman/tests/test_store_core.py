import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from forja_store_core import (
    parse_appstream, parse_pacman_search, parse_flatpak_search,
    parse_yay_updates, parse_checkupdates, parse_flatpak_updates,
)

class StoreParsingTests(unittest.TestCase):
    def test_appstream_maps_only_desktop_apps_to_available_packages(self):
        sample = """Identifier: org.example.Editor.desktop [desktop-application]
Name: Editor
Summary: Edita arquivos
Package: example-editor
Icon: org.example.Editor
Version: 2.4
---
Identifier: org.example.Library [runtime]
Name: Biblioteca
Summary: Biblioteca de suporte
Package: example-library
"""
        apps = parse_appstream(sample, {"example-editor"})
        self.assertEqual(len(apps), 1)
        self.assertEqual(apps[0]["package"], "example-editor")
        self.assertEqual(apps[0]["source"], "repo")
        self.assertEqual(apps[0]["version"], "2.4")
        self.assertEqual(apps[0]["app_id"], "org.example.Editor.desktop")

    def test_appstream_does_not_offer_package_missing_from_repositories(self):
        sample = """Identifier: org.example.App.desktop [desktop-application]
Name: App
Summary: Demo
Package: missing-package
"""
        self.assertEqual(parse_appstream(sample, {"another-package"}), [])

    def test_appstream_extracts_flatpak_bundle(self):
        sample = """Identifier: org.example.App.desktop [desktop-application]
Name: App
Summary: Demo
Bundle: flatpak:app/org.example.App/x86_64/stable
"""
        app = parse_appstream(sample)[0]
        self.assertEqual(app["source"], "flatpak")
        self.assertEqual(app["package"], "org.example.App")

    def test_pacman_search_parses_package_and_description(self):
        sample = "extra/editor 2.4-1\n    Editor de texto simples\nextra/viewer 1.2-3\n    Visualizador de arquivos\n"
        apps = parse_pacman_search(sample)
        self.assertEqual([item["package"] for item in apps], ["editor", "viewer"])
        self.assertEqual(apps[0]["summary"], "Editor de texto simples")
        self.assertEqual(apps[1]["version"], "1.2-3")

    def test_aur_search_uses_aur_source(self):
        sample = "aur/example-app 1.0-1 (+4 0.20)\n    Aplicativo comunitário\n"
        apps = parse_pacman_search(sample, "aur")
        self.assertEqual(apps[0]["source"], "aur")
        self.assertEqual(apps[0]["package"], "example-app")

    def test_flatpak_search_preserves_remote(self):
        sample = "Application\tName\tDescription\tRemotes\norg.example.App\tExample App\tAplicativo de teste\tflathub\n"
        apps = parse_flatpak_search(sample)
        self.assertEqual(len(apps), 1)
        self.assertEqual(apps[0]["package"], "org.example.App")
        self.assertEqual(apps[0]["remote"], "flathub")

    def test_yay_exit_one_empty_means_no_updates(self):
        lines, error = parse_yay_updates(subprocess.CompletedProcess([], 1, "", ""))
        self.assertEqual(lines, [])
        self.assertFalse(error)

    def test_yay_exit_one_with_error_is_not_hidden(self):
        lines, error = parse_yay_updates(subprocess.CompletedProcess([], 1, "", "network unavailable"))
        self.assertTrue(error)

    def test_checkupdates_exit_two_means_no_updates(self):
        lines, error = parse_checkupdates(subprocess.CompletedProcess([], 2, "", ""))
        self.assertEqual(lines, [])
        self.assertFalse(error)

    def test_pamac_checkupdates_exit_100_means_updates_available(self):
        lines, error = parse_checkupdates(
            subprocess.CompletedProcess([], 100, "firefox 1.0 -> 1.1\\n", "")
        )
        self.assertEqual(lines, ["firefox 1.0 -> 1.1"])
        self.assertFalse(error)

    def test_flatpak_updates_skip_header(self):
        lines, error = parse_flatpak_updates(subprocess.CompletedProcess([], 0, "Application\norg.example.App\n", ""))
        self.assertEqual(lines, ["org.example.App"])
        self.assertFalse(error)

if __name__ == "__main__":
    unittest.main()
