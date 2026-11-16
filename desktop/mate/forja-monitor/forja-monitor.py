#!/usr/bin/env python3
"""Forja Monitor: painel GTK3 leve, sem dependências do GNOME ou psutil."""
import os
import glob
import time
import shutil
import platform
import re
import sys

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk, Pango, cairo

APP_DIR = "/usr/share/forja-monitor"
INSTALL_INFO = "/var/lib/forja-os/install-info.json"
BG = "#17191c"
PANEL = "#202328"
CARD = "#272c32"
TEXT = "#e7e9ec"
MUTED = "#969da7"
LINE = "#383e46"
ACCENT = "#5598d6"
PROCESS_REFRESH_SECONDS = 3


def read_text(path, default=""):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as stream:
            return stream.read()
    except OSError:
        return default


def meminfo():
    values = {}
    for line in read_text("/proc/meminfo").splitlines():
        parts = line.split()
        if len(parts) >= 2:
            try:
                values[parts[0].rstrip(":")] = int(parts[1]) * 1024
            except ValueError:
                pass
    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", 0)
    return max(0, total - available), total


def cpu_total():
    lines = read_text("/proc/stat").splitlines()
    if not lines:
        return None
    try:
        values = [int(value) for value in lines[0].split()[1:]]
        idle = values[3] + (values[4] if len(values) > 4 else 0)
        return sum(values), idle
    except (ValueError, IndexError):
        return None


def network_total():
    total = 0
    for line in read_text("/proc/net/dev").splitlines()[2:]:
        if ":" not in line:
            continue
        name, data = line.split(":", 1)
        if name.strip() == "lo":
            continue
        fields = data.split()
        try:
            total += int(fields[0]) + int(fields[8])
        except (ValueError, IndexError):
            continue
    return total


def temp_reading():
    candidates = []
    for path in glob.glob("/sys/class/hwmon/hwmon*/temp*_input"):
        try:
            value = int(read_text(path).strip()) / 1000
        except ValueError:
            continue
        if not -10 < value < 150:
            continue
        base = path.rsplit("/", 1)[0]
        sensor = read_text(os.path.join(base, "name")).strip() or "Sensor"
        label = read_text(path[:-6] + "_label").strip()
        name = f"{sensor} {label}".strip()
        candidates.append((name, value))
    for name, value in candidates:
        if any(token in name.lower() for token in ("coretemp", "k10temp", "cpu", "package", "zenpower")):
            return name, value
    return candidates[0] if candidates else (None, None)


def process_snapshot():
    """Lê apenas /proc, sem psutil e sem iniciar processos externos."""
    ticks = {}
    rows = []
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
            # fields[0] é o estado (campo 3); utime/stime são 14/15.
            proc_ticks = int(fields[11]) + int(fields[12])
            state = fields[0]
            statm = read_text(f"/proc/{pid}/statm").split()
            rss = int(statm[1]) * page_size if len(statm) > 1 else 0
            ticks[pid] = proc_ticks
            rows.append((pid, name, state, proc_ticks, rss, clock_ticks))
        except (OSError, ValueError, IndexError, ProcessLookupError):
            continue
    return ticks, rows


class MiniGraph(Gtk.DrawingArea):
    def __init__(self):
        super().__init__()
        self.values = []
        self.set_size_request(120, 34)
        self.connect("draw", self.draw_graph)

    def push(self, value):
        self.values.append(max(0.0, min(100.0, value)))
        del self.values[:-36]
        self.queue_draw()

    def draw_graph(self, widget, cr):
        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        cr.set_source_rgb(0.22, 0.24, 0.27)
        cr.set_line_width(1)
        cr.move_to(0, height * .5)
        cr.line_to(width, height * .5)
        cr.stroke()
        if len(self.values) < 2:
            return False
        cr.set_source_rgb(0.34, 0.60, 0.84)
        cr.set_line_width(1.7)
        step = width / max(1, len(self.values) - 1)
        for index, value in enumerate(self.values):
            x = index * step
            y = height - (value / 100.0 * (height - 4)) - 2
            if index == 0:
                cr.move_to(x, y)
            else:
                cr.line_to(x, y)
        cr.stroke()
        return False


