#!/usr/bin/env python3
"""Forja Monitor: monitor de sistema GTK3, leve e sem daemon residente."""
import glob
import os
import platform
import pwd
import shutil
import signal
import sys
import time
import json
from datetime import datetime

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk, Pango, cairo

APP_ID = "br.forja.monitor"
APP_DIR = "/usr/share/forja-monitor"
INSTALL_INFO = "/var/lib/forja-os/install-info.json"
BG, PANEL, CARD = "#17191c", "#202328", "#272c32"
TEXT, MUTED, LINE = "#e7e9ec", "#969da7", "#383e46"
ACCENT = "#aeb4bc"
PROCESS_REFRESH_SECONDS = 3
METRIC_REFRESH_SECONDS = 2
PSEUDO_FS = {
    "proc", "sysfs", "devtmpfs", "devpts", "tmpfs", "cgroup", "cgroup2",
    "pstore", "securityfs", "debugfs", "tracefs", "configfs", "fusectl",
    "mqueue", "hugetlbfs", "rpc_pipefs", "autofs", "overlay", "squashfs",
}


def read_text(path, default=""):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as stream:
            return stream.read()
    except OSError:
        return default


def parse_meminfo():
    values = {}
    for line in read_text("/proc/meminfo").splitlines():
        parts = line.split()
        if len(parts) >= 2:
            try:
                values[parts[0].rstrip(":")] = int(parts[1]) * 1024
            except ValueError:
                pass
    return values


def memory_snapshot():
    info = parse_meminfo()
    total = info.get("MemTotal", 0)
    available = info.get("MemAvailable", info.get("MemFree", 0))
    used = max(0, total - available)
    swap_total = info.get("SwapTotal", 0)
    swap_free = info.get("SwapFree", 0)
    return used, total, max(0, swap_total - swap_free), swap_total


def cpu_snapshot():
    result = {}
    for line in read_text("/proc/stat").splitlines():
        parts = line.split()
        if not parts or not parts[0].startswith("cpu"):
            continue
        try:
            values = [int(v) for v in parts[1:]]
            if len(values) < 4:
                continue
            idle = values[3] + (values[4] if len(values) > 4 else 0)
            result[parts[0]] = (sum(values), idle)
        except ValueError:
            continue
    return result


def network_snapshot():
    result = {}
    for line in read_text("/proc/net/dev").splitlines()[2:]:
        if ":" not in line:
            continue
        name, data = line.split(":", 1)
        name = name.strip()
        fields = data.split()
        try:
            if name != "lo" and len(fields) >= 9:
                result[name] = (int(fields[0]), int(fields[8]))
        except ValueError:
            continue
    return result


def temperature_snapshot():
    readings = []
    for path in glob.glob("/sys/class/hwmon/hwmon*/temp*_input"):
        try:
            raw = int(read_text(path).strip())
            value = raw / 1000.0
        except ValueError:
            continue
        if not -10 <= value <= 150:
            continue
        base = path.rsplit("/", 1)[0]
        sensor = read_text(os.path.join(base, "name")).strip() or "Sensor"
        label = read_text(path[:-6] + "_label").strip()
        name = " ".join(part for part in (sensor, label) if part)
        readings.append((name, value))
    return readings


def disk_snapshot():
    """Partições reais montadas, sem pseudo-filesystems."""
    mounts = []
    seen = set()
    for line in read_text("/proc/mounts").splitlines():
        parts = line.split()
        if len(parts) < 3:
            continue
        device, mountpoint, fstype = parts[:3]
        if fstype in PSEUDO_FS or mountpoint in seen:
            continue
        if not device.startswith("/dev/") and fstype not in ("btrfs", "zfs"):
            continue
        seen.add(mountpoint)
        try:
            usage = shutil.disk_usage(mountpoint)
        except OSError:
            continue
        mounts.append((device, mountpoint, fstype, usage.total, usage.used, usage.free))
    mounts.sort(key=lambda item: (item[1] != "/", item[1]))
    return mounts


