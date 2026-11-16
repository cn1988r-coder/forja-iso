#!/usr/bin/python3
"""Small MATE panel indicator for Forja OS repository updates."""
import shutil
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

STORE = "/usr/bin/forja-store"
ICON_CURRENT = "forja-update-current"
ICON_AVAILABLE = "forja-update-available"
CHECK_INTERVAL = 1800


def check_updates():
    """Return (count, error). checkupdates exit 2 means no updates."""
    if not shutil.which("checkupdates"):
        return 0, "O utilitário checkupdates não está instalado."
    try:
        result = subprocess.run(
            ["checkupdates"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=180,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 0, str(exc)

    lines = [line for line in result.stdout.splitlines() if line.strip()]
    if result.returncode == 0:
        return len(lines), None
    if result.returncode == 2 and not lines:
        return 0, None
    detail = result.stderr.strip() or result.stdout.strip()
    return 0, detail or f"checkupdates terminou com código {result.returncode}."


class ForjaUpdateIndicator:
    def __init__(self):
        self.checking = False
        self.icon = Gtk.StatusIcon.new_from_icon_name(ICON_CURRENT)
        self.icon.set_title("Atualizações da Forja OS")
        self.icon.set_tooltip_text("Forja OS: aguardando a primeira verificação")
        self.icon.set_visible(True)
        self.icon.connect("activate", self.open_store)
        self.icon.connect("popup-menu", self.popup)

        self.menu = Gtk.Menu()
        self.status_item = Gtk.MenuItem(label="Aguardando verificação…")
        self.status_item.set_sensitive(False)
        self.menu.append(self.status_item)
        self.menu.append(Gtk.SeparatorMenuItem())
        self._add_item("Abrir Forja Store", self.open_store)
        self._add_item("Verificar atualizações agora", self.check)
        self.menu.show_all()

        # Primeira consulta após o painel carregar; depois, a cada 30 minutos.
        GLib.timeout_add_seconds(45, self.check)
        GLib.timeout_add_seconds(CHECK_INTERVAL, self.check)

    def _add_item(self, label, callback):
        item = Gtk.MenuItem(label=label)
        item.connect("activate", callback)
        self.menu.append(item)

    def popup(self, _icon, button, activate_time):
        self.menu.popup(None, None, Gtk.StatusIcon.position_menu,
                        self.icon, button, activate_time)

    def _set_state(self, count, error):
        if error:
            self.icon.set_from_icon_name(ICON_AVAILABLE)
            self.icon.set_tooltip_text("Forja OS: não foi possível verificar atualizações")
            self.status_item.set_label("Falha ao verificar atualizações")
        elif count:
            self.icon.set_from_icon_name(ICON_AVAILABLE)
            self.icon.set_tooltip_text(f"Forja OS: {count} atualização(ões) disponível(is)")
            self.status_item.set_label(f"{count} atualização(ões) disponível(is)")
        else:
            self.icon.set_from_icon_name(ICON_CURRENT)
            self.icon.set_tooltip_text("Forja OS está atualizada")
            self.status_item.set_label("O sistema está atualizado")
        self.checking = False
        return GLib.SOURCE_REMOVE

    def check(self, *_args):
        if self.checking:
            return GLib.SOURCE_REMOVE
        self.checking = True
        self.status_item.set_label("Verificando atualizações…")
        self.icon.set_tooltip_text("Forja OS: verificando atualizações…")

        def worker():
            count, error = check_updates()
            GLib.idle_add(self._set_state, count, error)

        threading.Thread(target=worker, daemon=True).start()
        return GLib.SOURCE_REMOVE

    def open_store(self, *_args):
        if not shutil.which(STORE):
            dialog = Gtk.MessageDialog(
                message_type=Gtk.MessageType.INFO,
                buttons=Gtk.ButtonsType.CLOSE,
                text="A Forja Store ainda não está instalada.",
            )
            dialog.format_secondary_text(
                "O indicador está preparado para abrir a seção de atualizações "
                "da loja quando ela for integrada à edição MATE."
            )
            dialog.run()
            dialog.destroy()
            return
        try:
            subprocess.Popen([STORE, "--updates"])
        except OSError as exc:
            dialog = Gtk.MessageDialog(
                message_type=Gtk.MessageType.ERROR,
                buttons=Gtk.ButtonsType.CLOSE,
                text="Não foi possível abrir a Forja Store.",
            )
            dialog.format_secondary_text(str(exc))
            dialog.run()
            dialog.destroy()


if __name__ == "__main__":
    indicator = ForjaUpdateIndicator()
    Gtk.main()
