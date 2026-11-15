import importlib.machinery
import importlib.util
import unittest
from pathlib import Path
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "src" / "forja-pacman-transaction"
loader = importlib.machinery.SourceFileLoader("forja_pamac_transaction_test", str(SOURCE))
spec = importlib.util.spec_from_loader(loader.name, loader)
tx = importlib.util.module_from_spec(spec)
loader.exec_module(tx)

class PamacTransactionTests(unittest.TestCase):
    def test_repo_install_uses_pamac(self):
        with patch.object(tx.shutil, "which", return_value="/usr/bin/pamac"):
            with patch.object(tx, "call", return_value=0) as call:
                self.assertEqual(tx.main(["install", "repo", "firefox"]), 0)
                call.assert_called_once_with(
                    ["pamac", "install", "--no-confirm", "firefox"]
                )

    def test_aur_install_uses_pamac_build(self):
        with patch.object(tx.shutil, "which", return_value="/usr/bin/pamac"):
            with patch.object(tx, "call", return_value=0) as call:
                self.assertEqual(tx.main(["install", "aur", "google-chrome"]), 0)
                call.assert_called_once_with(
                    ["pamac", "build", "--no-confirm", "google-chrome"]
                )

    def test_remove_uses_pamac(self):
        with patch.object(tx.shutil, "which", return_value="/usr/bin/pamac"):
            with patch.object(tx, "call", return_value=0) as call:
                self.assertEqual(tx.main(["remove", "repo", "firefox"]), 0)
                call.assert_called_once_with(
                    ["pamac", "remove", "--no-confirm", "firefox"]
                )

    def test_upgrade_uses_pamac_and_includes_aur(self):
        with patch.object(tx.shutil, "which", return_value="/usr/bin/pamac"):
            with patch.object(tx, "call", return_value=0) as call:
                self.assertEqual(tx.main(["upgrade"]), 0)
                self.assertEqual(
                    call.call_args_list[0].args[0],
                    ["pamac", "upgrade", "--aur", "--no-confirm"],
                )

    def test_invalid_package_is_rejected(self):
        with patch.object(tx.shutil, "which", return_value="/usr/bin/pamac"):
            with patch.object(tx, "call") as call:
                self.assertEqual(tx.main(["install", "repo", "bad package"]), 2)
                call.assert_not_called()

    def test_flatpak_install_stays_with_flatpak_cli(self):
        with patch.object(tx.shutil, "which", side_effect=lambda name: "/usr/bin/" + name):
            with patch.object(tx, "call", side_effect=[0, 0]) as call:
                self.assertEqual(
                    tx.main(["install", "flatpak", "org.example.App", "flathub"]), 0
                )
                self.assertEqual(
                    call.call_args_list[1].args[0],
                    ["flatpak", "install", "--system", "--noninteractive",
                     "--assumeyes", "flathub", "org.example.App"],
                )

    def test_flatpak_id_validation(self):
        with patch.object(tx.shutil, "which", side_effect=lambda name: "/usr/bin/" + name):
            with patch.object(tx, "call") as call:
                self.assertEqual(tx.main(["install", "flatpak", "not-an-id"]), 2)
                call.assert_not_called()

if __name__ == "__main__":
    unittest.main()
