#!/usr/bin/python3
"""Forja Store: GTK3 frontend for Arch/EndeavourOS package management."""
import json
import re
import shutil
import subprocess
import threading
import urllib.parse
import urllib.request

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gio

HELPER = "/usr/bin/forja-pacman-transaction"
PKG_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9@._+:-]*$")
AUR_API = "https://aur.archlinux.org/rpc/v5/search/"

def command(args, timeout=120):
    try:
        return subprocess.run(args, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return subprocess.CompletedProcess(args, 1, str(exc))

def checkupdates():
    if not shutil.which("checkupdates"):
        return None, "O pacote pacman-contrib (checkupdates) não está instalado."
    result = command(["checkupdates"], 180)
    rows = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    if result.returncode == 0:
        return rows, None
    if result.returncode == 2 and not rows:
        return [], None
    return None, result.stdout.strip() or f"checkupdates retornou {result.returncode}."

def aur_search(query):
    url = AUR_API + urllib.parse.quote(query)
    request = urllib.request.Request(url, headers={"User-Agent": "ForjaStore/1.0"})
    with urllib.request.urlopen(request, timeout=20) as response:
        data = json.loads(response.read().decode("utf-8"))
    if data.get("type") != "search":
        raise RuntimeError("Resposta inesperada da API do AUR.")
    return data.get("results", [])[:60]

def aur_info(names):
    if not names:
        return []
    query = urllib.parse.urlencode([("arg[]", name) for name in names])
    request = urllib.request.Request("https://aur.archlinux.org/rpc/v5/info?" + query,
                                    headers={"User-Agent": "ForjaStore/1.0"})
    results = []
    for start in range(0, len(names), 100):
        chunk = names[start:start + 100]
        query = urllib.parse.urlencode([("arg[]", name) for name in chunk])
        request = urllib.request.Request("https://aur.archlinux.org/rpc/v5/info?" + query,
                                        headers={"User-Agent": "ForjaStore/1.0"})
        with urllib.request.urlopen(request, timeout=25) as response:
            data = json.loads(response.read().decode("utf-8"))
        if data.get("type") != "multiinfo":
            raise RuntimeError("Resposta inesperada ao consultar versões do AUR.")
        results.extend(data.get("results", []))
    return results

class Store(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="br.forja.Store",
                         flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE)
        self.open_updates = False
        self.window = None
        self.content = None
        self.status = None
        self.search = None
        self.source = "official"
        self.installed = set()
        self.busy = False
        self.generation = 0
        self.rows = []

    def do_command_line(self, cmdline):
        self.open_updates = "--updates" in cmdline.get_arguments()
        self.activate()
        return 0

    def do_activate(self):
        if self.window:
            self.window.present()
            if self.open_updates:
                self.show_updates()
            return
        self.window = Gtk.ApplicationWindow(application=self, title="Forja Store")
        self.window.set_default_size(1000, 680)
        self.window.set_border_width(12)
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>Forja Store</span>")
        header.pack_start(title, False, False, 4)
        self.search = Gtk.SearchEntry()
        self.search.set_placeholder_text("Pesquisar pacotes oficiais ou no AUR")
        self.search.set_hexpand(True)
        self.search.connect("search-changed", self.on_search)
        header.pack_start(self.search, True, True, 8)
        updates = Gtk.Button(label="Atualizações")
        updates.connect("clicked", lambda *_: self.show_updates())
        header.pack_end(updates, False, False, 0)
        outer.pack_start(header, False, False, 0)
        self.content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.add(self.content)
        outer.pack_start(scroll, True, True, 0)
        self.status = Gtk.Label(label="Loja de aplicativos da Forja OS", xalign=0)
        outer.pack_start(self.status, False, False, 4)
        self.window.add(outer)
        self.window.show_all()
        self.reload_installed()
        if self.open_updates:
            self.show_updates()
        else:
            self.show_home()

    def set_status(self, message):
        self.status.set_text(message)

    def clear(self):
        for child in self.content.get_children():
            self.content.remove(child)

    def heading(self, text):
        label = Gtk.Label(label=text, xalign=0)
        label.set_markup("<span size='large' weight='bold'>" +
                         GLib.markup_escape_text(text) + "</span>")
        self.content.pack_start(label, False, False, 6)

    def reload_installed(self):
        def worker():
            result = command(["pacman", "-Q"], 60)
            names = {line.split()[0] for line in result.stdout.splitlines() if line.split()}
            GLib.idle_add(self._installed_ready, names)
        threading.Thread(target=worker, daemon=True).start()

    def _installed_ready(self, names):
        self.installed = names
        return GLib.SOURCE_REMOVE

    def show_home(self):
        self.clear()
        self.heading("Bem-vindo à Forja Store")
        self.content.pack_start(Gtk.Label(
            label="Pesquise programas dos repositórios oficiais do Arch Linux e do AUR. "
                  "Instalações do AUR exigem revisão manual do PKGBUILD.",
            xalign=0, yalign=0, wrap=True), False, False, 8)
        button = Gtk.Button(label="Ver atualizações disponíveis")
        button.set_halign(Gtk.Align.START)
        button.connect("clicked", lambda *_: self.show_updates())
        self.content.pack_start(button, False, False, 4)
        self.content.show_all()

    def on_search(self, *_):
        query = self.search.get_text().strip()
        if len(query) < 2:
            return
        self.generation += 1
        generation = self.generation
        self.clear()
        self.heading("Pesquisando nos repositórios oficiais e no AUR…")
        self.content.show_all()
        def worker():
            official = command(["pacman", "-Ss", query], 60)
            matches, current = [], None
            for line in official.stdout.splitlines():
                if line and not line[0].isspace():
                    m = re.match(r"^([^/]+)/([^ ]+) ([^ ]+)", line)
                    if m:
                        current = {"name": m.group(2), "version": m.group(3),
                                   "description": "", "source": "official"}
                        matches.append(current)
                elif current and line.strip():
                    current["description"] = line.strip()
                    current = None
            aur, error = [], None
            try:
                aur = [{"name": item["Name"], "version": item["Version"],
                        "description": item.get("Description", ""),
                        "source": "aur"} for item in aur_search(query)]
            except Exception as exc:
                error = str(exc)
            GLib.idle_add(self.show_results, generation, matches[:60], aur, error)
        threading.Thread(target=worker, daemon=True).start()

    def show_results(self, generation, official, aur, error):
        if generation != self.generation:
            return GLib.SOURCE_REMOVE
        self.clear()
        self.heading("Repositórios oficiais")
        if not official:
            self.content.pack_start(Gtk.Label(label="Nenhum pacote oficial encontrado.", xalign=0),
                                    False, False, 2)
        for item in official:
            self.add_package(item)
        self.heading("AUR (comunitário)")
        if error:
            self.content.pack_start(Gtk.Label(label="Não foi possível consultar o AUR: " + error,
                                              xalign=0, wrap=True), False, False, 2)
        elif not aur:
            self.content.pack_start(Gtk.Label(label="Nenhum pacote encontrado no AUR.", xalign=0),
                                    False, False, 2)
        for item in aur:
            self.add_package(item)
        self.content.show_all()
        self.set_status(f"{len(official)} pacote(s) oficial(is), {len(aur)} do AUR.")
        return GLib.SOURCE_REMOVE

    def add_package(self, item):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.set_border_width(7)
        info = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        name = Gtk.Label(label=item["name"], xalign=0)
        name.set_markup("<b>" + GLib.markup_escape_text(item["name"]) + "</b>")
        desc = Gtk.Label(label=item.get("description") or "Sem descrição.", xalign=0, wrap=True)
        desc.set_max_width_chars(75)
        info.pack_start(name, False, False, 0)
        info.pack_start(desc, False, False, 0)
        info.pack_start(Gtk.Label(label=("AUR · " if item["source"] == "aur" else "Repositório oficial · ") +
                                  item["version"], xalign=0), False, False, 0)
        row.pack_start(info, True, True, 0)
        button = Gtk.Button(label="Revisar e compilar" if item["source"] == "aur"
                            else ("Remover" if item["name"] in self.installed else "Instalar"))
        button.connect("clicked", self.package_action, item)
        row.pack_end(button, False, False, 0)
        self.content.pack_start(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL), False, False, 0)
        self.content.pack_start(row, False, False, 0)

    def confirm(self, title, message):
        dialog = Gtk.MessageDialog(transient_for=self.window, modal=True,
            message_type=Gtk.MessageType.WARNING, buttons=Gtk.ButtonsType.OK_CANCEL, text=title)
        dialog.format_secondary_text(message)
        response = dialog.run()
        dialog.destroy()
        return response == Gtk.ResponseType.OK

    def package_action(self, _button, item):
        name = item["name"]
        if not PKG_RE.fullmatch(name):
            self.set_status("Nome de pacote inválido.")
            return
        if item["source"] == "aur":
            if not self.confirm("Pacote comunitário do AUR",
                "O AUR não é revisado oficialmente pelo Arch. O PKGBUILD e os arquivos "
                "do pacote devem ser examinados antes da compilação. A Forja Store abrirá "
                "um terminal para você revisar o PKGBUILD e confirmar manualmente."):
                return
            if not shutil.which("mate-terminal"):
                self.set_status("mate-terminal não está disponível para a compilação do AUR.")
                return
            subprocess.Popen(["mate-terminal", "--", "bash", "-lc",
                              "exec /usr/bin/forja-aur-build " + name])
            return
        installed = name in self.installed
        action = "remove" if installed else "install"
        verb = "remover" if installed else "instalar"
        if not self.confirm("Confirmar operação", f"Deseja {verb} {name}? O Pacman resolverá dependências."):
            return
        self.run_privileged([action, name], f"Operação: {name}")

    def run_privileged(self, args, label):
        if self.busy:
            self.set_status("Já existe uma operação em andamento.")
            return
        self.busy = True
        self.set_status("Aguardando autorização e executando operação…")
        def worker():
            result = command(["pkexec", HELPER, *args], 7200)
            GLib.idle_add(self.operation_done, result.returncode, result.stdout, label)
        threading.Thread(target=worker, daemon=True).start()

    def operation_done(self, code, output, label):
        self.busy = False
        self.set_status((label + " concluída.") if code == 0 else
                        (label + " não concluída. " + (output[-350:] if output else "")))
        self.reload_installed()
        return GLib.SOURCE_REMOVE

    def show_updates(self):
        self.clear()
        self.heading("Atualizações do sistema")
        self.content.pack_start(Gtk.Label(label="Consultando Pacman e Flatpak…", xalign=0),
                                False, False, 4)
        self.content.show_all()
        def worker():
            pac, error = checkupdates()
            flat = []
            if shutil.which("flatpak"):
                for scope in ("--system", "--user"):
                    result = command(["flatpak", "remote-ls", scope, "--updates",
                                      "--columns=application,name,branch"], 180)
                    if result.returncode == 0:
                        flat.extend((scope, line.strip()) for line in result.stdout.splitlines()
                                    if line.strip())
            aur_outdated, aur_error = [], None
            try:
                foreign = command(["pacman", "-Qm"], 90)
                installed = {}
                for line in foreign.stdout.splitlines():
                    parts = line.split()
                    if len(parts) >= 2 and PKG_RE.fullmatch(parts[0]):
                        installed[parts[0]] = parts[1]
                for item in aur_info(list(installed)):
                    local = installed.get(item.get("Name"))
                    remote = item.get("Version")
                    if local and remote and shutil.which("vercmp"):
                        compare = command(["vercmp", local, remote], 10)
                        if compare.returncode == 0 and compare.stdout.strip() == "-1":
                            aur_outdated.append((item["Name"], local, remote))
            except Exception as exc:
                aur_error = str(exc)
            GLib.idle_add(self.show_update_results, pac, error, flat, aur_outdated, aur_error)
        threading.Thread(target=worker, daemon=True).start()

    def show_update_results(self, pac, error, flat, aur_outdated, aur_error):
        self.clear()
        self.heading("Atualizações disponíveis")
        if error:
            self.content.pack_start(Gtk.Label(label="Erro ao consultar Pacman: " + error,
                                              xalign=0, wrap=True), False, False, 4)
        else:
            for line in pac:
                self.content.pack_start(Gtk.Label(label="Pacman · " + line, xalign=0),
                                        False, False, 2)
        for scope, line in flat:
            self.content.pack_start(Gtk.Label(label=f"Flatpak {scope} · {line}", xalign=0),
                                    False, False, 2)
        self.heading("Pacotes do AUR")
        if aur_error:
            self.content.pack_start(Gtk.Label(
                label="Não foi possível verificar versões do AUR: " + aur_error,
                xalign=0, wrap=True), False, False, 2)
        elif not aur_outdated:
            self.content.pack_start(Gtk.Label(
                label="Nenhuma atualização do AUR identificada.", xalign=0),
                False, False, 2)
        for name, local, remote in aur_outdated:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            row.pack_start(Gtk.Label(label=f"{name}: {local} → {remote}", xalign=0),
                           True, True, 0)
            button = Gtk.Button(label="Revisar e atualizar")
            button.connect("clicked", self.launch_aur_update, name)
            row.pack_end(button, False, False, 0)
            self.content.pack_start(row, False, False, 2)
        if error is None and pac:
            button = Gtk.Button(label="Atualizar sistema (Pacman)")
            button.set_halign(Gtk.Align.START)
            button.connect("clicked", self.update_pacman)
            self.content.pack_start(button, False, False, 8)
        if flat:
            for scope, label in (("--system", "Atualizar Flatpak do sistema"),
                                 ("--user", "Atualizar Flatpak do usuário")):
                if any(s == scope for s, _ in flat):
                    button = Gtk.Button(label=label)
                    button.set_halign(Gtk.Align.START)
                    button.connect("clicked", self.update_flatpak, scope)
                    self.content.pack_start(button, False, False, 4)
        if error is None and not pac and not flat and not aur_outdated:
            self.content.pack_start(Gtk.Label(label="Nenhuma atualização disponível.", xalign=0),
                                    False, False, 4)
        self.content.show_all()
        self.set_status("Consulta concluída." if error is None else "A consulta de atualizações falhou.")
        return GLib.SOURCE_REMOVE

    def launch_aur_update(self, _button, name):
        if not self.confirm("Atualização de pacote AUR",
            "A atualização será compilada como usuário comum. Revise novamente o PKGBUILD "
            "e os arquivos do pacote antes de confirmar a compilação no terminal."):
            return
        subprocess.Popen(["mate-terminal", "--", "bash", "-lc",
                          "exec /usr/bin/forja-aur-build " + name])

    def update_pacman(self, *_):
        if self.confirm("Atualizar o sistema",
            "Será executada uma atualização completa com pacman -Syu. Não feche o sistema "
            "durante a transação. Atualizações parciais não são suportadas pelo Arch Linux."):
            self.run_privileged(["upgrade"], "Atualização completa do sistema")

    def update_flatpak(self, _button, scope):
        if scope == "--system":
            self.run_privileged(["flatpak-update-system"], "Atualização Flatpak do sistema")
            return
        if not self.confirm("Atualizar Flatpak do usuário",
                            "Executar flatpak update para os aplicativos do usuário?"):
            return
        def worker():
            result = command(["flatpak", "update", "--user", "--noninteractive", "--assumeyes"], 7200)
            GLib.idle_add(self.operation_done, result.returncode, result.stdout,
                          "Atualização Flatpak do usuário")
        if not shutil.which("flatpak"):
            self.set_status("Flatpak não está instalado.")
            return
        threading.Thread(target=worker, daemon=True).start()

if __name__ == "__main__":
    raise SystemExit(Store().run(None))
