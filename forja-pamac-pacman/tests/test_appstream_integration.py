import shutil
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from forja_store_core import parse_appstream

@unittest.skipUnless(shutil.which("appstreamcli") and shutil.which("pacman"),
                     "AppStream CLI integration test runs in the validation container")
class AppStreamCliIntegrationTests(unittest.TestCase):
    def test_network_category_returns_installable_apps(self):
        catalog = subprocess.run(
            ["appstreamcli", "--no-color", "--details", "list-categories", "Network"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120,
        )
        self.assertEqual(catalog.returncode, 0, catalog.stderr or catalog.stdout)
        package_result = subprocess.run(
            ["pacman", "-Slq"], text=True, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, timeout=120,
        )
        self.assertEqual(package_result.returncode, 0, package_result.stderr)
        apps = parse_appstream(catalog.stdout, set(package_result.stdout.splitlines()))
        self.assertTrue(apps, "AppStream category returned no installable Manjaro/Arch packages")
        self.assertTrue(all(app["source"] == "repo" for app in apps))
        self.assertTrue(all(app["package"] in set(package_result.stdout.splitlines()) for app in apps))

if __name__ == "__main__":
    unittest.main()