def process_snapshot():
    """Lê processos visíveis em /proc, sem executar comandos externos."""
    rows, ticks = [], {}
    page_size = os.sysconf("SC_PAGE_SIZE")
    clock_ticks = os.sysconf("SC_CLK_TCK")
    for entry in os.scandir("/proc"):
        if not entry.name.isdigit():
            continue
        pid = int(entry.name)
        try:
            raw = read_text(f"/proc/{pid}/stat")
            end = raw.rfind(")")
            if end < 0:
                continue
            name = raw[raw.find("(") + 1:end]
            fields = raw[end + 2:].split()
            state = fields[0]
            proc_ticks = int(fields[11]) + int(fields[12])
            statm = read_text(f"/proc/{pid}/statm").split()
            rss = int(statm[1]) * page_size if len(statm) > 1 else 0
            uid = None
            for line in read_text(f"/proc/{pid}/status").splitlines():
                if line.startswith("Uid:"):
                    uid = int(line.split()[1])
                    break
            try:
                owner = pwd.getpwuid(uid).pw_name if uid is not None else "?"
            except KeyError:
                owner = str(uid) if uid is not None else "?"
            ticks[pid] = proc_ticks
            rows.append((pid, name, owner, state, proc_ticks, rss, clock_ticks))
        except (OSError, ValueError, IndexError, ProcessLookupError):
            continue
    return ticks, rows


def format_bytes(value):
    value = float(max(0, value))
    units = ("B", "KB", "MB", "GB", "TB")
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.0f} {unit}" if unit == "B" else f"{value:.1f} {unit}"
        value /= 1024
    return f"{value:.1f} TB"


def format_uptime():
    try:
        seconds = int(float(read_text("/proc/uptime").split()[0]))
    except (ValueError, IndexError):
        return "Não disponível"
    days, seconds = divmod(seconds, 86400)
    hours, seconds = divmod(seconds, 3600)
    minutes = seconds // 60
    return f"{days} d, {hours} h, {minutes} min" if days else f"{hours} h, {minutes} min"


class MiniGraph(Gtk.DrawingArea):
    def __init__(self):
        super().__init__()
        self.values = []
        self.set_size_request(130, 42)
        self.connect("draw", self.draw_graph)

    def push(self, value):
        self.values.append(max(0.0, min(100.0, float(value))))
        del self.values[:-48]
        self.queue_draw()

    def draw_graph(self, widget, cr):
        width, height = widget.get_allocated_width(), widget.get_allocated_height()
        cr.set_source_rgb(0.22, 0.24, 0.27)
        cr.set_line_width(1)
        cr.move_to(0, height * .5)
        cr.line_to(width, height * .5)
        cr.stroke()
        if len(self.values) < 2:
            return False
        cr.set_source_rgb(0.70, 0.73, 0.77)
        cr.set_line_width(1.8)
        step = width / (len(self.values) - 1)
        for index, value in enumerate(self.values):
            x = index * step
            y = height - (value / 100.0 * (height - 5)) - 2
            cr.move_to(x, y) if index == 0 else cr.line_to(x, y)
        cr.stroke()
        return False


class MetricCard(Gtk.Box):
    def __init__(self, title):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.get_style_context().add_class("metric-card")
        header = Gtk.Box(spacing=4)
        label = Gtk.Label(label=title, xalign=0)
        label.get_style_context().add_class("card-title")
        header.pack_start(label, True, True, 0)
        self.value = Gtk.Label(label="--", xalign=1)
        self.value.get_style_context().add_class("metric-value")
        header.pack_end(self.value, False, False, 0)
        self.pack_start(header, False, False, 0)
        self.graph = MiniGraph()
        self.pack_start(self.graph, True, True, 0)
        self.detail = Gtk.Label(label="", xalign=0)
        self.detail.get_style_context().add_class("muted")
        self.detail.set_ellipsize(Pango.EllipsizeMode.END)
        self.pack_start(self.detail, False, False, 0)


