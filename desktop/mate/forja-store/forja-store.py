#!/usr/bin/python3
"""Forja Store: a native, category-led GTK3 software center for Forja OS."""
import json
import re
import shutil
import subprocess
import threading
import urllib.parse
import urllib.request

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gio, Gdk

HELPER = "/usr/bin/forja-pacman-transaction"
PKG_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9@._+:-]*$")
AUR_API = "https://aur.archlinux.org/rpc/v5/search/"

# Curated entry points make the home screen useful before the first search.
CATALOG = {
    "Destaques": [
        ("firefox", "Navegador Firefox", "internet-web-browser", "Navegue na internet com privacidade e extensões."),
        ("vlc", "VLC Media Player", "multimedia-video-player", "Reproduza vídeos e músicas em vários formatos."),
        ("libreoffice-fresh", "LibreOffice", "libreoffice-startcenter", "Suíte completa para documentos, planilhas e apresentações."),
        ("gimp", "GIMP", "gimp", "Edite imagens e crie artes digitais."),
        ("thunderbird", "Thunderbird", "thunderbird", "E-mail, agenda e contatos em um só lugar."),
        ("obs-studio", "OBS Studio", "obs", "Grave a tela e produza transmissões."),
    ],
    "Internet": [
        ("firefox", "Firefox", "internet-web-browser", "Navegador web."),
        ("chromium", "Chromium", "web-browser", "Navegador de código aberto."),
        ("thunderbird", "Thunderbird", "thunderbird", "Cliente de e-mail."),
        ("transmission-gtk", "Transmission", "transmission", "Cliente simples para torrents."),
        ("filezilla", "FileZilla", "folder-remote", "Transferência de arquivos por FTP e SFTP."),
    ],
    "Multimídia": [
        ("vlc", "VLC", "multimedia-video-player", "Reprodutor multimídia."),
        ("mpv", "MPV", "video-x-generic", "Reprodutor de vídeo leve."),
        ("audacity", "Audacity", "audacity", "Gravação e edição de áudio."),
        ("obs-studio", "OBS Studio", "obs", "Gravação e transmissão de tela."),
        ("gimp", "GIMP", "gimp", "Edição de imagens."),
        ("kdenlive", "Kdenlive", "kdenlive", "Edição de vídeo."),
    ],
    "Escritório": [
        ("libreoffice-fresh", "LibreOffice", "libreoffice-startcenter", "Documentos, planilhas e apresentações."),
        ("onlyoffice-bin", "ONLYOFFICE", "onlyoffice", "Editor de documentos compatíveis com Office (AUR)."),
        ("evince", "Visualizador de documentos", "x-office-document", "Leitor de documentos PDF."),
        ("calibre", "Calibre", "calibre", "Organize e leia sua biblioteca digital."),
    ],
    "Sistema": [
        ("htop", "htop", "utilities-system-monitor", "Monitore processos e recursos do sistema."),
        ("timeshift", "Timeshift", "preferences-system-backup", "Crie e restaure snapshots do sistema."),
        ("bleachbit", "BleachBit", "edit-clear", "Limpeza de arquivos temporários."),
    ],
    "Desenvolvimento": [
        ("code", "Visual Studio Code", "com.visualstudio.code", "Editor de código (AUR)."),
        ("git", "Git", "git", "Controle de versão distribuído."),
        ("meld", "Meld", "meld", "Compare arquivos e diretórios."),
        ("geany", "Geany", "geany", "Editor de código leve."),
    ],
}
CATEGORIES = list(CATALOG.keys())

