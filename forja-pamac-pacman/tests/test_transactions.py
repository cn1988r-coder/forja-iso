import importlib.machinery
import importlib.util
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "src" / "forja-pacman-transaction"
loader = importlib.machinery.SourceFileLoader("forja_transaction_test_module", str(SOURCE))
spec = importlib.util.spec_from_loader(loader.name, loader)
tx = importlib.util.module_from_spec(spec)
loader.exec_module(tx)

class TransactionValidationTests(unittest.TestCase):
    def test_rejects_invalid_flatpak_id_without_running_commands(self):
        with patch.object(tx.shutil, "which", return_value="/usr/bin/flatpak"):
            with patch.object(tx, "call") as call:
                self.assertEqual(tx.main(["install", "flatpak", "not-an-app-id", "flathub"]), 2)
                call.assert_not_called()

    def test_rejects_invalid_flatpak_remote(self):
        with patch.object(tx.shutil, "which", return_value="/usr/bin/flatpak"):
            with patch.object(tx, "call") as call:
                self.assertEqual(tx.main(["install", "flatpak", "org.example.App", "bad/remote"]), 2)
                call.assert_not_called()

    def test_rejects_invalid_pacman_package(self):
        with patch.object(tx, "call") as call:
            self.assertEqual(tx.main(["install", "repo", "bad package"]), 2)
            call.assert_not_called()

    def test_rejects_unknown_package_source(self):
        with patch.object(tx, "call") as call:
            self.assertEqual(tx.main(["install", "unknown", "example"]), 2)
            call.assert_not_called()

    def test_pacman_failure_stops_aur_upgrade(self):
        with patch.object(tx, "call", return_value=1) as call:
            with patch.object(tx, "aur_command") as aur:
                self.assertEqual(tx.upgrade_system(), 1)
                aur.assert_not_called()
                self.assertEqual(call.call_count, 1)

    def test_aur_failure_does_not_skip_flatpak_upgrade(self):
        with patch.object(tx.shutil, "which", return_value="/usr/bin/flatpak"):
            with patch.object(tx, "call", side_effect=[0, 0]) as call:
                with patch.object(tx, "aur_command", return_value=1):
                    self.assertEqual(tx.upgrade_system(), 1)
                    self.assertEqual(call.call_count, 2)
                    self.assertEqual(call.call_args_list[1].args[0][0], "flatpak")

if __name__ == "__main__":
    unittest.main()