class MetricCard(Gtk.Box):
    def __init__(self, title):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=4)
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
        self.pack_start(self.detail, False, False, 0)


class ForjaMonitor(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="br.forja.monitor")
        self.prev_cpu = cpu_total()
        self.prev_net = network_total()
        self.prev_time = time.monotonic()
        self.last_cpu = 0.0
        self.last_process_ticks = {}
        self.last_process_time = time.monotonic()
        self.process_rows = {}
        self.last_process_refresh = 0.0

    def do_activate(self):
        self.win = Gtk.ApplicationWindow(application=self)
        self.win.set_title("Forja Monitor")
        self.win.set_default_size(1240, 760)
        self.win.set_size_request(980, 620)
        self.apply_css()

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        outer.get_style_context().add_class("root")
        self.win.add(outer)

        topbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        topbar.set_margin_start(22)
        topbar.set_margin_end(22)
        topbar.set_margin_top(16)
        topbar.set_margin_bottom(14)
        logo = Gtk.Image.new_from_file(os.path.join(APP_DIR, "forja-flame.svg"))
        logo.set_pixel_size(28)
        topbar.pack_start(logo, False, False, 0)
        brand = Gtk.Label()
        brand.set_markup('<span weight="bold" foreground="#e7e9ec" size="large">FORJA</span><span foreground="#5598d6" weight="bold" size="large"> OS</span>')
        topbar.pack_start(brand, False, False, 0)
        topbar.pack_end(Gtk.Label(label="MONITOR DO SISTEMA", xalign=1), False, False, 0)
        outer.pack_start(topbar, False, False, 0)

        divider = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        outer.pack_start(divider, False, False, 0)

        body = Gtk.Paned.new(Gtk.Orientation.HORIZONTAL)
        body.set_wide_handle(False)
        body.set_position(790)
        body.set_margin_start(16)
        body.set_margin_end(16)
        body.set_margin_top(16)
        body.set_margin_bottom(16)
        outer.pack_start(body, True, True, 0)

        self.monitor_panel = self.make_monitor_panel()
        self.info_panel = self.make_info_panel()
        body.pack1(self.monitor_panel, True, False)
        body.pack2(self.info_panel, False, False)

        self.win.show_all()
        self.refresh_metrics()
        GLib.timeout_add_seconds(2, self.refresh_metrics)
        GLib.timeout_add_seconds(PROCESS_REFRESH_SECONDS, self.refresh_processes)

    def apply_css(self):
        css = b"""
        window, .root { background: #17191c; color: #e7e9ec; }
        .panel { background: #202328; border: 1px solid #343a42; border-radius: 9px; }
        .panel-title { color: #f0f2f5; font-size: 15pt; font-weight: 600; }
        .section-title { color: #d9dde2; font-size: 10pt; font-weight: 600; }
        .muted { color: #969da7; font-size: 9pt; }
        .metric-card { background: #272c32; border: 1px solid #383f48; border-radius: 7px; padding: 9px; }
        .card-title { color: #aeb6c0; font-size: 9pt; font-weight: 600; }
        .metric-value { color: #f0f2f5; font-size: 15pt; font-weight: 600; }
        .info-row { border-bottom: 1px solid #343a42; padding: 7px 2px; }
        .info-key { color: #969da7; font-size: 9pt; }
        .info-value { color: #e3e6ea; font-size: 9pt; }
        treeview { background: #202328; color: #e2e5e9; }
        treeview.view { background: #202328; color: #e2e5e9; }
        treeview.view:selected { background: #30475e; color: #ffffff; }
        treeview header button { background: #292e35; color: #bfc6cf; border: 0; padding: 7px; }
        scrolledwindow { border: 1px solid #383f48; border-radius: 6px; }
        paned > separator { background: #343a42; min-width: 8px; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def make_monitor_panel(self):
        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        panel.get_style_context().add_class("panel")
        panel.set_margin_end(8)
        panel.set_margin_top(2)
        panel.set_margin_bottom(2)
        panel.set_margin_start(2)
        panel.set_border_width(14)

        title = Gtk.Label(label="Monitor do Sistema", xalign=0)
        title.get_style_context().add_class("panel-title")
        panel.pack_start(title, False, False, 0)
        subtitle = Gtk.Label(label="Atividade e processos em execução", xalign=0)
        subtitle.get_style_context().add_class("muted")
        panel.pack_start(subtitle, False, False, 0)

        metrics = Gtk.Grid()
        metrics.set_column_spacing(8)
        metrics.set_row_spacing(8)
        metrics.set_column_homogeneous(True)
        self.cpu = MetricCard("Processador")
        self.memory = MetricCard("Memória")
        self.disk = MetricCard("Armazenamento")
        self.net = MetricCard("Rede")
        metrics.attach(self.cpu, 0, 0, 1, 1)
        metrics.attach(self.memory, 1, 0, 1, 1)
        metrics.attach(self.disk, 0, 1, 1, 1)
        metrics.attach(self.net, 1, 1, 1, 1)
        panel.pack_start(metrics, False, False, 0)

        process_header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        process_title = Gtk.Label(label="Processos", xalign=0)
        process_title.get_style_context().add_class("section-title")
        process_header.pack_start(process_title, True, True, 0)
        self.process_count = Gtk.Label(label="Detectando…", xalign=1)
        self.process_count.get_style_context().add_class("muted")
        process_header.pack_end(self.process_count, False, False, 0)
        panel.pack_start(process_header, False, False, 0)

        self.process_store = Gtk.ListStore(str, int, str, str, str, int)
        self.process_view = Gtk.TreeView(model=self.process_store)
        self.process_view.set_headers_visible(True)
        self.process_view.set_enable_search(True)
        self.process_view.set_search_column(0)
        self.process_view.get_selection().set_mode(Gtk.SelectionMode.SINGLE)
        columns = [
            ("Nome", 0, 1),
            ("PID", 1, 0),
            ("CPU", 2, 0),
            ("Memória", 3, 0),
            ("Estado", 4, 0),
        ]
        for heading, index, expand in columns:
            renderer = Gtk.CellRendererText()
            renderer.set_padding(7, 5)
            if index == 0:
                renderer.set_property("ellipsize", Pango.EllipsizeMode.END)
            column = Gtk.TreeViewColumn(heading, renderer, text=index)
            column.set_resizable(True)
            column.set_expand(bool(expand))
            if index in (1, 2, 3):
                column.set_alignment(1.0)
                renderer.set_property("xalign", 1.0)
            self.process_view.append_column(column)
        self.process_view.set_tooltip_text("Lista dos processos que o sistema permite ler em /proc. Clique no cabeçalho para ordenar.")
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.set_min_content_height(180)
        scroll.add(self.process_view)
        panel.pack_start(scroll, True, True, 0)

        self.temp_label = Gtk.Label(label="Temperatura: verificando sensores…", xalign=0)
        self.temp_label.get_style_context().add_class("muted")
        panel.pack_start(self.temp_label, False, False, 0)
        return panel

    def make_info_panel(self):
        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        panel.get_style_context().add_class("panel")
        panel.set_margin_start(8)
        panel.set_margin_top(2)
        panel.set_margin_bottom(2)
        panel.set_margin_end(2)
        panel.set_border_width(14)

        heading = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=7)
        title = Gtk.Label(label="Informações do Forja", xalign=0)
        title.get_style_context().add_class("panel-title")
        heading.pack_start(title, True, True, 0)
        dot = Gtk.Label()
        dot.set_markup('<span foreground="#5598d6" size="large">●</span>')
        dot.set_tooltip_text("Informações da Forja OS")
        heading.pack_end(dot, False, False, 0)
        panel.pack_start(heading, False, False, 0)
        desc = Gtk.Label(label="Computador e instalação", xalign=0)
        desc.get_style_context().add_class("muted")
        panel.pack_start(desc, False, False, 0)

        self.info_grid = Gtk.Grid()
        self.info_grid.set_column_spacing(10)
        self.info_grid.set_row_spacing(0)
        self.info_grid.set_column_homogeneous(False)
        self.info_grid.set_hexpand(True)
        values = self.system_information()
        for row, (key, value) in enumerate(values):
            key_label = Gtk.Label(label=key, xalign=0, yalign=0)
            key_label.get_style_context().add_class("info-key")
            value_label = Gtk.Label(label=value or "Não disponível", xalign=1, yalign=0)
            value_label.set_selectable(True)
            value_label.set_line_wrap(True)
            value_label.set_max_width_chars(26)
            value_label.set_ellipsize(Pango.EllipsizeMode.END)
            value_label.get_style_context().add_class("info-value")
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            row_box.get_style_context().add_class("info-row")
            row_box.pack_start(key_label, True, True, 0)
            row_box.pack_end(value_label, False, False, 0)
            self.info_grid.attach(row_box, 0, row, 1, 1)
        panel.pack_start(self.info_grid, False, False, 0)

        note = Gtk.Label(label="Dados lidos diretamente do sistema. Sensores dependem do suporte do hardware e dos drivers.", xalign=0)
        note.set_line_wrap(True)
        note.get_style_context().add_class("muted")
        panel.pack_end(note, False, False, 0)
        return panel

    def system_information(self):
        cpu_name = ""
        for line in read_text("/proc/cpuinfo").splitlines():
            if line.lower().startswith(("model name", "hardware")):
                cpu_name = line.split(":", 1)[-1].strip()
                break
        used, total = meminfo()
        ram = f"{total / 1024**3:.1f} GB" if total else ""
        gpu = self.gpu_name()
        disk = shutil.disk_usage("/")
        disk_text = f"{disk.total / 1024**3:.1f} GB"
        screen = Gdk.Screen.get_default()
        resolution = f"{screen.get_width()} × {screen.get_height()}" if screen else ""
        os_info = {}
        for line in read_text("/etc/os-release").splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                os_info[key] = value.strip().strip('"')
        install_date = self.installation_date()
        board = read_text("/sys/devices/virtual/dmi/id/board_name").strip()
        return [
            ("Distribuição", os_info.get("PRETTY_NAME", "Forja OS")),
            ("Ambiente", "MATE"),
            ("Kernel", platform.release()),
            ("Arquitetura", platform.machine()),
            ("Processador", cpu_name),
            ("Gráficos", gpu),
            ("Memória RAM", ram),
            ("Armazenamento", disk_text),
            ("Resolução", resolution),
            ("Placa-mãe", board),
            ("Instalada em", install_date),
        ]

    def gpu_name(self):
        names = []
        for vendor_path in glob.glob("/sys/class/drm/card[0-9]*/device/vendor"):
            base = os.path.dirname(vendor_path)
            vendor = read_text(vendor_path).strip().lower()
            device = read_text(os.path.join(base, "device")).strip()
            vendor_name = {
                "0x8086": "Intel",
                "0x1002": "AMD",
                "0x10de": "NVIDIA",
            }.get(vendor, vendor or "GPU")
            label = f"{vendor_name} ({device})" if device else vendor_name
            if label not in names:
                names.append(label)
        return ", ".join(names) if names else "Não detectada"

    def installation_date(self):
        try:
            import json
            from datetime import datetime
            payload = json.loads(read_text(INSTALL_INFO, "{}"))
            stamp = payload.get("installed_at")
            if not stamp:
                return "Registro não encontrado"
            installed = datetime.fromisoformat(stamp.replace("Z", "+00:00"))
            if installed.tzinfo is None:
                return "Registro sem fuso horário"
            return installed.astimezone().strftime("%d/%m/%Y às %H:%M:%S")
        except (ValueError, TypeError, OSError):
            return "Registro indisponível"

    def refresh_metrics(self):
        if not self.win.get_visible():
            return True
        now = time.monotonic()
        cpu = cpu_total()
        if cpu and self.prev_cpu:
            total_delta = cpu[0] - self.prev_cpu[0]
            idle_delta = cpu[1] - self.prev_cpu[1]
            if total_delta > 0:
                self.last_cpu = max(0, min(100, (1 - idle_delta / total_delta) * 100))
        self.prev_cpu = cpu
        used, total = meminfo()
        mem_pct = used * 100 / total if total else 0
        disk = shutil.disk_usage("/")
        disk_pct = disk.used * 100 / disk.total if disk.total else 0
        net = network_total()
        elapsed = max(.1, now - self.prev_time)
        rate = max(0, net - self.prev_net) / elapsed
        self.prev_net, self.prev_time = net, now

        self.cpu.value.set_text(f"{self.last_cpu:.0f}%")
        self.cpu.detail.set_text("Uso total")
        self.cpu.graph.push(self.last_cpu)
        self.memory.value.set_text(f"{mem_pct:.0f}%")
        self.memory.detail.set_text(f"{used / 1024**3:.1f} de {total / 1024**3:.1f} GB")
        self.memory.graph.push(mem_pct)
        self.disk.value.set_text(f"{disk_pct:.0f}%")
        self.disk.detail.set_text(f"{disk.used / 1024**3:.1f} de {disk.total / 1024**3:.1f} GB")
        self.disk.graph.push(disk_pct)
        self.net.value.set_text(f"{rate / 1024:.0f} KB/s")
        self.net.detail.set_text("Entrada + saída")
        self.net.graph.push(min(100, rate / (1024 * 1024) * 100))
        sensor, temperature = temp_reading()
        if temperature is None:
            self.temp_label.set_text("Temperatura: sensor não disponível")
        else:
            self.temp_label.set_text(f"Temperatura ({sensor}): {temperature:.0f} °C")
        return True

    def refresh_processes(self):
        if not self.win.get_visible():
            return True
        now = time.monotonic()
        new_ticks, rows = process_snapshot()
        elapsed = max(0.1, now - self.last_process_time)
        total_memory = meminfo()[1]
        updated = []
        for pid, name, state, ticks, rss, clock_ticks in rows:
            previous = self.last_process_ticks.get(pid)
            cpu_pct = 0.0
            if previous is not None and ticks >= previous:
                cpu_pct = (ticks - previous) / clock_ticks / elapsed * 100.0
            memory_pct = (rss * 100.0 / total_memory) if total_memory else 0.0
            updated.append((name, pid, cpu_pct, rss, state, memory_pct))
        self.last_process_ticks = new_ticks
        self.last_process_time = now
        updated.sort(key=lambda item: item[2], reverse=True)

        self.process_store.clear()
        for name, pid, cpu_pct, rss, state, memory_pct in updated:
            self.process_store.append((
                name, pid, f"{cpu_pct:.1f}%", f"{rss / 1024**2:.1f} MB",
                state, int(min(100, max(0, cpu_pct * 10)))
            ))
        self.process_count.set_text(f"{len(updated)} processos")
        return True


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        if not Gtk.init_check([]):
            raise SystemExit("GTK não conseguiu inicializar o display de teste.")
        app = ForjaMonitor()
        app.register(None)
        app.do_activate()
        app.refresh_metrics()
        app.refresh_processes()
        assert app.cpu.value.get_text() != "--"
        assert app.memory.value.get_text() != "--"
        assert app.disk.value.get_text() != "--"
        assert app.net.value.get_text() != "--"
        assert len(app.process_store) >= 1
        app.win.destroy()
        app.quit()
        print("Forja Monitor GTK smoke test: OK")
    else:
        ForjaMonitor().run(None)