def run(args, timeout=120):
    try:
        return subprocess.run(args, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return subprocess.CompletedProcess(args, 1, str(exc))

def aur_search(query):
    request = urllib.request.Request(AUR_API + urllib.parse.quote(query),
        headers={"User-Agent": "ForjaStore/2.0"})
    with urllib.request.urlopen(request, timeout=20) as response:
        data = json.loads(response.read().decode("utf-8"))
    return data.get("results", []) if data.get("type") == "search" else []

class Store(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="br.forja.Store",
                         flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE)
        self.window = None
        self.body = None
        self.content = None
        self.search = None
        self.status = None
        self.installed = set()
        self.installed_flatpak = {}
        self.busy = False
        self.generation = 0
        self.current_page = "Destaques"
        self.updates_mode = False

    def do_command_line(self, cmdline):
        self.updates_mode = "--updates" in cmdline.get_arguments()
        self.activate()
        return 0

    def do_activate(self):
        if self.window:
            self.window.present()
            if self.updates_mode:
                self.show_updates()
            return
        self.window = Gtk.ApplicationWindow(application=self, title="Forja Store")
        self.window.set_default_size(1080, 720)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.apply_style()
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        top.set_border_width(18)
        brand = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        mark = Gtk.Image.new_from_icon_name("forja-store", Gtk.IconSize.DIALOG)
        mark.set_pixel_size(38)
        brand.pack_start(mark, False, False, 0)
        word = Gtk.Label()
        word.set_markup("<span size='x-large' weight='bold'>Forja</span> <span size='x-large' foreground='#76b7ed'>Store</span>")
        brand.pack_start(word, False, False, 0)
        top.pack_start(brand, False, False, 0)
        self.search = Gtk.SearchEntry()
        self.search.set_placeholder_text("Buscar aplicativos e ferramentas")
        self.search.set_size_request(360, -1)
        self.search.set_hexpand(True)
        self.search.connect("search-changed", self.on_search)
        top.pack_start(self.search, True, True, 12)
        update_button = Gtk.Button(label="Atualizações")
        update_button.connect("clicked", lambda *_: self.show_updates())
        top.pack_end(update_button, False, False, 0)
        root.pack_start(top, False, False, 0)
        root.pack_start(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL), False, False, 0)

        split = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        sidebar.set_size_request(205, -1)
        sidebar.set_border_width(14)
        for category in CATEGORIES:
            button = Gtk.Button(label=category)
            button.set_relief(Gtk.ReliefStyle.NONE)
            button.set_halign(Gtk.Align.FILL)
            button.connect("clicked", self.navigate, category)
            sidebar.pack_start(button, False, False, 0)
        split.pack_start(sidebar, False, False, 0)
        split.pack_start(Gtk.Separator(orientation=Gtk.Orientation.VERTICAL), False, False, 0)
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        self.content.set_border_width(24)
        scroller.add(self.content)
        split.pack_start(scroller, True, True, 0)
        root.pack_start(split, True, True, 0)
        root.pack_start(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL), False, False, 0)
        self.status = Gtk.Label(label="Aplicativos para sua Forja OS", xalign=0)
        self.status.set_border_width(10)
        root.pack_start(self.status, False, False, 0)
        self.window.add(root)
        self.window.show_all()
        self.reload_installed()
        if self.updates_mode:
            self.show_updates()
        else:
            self.show_home()

    def apply_style(self):
        css = b"""
        window, .background { background: #17191d; color: #e8eaf0; }
        headerbar { background: #202329; }
        button { background: #292d34; color: #e8eaf0; border: 1px solid #3a414b; border-radius: 8px; padding: 8px 13px; }
        button:hover { background: #343b45; }
        entry { background: #252a31; color: #f4f6fa; border: 1px solid #46505d; border-radius: 9px; padding: 9px; }
        .card { background: #22262c; border: 1px solid #353c46; border-radius: 12px; padding: 15px; }
        label { color: #e8eaf0; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def set_status(self, text):
        if self.status:
            self.status.set_text(text)

    def clear(self):
        for child in self.content.get_children():
            self.content.remove(child)

    def heading(self, title, subtitle=None):
        label = Gtk.Label(label=title, xalign=0)
        label.set_markup("<span size='xx-large' weight='bold'>" + GLib.markup_escape_text(title) + "</span>")
        self.content.pack_start(label, False, False, 0)
        if subtitle:
            sub = Gtk.Label(label=subtitle, xalign=0, wrap=True)
            sub.set_line_wrap(True)
            self.content.pack_start(sub, False, False, 0)

    def reload_installed(self):
        def worker():
            result = run(["pacman", "-Q"], 60)
            names = {line.split()[0] for line in result.stdout.splitlines() if line.split()}
            flatpak_apps = {}
            if shutil.which("flatpak"):
                listing = run(["flatpak", "list", "--app", "--columns=application,installation"], 60)
                for line in listing.stdout.splitlines():
                    fields = line.split()
                    if len(fields) >= 2 and "." in fields[0]:
                        flatpak_apps[fields[0]] = fields[1].lower()
            GLib.idle_add(self.set_installed, names, flatpak_apps)
        threading.Thread(target=worker, daemon=True).start()

    def set_installed(self, names, flatpak_apps=None):
        self.installed = names
        self.installed_flatpak = flatpak_apps or {}
        return GLib.SOURCE_REMOVE

    def navigate(self, _button, category):
        self.current_page = category
        self.search.set_text("")
        self.show_category(category)

    def show_home(self):
        self.current_page = "Destaques"
        self.show_category("Destaques")

    def show_category(self, category):
        self.clear()
        self.heading(category, "Aplicativos selecionados para começar. Use a busca para encontrar outros pacotes dos repositórios Arch e do AUR.")
        grid = Gtk.FlowBox()
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        grid.set_homogeneous(True)
        grid.set_min_children_per_line(2)
        grid.set_max_children_per_line(3)
        grid.set_column_spacing(12)
        grid.set_row_spacing(12)
        self.content.pack_start(grid, False, False, 4)
        self.content.show_all()
        names = [item[0] for item in CATALOG.get(category, [])]
        def worker():
            results = []
            for pkg, title, icon, desc in CATALOG.get(category, []):
                if pkg.startswith(" "):
                    continue
                if pkg.endswith("-bin") or pkg == "code":
                    results.append({"name": pkg, "title": title, "icon": icon,
                                    "description": desc, "version": "AUR", "source": "aur"})
                    continue
                info = run(["pacman", "-Si", pkg], 20)
                if info.returncode == 0:
                    version, description = "", desc
                    for line in info.stdout.splitlines():
                        if line.strip().startswith("Version"):
                            version = line.split(":", 1)[-1].strip()
                        if line.strip().startswith("Description"):
                            description = line.split(":", 1)[-1].strip()
                    results.append({"name": pkg, "title": title, "icon": icon,
                                    "description": description, "version": version,
                                    "source": "official"})
            GLib.idle_add(self.render_catalog, category, results)
        threading.Thread(target=worker, daemon=True).start()

    def render_catalog(self, category, results):
        if self.current_page != category:
            return GLib.SOURCE_REMOVE
        for child in self.content.get_children():
            if isinstance(child, Gtk.FlowBox):
                self.content.remove(child)
        grid = Gtk.FlowBox()
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        grid.set_homogeneous(True)
        grid.set_min_children_per_line(2)
        grid.set_max_children_per_line(3)
        grid.set_column_spacing(12)
        grid.set_row_spacing(12)
        for item in results:
            grid.add(self.make_card(item))
        self.content.pack_start(grid, False, False, 4)
        self.content.show_all()
        self.set_status(str(len(results)) + " aplicativos nesta seleção.")
        return GLib.SOURCE_REMOVE

    def make_card(self, item):
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        card.get_style_context().add_class("card")
        top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        icon = Gtk.Image.new_from_icon_name(item.get("icon", "application-x-executable"), Gtk.IconSize.DIALOG)
        icon.set_pixel_size(42)
        top.pack_start(icon, False, False, 0)
        title = Gtk.Label(label=item["title"], xalign=0)
        title.set_line_wrap(True)
        title.set_markup("<b>" + GLib.markup_escape_text(item["title"]) + "</b>")
        top.pack_start(title, True, True, 0)
        card.pack_start(top, False, False, 0)
        desc = Gtk.Label(label=item.get("description", ""), xalign=0, yalign=0)
        desc.set_line_wrap(True)
        desc.set_max_width_chars(38)
        card.pack_start(desc, True, True, 0)
        source_label = {"aur": "AUR comunitário", "flatpak": "Flathub", "official": "Repositório oficial"}[item["source"]]
        meta = Gtk.Label(label=source_label +
                         (" · " + item.get("version", "") if item.get("version") else ""), xalign=0)
        card.pack_start(meta, False, False, 0)
        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        details = Gtk.Button(label="Detalhes")
        details.connect("clicked", self.show_details, item)
        actions.pack_start(details, False, False, 0)
        installed = (item["name"] in self.installed if item["source"] == "official"
                     else item["name"] in self.installed_flatpak if item["source"] == "flatpak"
                     else item["name"] in self.installed)
        action = Gtk.Button(label="Remover" if installed else "Instalar")
        action.connect("clicked", self.package_action, item)
        actions.pack_end(action, False, False, 0)
        card.pack_start(actions, False, False, 0)
        return card

    def show_details(self, _button, item):
        dialog = Gtk.Dialog(title=item["title"], transient_for=self.window, modal=True)
        dialog.add_button("Fechar", Gtk.ResponseType.CLOSE)
        box = dialog.get_content_area()
        box.set_border_width(20)
        box.set_spacing(12)
        icon = Gtk.Image.new_from_icon_name(item.get("icon", "application-x-executable"), Gtk.IconSize.DIALOG)
        icon.set_pixel_size(64)
        box.pack_start(icon, False, False, 0)
        label = Gtk.Label(label=item.get("description", ""), xalign=0, wrap=True)
        box.pack_start(label, False, False, 0)
        source = {"aur": "AUR comunitário: o PKGBUILD será exibido para revisão antes da compilação.",
                  "flatpak": "Aplicativo distribuído pelo Flathub usando Flatpak.",
                  "official": "Pacote dos repositórios oficiais do Arch Linux."}.get(item["source"], "Aplicativo")
        box.pack_start(Gtk.Label(label=source, xalign=0, wrap=True), False, False, 0)
        dialog.show_all()
        dialog.run()
        dialog.destroy()

    def on_search(self, *_):
        query = self.search.get_text().strip()
        if len(query) < 2:
            if not query:
                self.show_category(self.current_page)
            return
        self.generation += 1
        generation = self.generation
        self.clear()
        self.heading("Resultados da busca", "Pesquisa nos repositórios oficiais do Arch e no AUR.")
        self.content.show_all()
        def worker():
            official = run(["pacman", "-Ss", query], 90)
            matches, current = [], None
            for line in official.stdout.splitlines():
                if line and not line[0].isspace():
                    match = re.match(r"^([^/]+)/([^ ]+) ([^ ]+)", line)
                    if match:
                        current = {"name": match.group(2), "title": match.group(2),
                            "version": match.group(3), "description": "", "source": "official",
                            "icon": "application-x-executable"}
                        matches.append(current)
                elif current and line.strip():
                    current["description"] = line.strip()
                    current = None
            aur, error = [], None
            try:
                for item in aur_search(query)[:30]:
                    aur.append({"name": item["Name"], "title": item["Name"],
                        "version": item.get("Version", ""), "description": item.get("Description", ""),
                        "source": "aur", "icon": "application-x-executable"})
            except Exception as exc:
                error = "AUR: " + str(exc)
            flatpak_items = []
            if shutil.which("flatpak"):
                remotes = run(["flatpak", "remotes", "--user", "--columns=name"], 60)
                if "flathub" not in remotes.stdout.splitlines():
                    run(["flatpak", "remote-add", "--user", "--if-not-exists", "flathub",
                         "https://flathub.org/repo/flathub.flatpakrepo"], 120)
                fp = run(["flatpak", "search", "--columns=application,name,description", query], 90)
                for line in fp.stdout.splitlines():
                    fields = [part.strip() for part in line.split("\t")]
                    if len(fields) < 2:
                        fields = line.split(None, 2)
                    if len(fields) >= 2 and "." in fields[0] and fields[0].lower() not in {"application", "application id"}:
                        flatpak_items.append({"name": fields[0], "title": fields[1],
                            "version": "Flathub", "description": fields[2] if len(fields) > 2 else "",
                            "source": "flatpak", "icon": "application-x-executable"})
            GLib.idle_add(self.show_search_results, generation, matches[:45], aur, flatpak_items, error)
        threading.Thread(target=worker, daemon=True).start()

    def show_search_results(self, generation, official, aur, flatpak_items, error):
        if generation != self.generation:
            return GLib.SOURCE_REMOVE
        self.clear()
        self.heading("Resultados da busca", "Aplicativos encontrados nos repositórios oficiais, AUR e Flathub.")
        if error:
            self.content.pack_start(Gtk.Label(label="Aviso de pesquisa: " + error, xalign=0, wrap=True), False, False, 4)
        for title, items in (("Arch Linux", official), ("AUR comunitário", aur), ("Flathub", flatpak_items)):
            self.heading(title)
            grid = Gtk.FlowBox()
            grid.set_selection_mode(Gtk.SelectionMode.NONE)
            grid.set_homogeneous(True)
            grid.set_min_children_per_line(2)
            grid.set_max_children_per_line(3)
            grid.set_column_spacing(12)
            grid.set_row_spacing(12)
            for item in items:
                grid.add(self.make_card(item))
            self.content.pack_start(grid, False, False, 4)
        self.content.show_all()
        self.set_status(str(len(official) + len(aur) + len(flatpak_items)) + " resultados.")
        return GLib.SOURCE_REMOVE

    def package_action(self, _button, item):
        name = item["name"]
        if not PKG_RE.fullmatch(name):
            self.set_status("Nome de pacote inválido.")
            return
        if item["source"] == "aur":
            if name in self.installed:
                if self.confirm("Remover pacote AUR", "Remover " + name + " usando o Pacman?"):
                    self.run_privileged(["remove", name], "Remoção de " + name)
                return
            if not shutil.which("mate-terminal"):
                self.set_status("O terminal MATE não está disponível para a revisão e compilação segura do AUR.")
                return
            if self.confirm("Revisão do AUR",
                "A loja abrirá uma janela de terminal para mostrar os arquivos do pacote. "
                "Revise o PKGBUILD e só digite COMPILAR se confiar no mantenedor. "
                "A compilação será executada como usuário comum."):
                subprocess.Popen(["mate-terminal", "--title=Forja Store · Revisão AUR",
                                  "--", "/usr/bin/forja-aur-build", name])
            return

        if item["source"] == "flatpak":
            installed_scope = self.installed_flatpak.get(name)
            if installed_scope:
                if not self.confirm("Remover aplicativo Flatpak", "Remover " + name + " (" + installed_scope + ")?"):
                    return
                if installed_scope == "system":
                    self.run_privileged(["flatpak-remove-system", name], "Remoção Flatpak de " + name)
                else:
                    self.run_unprivileged(["flatpak", "uninstall", "--user", "--noninteractive", "--assumeyes", name],
                                          "Remoção Flatpak de " + name)
            else:
                dialog = Gtk.MessageDialog(transient_for=self.window, modal=True,
                    message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.NONE,
                    text="Onde deseja instalar o aplicativo?")
                dialog.format_secondary_text(name + " será instalado a partir do Flathub.")
                dialog.add_button("Cancelar", Gtk.ResponseType.CANCEL)
                dialog.add_button("Só este usuário", Gtk.ResponseType.ACCEPT)
                dialog.add_button("Todos os usuários", Gtk.ResponseType.YES)
                response = dialog.run()
                dialog.destroy()
                if response == Gtk.ResponseType.ACCEPT:
                    self.run_unprivileged(["flatpak", "remote-add", "--user", "--if-not-exists",
                                           "flathub", "https://flathub.org/repo/flathub.flatpakrepo"],
                                          "Instalação Flatpak de " + name, follow_up=[
                        "flatpak", "install", "--user", "--noninteractive", "--assumeyes", "flathub", name])
                elif response == Gtk.ResponseType.YES:
                    self.run_privileged(["flatpak-install-system", name], "Instalação Flatpak de " + name)
            return

        installed = name in self.installed
        verb = "remover" if installed else "instalar"
        if not self.confirm("Gerenciar aplicativo", verb.capitalize() + " " + name + " usando o Pacman?"):
            return
        action = "remove" if installed else "install"
        self.run_privileged([action, name], ("Remoção de " if installed else "Instalação de ") + name)

    def confirm(self, title, message):
        dialog = Gtk.MessageDialog(transient_for=self.window, modal=True,
            message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.OK_CANCEL, text=title)
        dialog.format_secondary_text(message)
        response = dialog.run()
        dialog.destroy()
        return response == Gtk.ResponseType.OK

    def run_unprivileged(self, args, label, follow_up=None):
        if self.busy:
            self.set_status("Já existe uma operação em andamento.")
            return
        if not shutil.which(args[0]):
            self.set_status("Ferramenta necessária não está instalada: " + args[0])
            return
        self.busy = True
        self.set_status(label + "…")
        def worker():
            result = run(args, 7200)
            if result.returncode == 0 and follow_up:
                result = run(follow_up, 7200)
            GLib.idle_add(self.operation_done, result.returncode, result.stdout, label)
        threading.Thread(target=worker, daemon=True).start()

    def run_privileged(self, args, label):
        if self.busy:
            self.set_status("Já existe uma operação em andamento.")
            return
        self.busy = True
        self.set_status("Aguardando autorização para " + label.lower() + "…")
        def worker():
            result = run(["pkexec", HELPER] + args, 7200)
            GLib.idle_add(self.operation_done, result.returncode, result.stdout, label)
        threading.Thread(target=worker, daemon=True).start()

    def operation_done(self, code, output, label):
        self.busy = False
        self.set_status(label + (" concluída." if code == 0 else " não concluída: " + (output[-250:] if output else "operação cancelada.")))
        self.reload_installed()
        if code == 0:
            if self.current_page == "updates":
                self.show_updates()
            else:
                self.show_category(self.current_page)
        return GLib.SOURCE_REMOVE

    def show_updates(self):
        self.current_page = "updates"
        self.clear()
        self.heading("Atualizações", "Gerencie separadamente o Arch Linux e os aplicativos Flatpak.")
        self.content.pack_start(Gtk.Label(label="Consultando atualizações disponíveis…", xalign=0), False, False, 6)
        self.content.show_all()
        def worker():
            result = run(["checkupdates"], 180)
            rows = [line.strip() for line in result.stdout.splitlines() if line.strip()]
            error = result.returncode not in (0, 2)
            flat_system, flat_user = [], []
            flat_error = None
            if shutil.which("flatpak"):
                for scope, target in (("--system", flat_system), ("--user", flat_user)):
                    fp = run(["flatpak", "remote-ls", scope, "--updates", "--columns=application"], 180)
                    if fp.returncode == 0:
                        target.extend(line.strip() for line in fp.stdout.splitlines()
                                      if line.strip() and "." in line)
                    elif "No remote refs found" not in fp.stdout + fp.stderr:
                        flat_error = (fp.stderr or fp.stdout).strip() or "Falha ao consultar Flatpak."
            GLib.idle_add(self.render_updates, rows, error, result.stdout, flat_system, flat_user, flat_error)
        threading.Thread(target=worker, daemon=True).start()

    def render_updates(self, rows, error, output, flat_system=None, flat_user=None, flat_error=None):
        self.clear()
        self.heading("Atualizações", "Atualização completa do Arch e atualizações independentes do Flatpak.")
        if error:
            self.content.pack_start(Gtk.Label(label="Falha ao consultar Pacman: " + output, xalign=0, wrap=True), False, False, 6)
        elif rows:
            for row in rows:
                self.content.pack_start(Gtk.Label(label=row, xalign=0), False, False, 2)
            button = Gtk.Button(label="Atualizar sistema Arch")
            button.set_halign(Gtk.Align.START)
            button.connect("clicked", self.update_system)
            self.content.pack_start(button, False, False, 12)
        else:
            self.content.pack_start(Gtk.Label(label="Arch Linux: nenhuma atualização disponível.", xalign=0), False, False, 8)
        if shutil.which("flatpak"):
            if flat_error:
                self.content.pack_start(Gtk.Label(label="Aviso Flatpak: " + flat_error, xalign=0, wrap=True), False, False, 6)
            system_count = len(flat_system or [])
            user_count = len(flat_user or [])
            self.content.pack_start(Gtk.Label(label=f"Flatpak do sistema: {system_count} atualização(ões).", xalign=0), False, False, 4)
            system_button = Gtk.Button(label="Atualizar Flatpak do sistema")
            system_button.set_halign(Gtk.Align.START)
            system_button.connect("clicked", self.update_flatpak, "--system")
            self.content.pack_start(system_button, False, False, 4)
            self.content.pack_start(Gtk.Label(label=f"Flatpak do usuário: {user_count} atualização(ões).", xalign=0), False, False, 4)
            user_button = Gtk.Button(label="Atualizar Flatpak do usuário")
            user_button.set_halign(Gtk.Align.START)
            user_button.connect("clicked", self.update_flatpak, "--user")
            self.content.pack_start(user_button, False, False, 4)
        self.content.show_all()
        self.set_status("Consulta concluída.")
        return GLib.SOURCE_REMOVE

    def update_flatpak(self, _button, scope):
        label = "Atualização Flatpak do sistema" if scope == "--system" else "Atualização Flatpak do usuário"
        if not self.confirm(label, "Instalar as atualizações disponíveis para esta instalação Flatpak?"):
            return
        if scope == "--system":
            self.run_privileged(["flatpak-update-system"], label)
        else:
            self.run_unprivileged(["flatpak", "update", "--user", "--noninteractive", "--assumeyes"], label)

    def update_system(self, *_):
        if self.confirm("Atualizar Forja OS", "Será executada uma atualização completa com pacman -Syu. Não desligue o computador durante o processo."):
            self.run_privileged(["upgrade"], "Atualização do sistema")

if __name__ == "__main__":
    raise SystemExit(Store().run(None))