class ForjaMonitor(Gtk.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID)
        self.prev_cpu = cpu_snapshot()
        self.prev_net = network_snapshot()
        self.prev_time = time.monotonic()
        self.last_process_ticks = {}
        self.last_process_time = time.monotonic()
        self.process_data = {}
        self.current_page = "overview"

    def do_activate(self):
        self.win = Gtk.ApplicationWindow(application=self)
        self.win.set_title("Forja Monitor")
        self.win.set_default_size(1260, 800)
        self.win.set_size_request(920, 620)
        self.apply_css()

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        root.get_style_context().add_class("root")
        self.win.add(root)
        root.pack_start(self.make_header(), False, False, 0)
        root.pack_start(Gtk.Separator(), False, False, 0)

        body = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        root.pack_start(body, True, True, 0)
        body.pack_start(self.make_sidebar(), False, False, 0)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.NONE)
        self.stack.set_hexpand(True)
        self.stack.set_vexpand(True)
        self.stack.set_margin_start(18)
        self.stack.set_margin_end(18)
        self.stack.set_margin_top(18)
        self.stack.set_margin_bottom(18)
        body.pack_start(self.stack, True, True, 0)
        self.stack.add_named(self.make_overview_page(), "overview")
        self.stack.add_named(self.make_process_page(), "processes")
        self.stack.add_named(self.make_system_page(), "system")
        self.show_page("overview")

        self.win.show_all()
        self.refresh_metrics()
        self.refresh_processes()
        GLib.timeout_add_seconds(METRIC_REFRESH_SECONDS, self.refresh_metrics)
        GLib.timeout_add_seconds(PROCESS_REFRESH_SECONDS, self.refresh_processes)

    def apply_css(self):
        css = b"""
        window, .root { background: #17191c; color: #e7e9ec; }
        .header { background: #202328; padding: 13px 20px; }
        .brand { color: #f0f2f5; font-size: 15pt; font-weight: 800; letter-spacing: 1px; }
        .muted { color: #969da7; font-size: 9pt; }
        .sidebar { background: #1c1f23; border-right: 1px solid #343a42; padding: 16px 10px; }
        .nav-button { background: transparent; color: #b9c0c8; border: 0; border-radius: 6px; padding: 10px 12px; text-align: left; }
        .nav-button:hover { background: #292e34; color: #ffffff; }
        .nav-button:checked { background: #343a41; color: #ffffff; }
        .panel { background: #202328; border: 1px solid #343a42; border-radius: 9px; padding: 15px; }
        .panel-title { color: #f0f2f5; font-size: 16pt; font-weight: 650; }
        .section-title { color: #d9dde2; font-size: 10pt; font-weight: 650; }
        .metric-card { background: #272c32; border: 1px solid #383f48; border-radius: 8px; padding: 12px; }
        .card-title { color: #aeb6c0; font-size: 9pt; font-weight: 600; }
        .metric-value { color: #f0f2f5; font-size: 17pt; font-weight: 650; }
        .info-row { border-bottom: 1px solid #343a42; padding: 9px 3px; }
        .info-key { color: #969da7; font-size: 9pt; }
        .info-value { color: #e3e6ea; font-size: 9pt; }
        treeview, treeview.view { background: #202328; color: #e2e5e9; }
        treeview.view:selected { background: #454b53; color: #ffffff; }
        treeview header button { background: #292e35; color: #bfc6cf; border: 0; padding: 8px; }
        entry, searchentry { background: #292e35; color: #e7e9ec; border: 1px solid #414851; border-radius: 6px; padding: 7px; }
        button.action { background: #343a41; color: #f0f2f5; border: 1px solid #4a515a; border-radius: 6px; padding: 8px 12px; }
        button.action:hover { background: #424951; }
        scrolledwindow { border: 1px solid #383f48; border-radius: 6px; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def make_header(self):
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        header.get_style_context().add_class("header")
        logo_path = os.path.join(APP_DIR, "forja-flame.svg")
        if os.path.exists(logo_path):
            logo = Gtk.Image.new_from_file(logo_path)
            logo.set_pixel_size(28)
            header.pack_start(logo, False, False, 0)
        brand = Gtk.Button()
        brand.set_relief(Gtk.ReliefStyle.NONE)
        brand.set_tooltip_text("Abrir informações do sistema")
        label = Gtk.Label()
        label.set_markup('<span weight="bold" foreground="#e7e9ec" size="large">FORJA</span><span foreground="#aeb4bc" weight="bold" size="large">.</span>')
        label.get_style_context().add_class("brand")
        brand.add(label)
        brand.connect("clicked", lambda *_: self.show_page("system"))
        header.pack_start(brand, False, False, 0)
        subtitle = Gtk.Label(label="MONITOR DO SISTEMA", xalign=0)
        subtitle.get_style_context().add_class("muted")
        header.pack_start(subtitle, False, False, 12)
        self.header_status = Gtk.Label(label="Monitoramento ativo", xalign=1)
        self.header_status.get_style_context().add_class("muted")
        header.pack_end(self.header_status, False, False, 0)
        return header

    def make_sidebar(self):
        side = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=7)
        side.set_size_request(190, -1)
        side.get_style_context().add_class("sidebar")
        self.nav_buttons = {}
        for key, title in (("overview", "Visão geral"), ("processes", "Processos"), ("system", "Sistema")):
            button = Gtk.ToggleButton(label=title)
            button.set_relief(Gtk.ReliefStyle.NONE)
            button.get_style_context().add_class("nav-button")
            button.connect("toggled", self.on_nav_toggled, key)
            side.pack_start(button, False, False, 0)
            self.nav_buttons[key] = button
        spacer = Gtk.Box()
        side.pack_start(spacer, True, True, 0)
        note = Gtk.Label(label="FORJA OS\nMonitor leve\nDados do sistema", xalign=0)
        note.get_style_context().add_class("muted")
        note.set_margin_start(10)
        note.set_margin_bottom(8)
        side.pack_start(note, False, False, 0)
        return side

    def on_nav_toggled(self, button, key):
        if button.get_active():
            self.show_page(key)

    def show_page(self, key):
        self.current_page = key
        self.stack.set_visible_child_name(key)
        for name, button in self.nav_buttons.items():
            if name != key:
                button.set_active(False)
            else:
                button.set_active(True)

    def page_heading(self, title, subtitle):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        label = Gtk.Label(label=title, xalign=0)
        label.get_style_context().add_class("panel-title")
        box.pack_start(label, False, False, 0)
        desc = Gtk.Label(label=subtitle, xalign=0)
        desc.get_style_context().add_class("muted")
        box.pack_start(desc, False, False, 0)
        return box

    def make_overview_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        page.pack_start(self.page_heading("Visão geral", "Resumo em tempo real dos recursos do computador"), False, False, 0)
        grid = Gtk.Grid()
        grid.set_column_spacing(12)
        grid.set_row_spacing(12)
        grid.set_column_homogeneous(True)
        self.cpu_card = MetricCard("Processador")
        self.memory_card = MetricCard("Memória RAM")
        self.disk_card = MetricCard("Armazenamento principal")
        self.net_card = MetricCard("Tráfego de rede")
        for card, col, row in ((self.cpu_card, 0, 0), (self.memory_card, 1, 0), (self.disk_card, 0, 1), (self.net_card, 1, 1)):
            grid.attach(card, col, row, 1, 1)
        page.pack_start(grid, False, False, 0)

        lower = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        page.pack_start(lower, True, True, 0)
        disk_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        disk_panel.get_style_context().add_class("panel")
        disk_panel.set_hexpand(True)
        disk_panel.pack_start(self.section_label("Volumes montados"), False, False, 0)
        self.disk_details = Gtk.Label(label="Detectando volumes…", xalign=0, yalign=0)
        self.disk_details.set_selectable(True)
        self.disk_details.set_line_wrap(True)
        disk_panel.pack_start(self.disk_details, True, True, 0)
        lower.pack_start(disk_panel, True, True, 0)

        sensor_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        sensor_panel.get_style_context().add_class("panel")
        sensor_panel.set_size_request(250, -1)
        sensor_panel.pack_start(self.section_label("Sensores térmicos"), False, False, 0)
        self.temp_details = Gtk.Label(label="Consultando sensores…", xalign=0, yalign=0)
        self.temp_details.set_line_wrap(True)
        sensor_panel.pack_start(self.temp_details, True, True, 0)
        sensor_panel.pack_start(self.section_label("CPU por núcleo"), False, False, 4)
        self.core_details = Gtk.Label(label="Aguardando leitura…", xalign=0, yalign=0)
        self.core_details.set_line_wrap(True)
        sensor_panel.pack_start(self.core_details, False, False, 0)
        self.swap_label = Gtk.Label(label="SWAP: verificando…", xalign=0)
        self.swap_label.get_style_context().add_class("muted")
        sensor_panel.pack_end(self.swap_label, False, False, 0)
        lower.pack_start(sensor_panel, False, False, 0)
        return page

    def section_label(self, text):
        label = Gtk.Label(label=text, xalign=0)
        label.get_style_context().add_class("section-title")
        return label

    def make_process_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        page.pack_start(self.page_heading("Processos", "Consumo individual e controle dos processos do sistema"), False, False, 0)
        toolbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.process_search = Gtk.SearchEntry()
        self.process_search.set_placeholder_text("Pesquisar processo ou usuário…")
        self.process_search.set_hexpand(True)
        self.process_search.connect("search-changed", self.filter_processes)
        toolbar.pack_start(self.process_search, True, True, 0)
        self.terminate_button = Gtk.Button(label="Encerrar")
        self.terminate_button.get_style_context().add_class("action")
        self.terminate_button.connect("clicked", self.terminate_selected, signal.SIGTERM)
        toolbar.pack_start(self.terminate_button, False, False, 0)
        self.force_button = Gtk.Button(label="Forçar encerramento")
        self.force_button.get_style_context().add_class("action")
        self.force_button.connect("clicked", self.terminate_selected, signal.SIGKILL)
        toolbar.pack_start(self.force_button, False, False, 0)
        page.pack_start(toolbar, False, False, 0)

        self.process_store = Gtk.ListStore(str, int, str, str, str, str, float, int)
        self.process_filter = self.process_store.filter_new()
        self.process_filter.set_visible_func(self.process_visible)
        self.process_view = Gtk.TreeView(model=self.process_filter)
        self.process_view.set_headers_visible(True)
        self.process_view.get_selection().set_mode(Gtk.SelectionMode.SINGLE)
        columns = [
            ("Processo", 0, 0, True),
            ("PID", 1, 1, False),
            ("Usuário", 2, 2, False),
            ("CPU", 3, 6, False),
            ("Memória", 4, 7, False),
            ("Estado", 5, 5, False),
        ]
        for title, visible_col, sort_col, expand in columns:
            renderer = Gtk.CellRendererText()
            renderer.set_padding(8, 6)
            if visible_col == 0:
                renderer.set_property("ellipsize", Pango.EllipsizeMode.END)
            column = Gtk.TreeViewColumn(title, renderer, text=visible_col)
            column.set_resizable(True)
            column.set_expand(expand)
            column.set_sort_column_id(sort_col)
            self.process_view.append_column(column)
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.add(self.process_view)
        page.pack_start(scroll, True, True, 0)
        self.process_count = Gtk.Label(label="Aguardando leitura…", xalign=0)
        self.process_count.get_style_context().add_class("muted")
        page.pack_start(self.process_count, False, False, 0)
        return page

    def process_visible(self, model, tree_iter, _data):
        query = self.process_search.get_text().strip().lower()
        if not query:
            return True
        return query in model[tree_iter][0].lower() or query in model[tree_iter][2].lower() or query in str(model[tree_iter][1])

    def filter_processes(self, *_):
        self.process_filter.refilter()

    def selected_process(self):
        model, tree_iter = self.process_view.get_selection().get_selected()
        if tree_iter is None:
            return None
        return model[tree_iter][1], model[tree_iter][0]

    def terminate_selected(self, _button, sig):
        selected = self.selected_process()
        if not selected:
            self.header_status.set_text("Selecione um processo")
            return
        pid, name = selected
        action = "encerrar" if sig == signal.SIGTERM else "forçar o encerramento"
        dialog = Gtk.MessageDialog(
            transient_for=self.win, flags=Gtk.DialogFlags.MODAL,
            message_type=Gtk.MessageType.WARNING, buttons=Gtk.ButtonsType.NONE,
            text=f"Deseja {action} este processo?",
        )
        dialog.format_secondary_text(f"{name}  •  PID {pid}\nA operação pode causar perda de dados no aplicativo.")
        dialog.add_button("Cancelar", Gtk.ResponseType.CANCEL)
        dialog.add_button("Confirmar", Gtk.ResponseType.OK)
        response = dialog.run()
        dialog.destroy()
        if response != Gtk.ResponseType.OK:
            return
        try:
            current_name = read_text(f"/proc/{pid}/comm").strip()
            if not current_name:
                raise ProcessLookupError
            if current_name != name:
                self.header_status.set_text("O processo mudou desde a seleção. Atualize a lista e tente novamente.")
                return
            if pid in (1, os.getpid()):
                self.header_status.set_text("Este processo é protegido pelo Forja Monitor.")
                return
            os.kill(pid, sig)
            self.header_status.set_text(f"Sinal enviado ao PID {pid}")
        except ProcessLookupError:
            self.header_status.set_text("O processo já foi encerrado")
        except PermissionError:
            self.header_status.set_text("Sem permissão para encerrar esse processo")
        except OSError as exc:
            self.header_status.set_text(f"Falha ao encerrar: {exc.strerror or exc}")

    def make_system_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        page.pack_start(self.page_heading("Informações do sistema", "Identificação do computador, hardware e instalação"), False, False, 0)
        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        panel.get_style_context().add_class("panel")
        self.system_grid = Gtk.Grid()
        self.system_grid.set_column_spacing(20)
        self.system_grid.set_row_spacing(0)
        self.system_grid.set_column_homogeneous(False)
        panel.pack_start(self.system_grid, False, False, 0)
        page.pack_start(panel, False, False, 0)
        note = Gtk.Label(label="As informações são lidas diretamente do Linux. Alguns sensores e identificadores dependem do suporte do kernel e do hardware.", xalign=0)
        note.set_line_wrap(True)
        note.get_style_context().add_class("muted")
        page.pack_start(note, False, False, 0)
        self.populate_system_info()
        return page

    def gpu_name(self):
        names = []
        for vendor_path in glob.glob("/sys/class/drm/card[0-9]*/device/vendor"):
            base = os.path.dirname(vendor_path)
            vendor = read_text(vendor_path).strip().lower()
            device = read_text(os.path.join(base, "device")).strip()
            vendor_name = {"0x8086": "Intel", "0x1002": "AMD", "0x10de": "NVIDIA"}.get(vendor, vendor or "GPU")
            label = f"{vendor_name} ({device})" if device else vendor_name
            if label not in names:
                names.append(label)
        return ", ".join(names) if names else "Não detectada"

    def installation_date(self):
        try:
            payload = json.loads(read_text(INSTALL_INFO, "{}"))
            stamp = payload.get("installed_at")
            if not stamp:
                return "Não registrada pelo instalador"
            installed = datetime.fromisoformat(stamp.replace("Z", "+00:00"))
            if installed.tzinfo is None:
                return "Registro sem fuso horário"
            return installed.astimezone().strftime("%d/%m/%Y às %H:%M:%S %Z")
        except (ValueError, TypeError, OSError):
            return "Registro indisponível"

    def system_information(self):
        cpu_name = "Não identificado"
        for line in read_text("/proc/cpuinfo").splitlines():
            if line.lower().startswith(("model name", "hardware")):
                cpu_name = line.split(":", 1)[-1].strip()
                break
        os_info = {}
        for line in read_text("/etc/os-release").splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                os_info[key] = value.strip().strip('"')
        mem_used, mem_total, _, _ = memory_snapshot()
        disk = shutil.disk_usage("/")
        screen = Gdk.Screen.get_default()
        resolution = f"{screen.get_width()} × {screen.get_height()}" if screen else "Não disponível"
        board = read_text("/sys/devices/virtual/dmi/id/board_name").strip() or "Não identificado"
        model = read_text("/sys/devices/virtual/dmi/id/product_name").strip() or "Não identificado"
        return [
            ("Distribuição", os_info.get("PRETTY_NAME", "Forja OS")),
            ("Versão", os_info.get("VERSION", "Não informada").strip('"')),
            ("Ambiente gráfico", "MATE"),
            ("Kernel", platform.release()),
            ("Arquitetura", platform.machine()),
            ("Computador", model),
            ("Placa-mãe", board),
            ("Processador", cpu_name),
            ("Núcleos lógicos", str(os.cpu_count() or "Não identificado")),
            ("Gráficos", self.gpu_name()),
            ("Memória RAM", f"{format_bytes(mem_total)} total"),
            ("Armazenamento /", f"{format_bytes(disk.total)} total"),
            ("Resolução", resolution),
            ("Tempo ligado", format_uptime()),
            ("Instalada em", self.installation_date()),
        ]

    def populate_system_info(self):
        for child in self.system_grid.get_children():
            self.system_grid.remove(child)
        for row, (key, value) in enumerate(self.system_information()):
            key_label = Gtk.Label(label=key, xalign=0, yalign=0)
            key_label.get_style_context().add_class("info-key")
            key_label.set_size_request(180, -1)
            value_label = Gtk.Label(label=value, xalign=0, yalign=0)
            value_label.set_selectable(True)
            value_label.set_line_wrap(True)
            value_label.set_max_width_chars(65)
            value_label.get_style_context().add_class("info-value")
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            row_box.get_style_context().add_class("info-row")
            row_box.pack_start(key_label, False, False, 0)
            row_box.pack_start(value_label, True, True, 0)
            self.system_grid.attach(row_box, 0, row, 1, 1)

    def refresh_metrics(self):
        if not hasattr(self, "win") or not self.win.get_visible():
            return True
        now = time.monotonic()
        current_cpu = cpu_snapshot()
        previous_cpu = self.prev_cpu
        total, idle = current_cpu.get("cpu", (0, 0))
        old_total, old_idle = previous_cpu.get("cpu", (0, 0))
        delta_total, delta_idle = total - old_total, idle - old_idle
        cpu_pct = max(0, min(100, (1 - delta_idle / delta_total) * 100)) if delta_total > 0 else 0
        core_values = []
        for core_name in sorted((name for name in current_cpu if name.startswith("cpu") and name != "cpu"),
                                key=lambda name: int(name[3:]) if name[3:].isdigit() else 999999):
            core_total, core_idle = current_cpu[core_name]
            prev_total, prev_idle = previous_cpu.get(core_name, (core_total, core_idle))
            core_delta, idle_delta = core_total - prev_total, core_idle - prev_idle
            if core_delta > 0:
                core_values.append((core_name.upper(), max(0, min(100, (1 - idle_delta / core_delta) * 100))))
        self.prev_cpu = current_cpu
        used, total_mem, swap_used, swap_total = memory_snapshot()
        mem_pct = used * 100 / total_mem if total_mem else 0
        disk = shutil.disk_usage("/")
        disk_pct = disk.used * 100 / disk.total if disk.total else 0

        current_net = network_snapshot()
        elapsed = max(.1, now - self.prev_time)
        rx_rate = tx_rate = 0
        for name, (rx, tx) in current_net.items():
            old_rx, old_tx = self.prev_net.get(name, (rx, tx))
            rx_rate += max(0, rx - old_rx)
            tx_rate += max(0, tx - old_tx)
        rx_rate /= elapsed
        tx_rate /= elapsed
        self.prev_net, self.prev_time = current_net, now
        total_rate = rx_rate + tx_rate

        self.cpu_card.value.set_text(f"{cpu_pct:.0f}%")
        self.cpu_card.detail.set_text(f"{os.cpu_count() or 1} processadores lógicos")
        self.cpu_card.graph.push(cpu_pct)
        self.memory_card.value.set_text(f"{mem_pct:.0f}%")
        self.memory_card.detail.set_text(f"{format_bytes(used)} de {format_bytes(total_mem)}")
        self.memory_card.graph.push(mem_pct)
        self.disk_card.value.set_text(f"{disk_pct:.0f}%")
        self.disk_card.detail.set_text(f"{format_bytes(disk.used)} usados de {format_bytes(disk.total)}")
        self.disk_card.graph.push(disk_pct)
        self.net_card.value.set_text(format_bytes(total_rate) + "/s")
        self.net_card.detail.set_text(f"↓ {format_bytes(rx_rate)}/s    ↑ {format_bytes(tx_rate)}/s")
        self.net_card.graph.push(min(100, total_rate / (10 * 1024 * 1024) * 100))

        swap_pct = swap_used * 100 / swap_total if swap_total else 0
        self.swap_label.set_text(
            f"SWAP: {format_bytes(swap_used)} de {format_bytes(swap_total)} ({swap_pct:.0f}%)"
            if swap_total else "SWAP: não configurada"
        )
        disks = disk_snapshot()
        self.disk_details.set_text(
            "\n".join(f"{mount}  •  {format_bytes(used)} / {format_bytes(total)}  ({used * 100 / total:.0f}%)"
                      for _dev, mount, _fs, total, used, _free in disks)
            if disks else "Nenhum volume de armazenamento detectado."
        )
        sensors = temperature_snapshot()
        self.temp_details.set_text(
            "\n".join(f"{name}: {value:.0f} °C" for name, value in sensors)
            if sensors else "Nenhum sensor térmico disponível. Isso depende do hardware e dos drivers."
        )
        self.core_details.set_text(
            "    ".join(f"{name}: {value:.0f}%" for name, value in core_values)
            if core_values else "Dados por núcleo indisponíveis."
        )
        self.header_status.set_text("Atualizado agora")
        return True

    def refresh_processes(self):
        if not hasattr(self, "win") or not self.win.get_visible():
            return True
        now = time.monotonic()
        new_ticks, rows = process_snapshot()
        elapsed = max(.1, now - self.last_process_time)
        _used, total_memory, _swap_used, _swap_total = memory_snapshot()
        updated = []
        for pid, name, owner, state, ticks, rss, clock_ticks in rows:
            previous = self.last_process_ticks.get(pid)
            cpu_pct = (ticks - previous) / clock_ticks / elapsed * 100 if previous is not None and ticks >= previous else 0.0
            memory_pct = rss * 100 / total_memory if total_memory else 0.0
            updated.append((pid, name, owner, state, cpu_pct, rss, memory_pct))
        self.last_process_ticks = new_ticks
        self.last_process_time = now
        updated.sort(key=lambda item: item[4], reverse=True)
        selected = self.selected_process() if hasattr(self, "process_view") else None
        self.process_store.clear()
        for pid, name, owner, state, cpu_pct, rss, memory_pct in updated:
            self.process_store.append((name, pid, owner, f"{cpu_pct:.1f}%", format_bytes(rss), state, cpu_pct, rss))
        self.process_count.set_text(f"{len(updated)} processos visíveis em /proc  •  CPU por núcleo, pode ultrapassar 100%")
        self.process_data = {item[0]: item for item in updated}
        self.process_filter.refilter()
        if selected:
            for index in range(len(self.process_store)):
                child_iter = self.process_store.iter_nth_child(None, index)
                if self.process_store.get_value(child_iter, 1) == selected[0]:
                    child_path = self.process_store.get_path(child_iter)
                    visible_path = self.process_filter.convert_child_path_to_path(child_path)
                    if visible_path is not None:
                        self.process_view.get_selection().select_path(visible_path)
                    break
        return True


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        init_result = Gtk.init_check([])
        initialized = init_result[0] if isinstance(init_result, tuple) else init_result
        if not initialized:
            raise SystemExit("GTK não conseguiu inicializar o display de teste.")
        app = ForjaMonitor()
        app.register(None)
        app.do_activate()
        app.refresh_metrics()
        app.refresh_processes()
        assert app.cpu_card.value.get_text() != "--"
        assert app.memory_card.value.get_text() != "--"
        assert app.disk_card.value.get_text() != "--"
        assert app.net_card.value.get_text() != "--"
        assert len(app.process_store) >= 1
        assert isinstance(cpu_snapshot(), dict)
        assert isinstance(network_snapshot(), dict)
        assert isinstance(memory_snapshot(), tuple)
        app.win.destroy()
        app.quit()
        print("Forja Monitor GTK smoke test: OK")
    else:
        ForjaMonitor().run(None)
