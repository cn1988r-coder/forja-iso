#!/usr/bin/env python3
"""Forja Monitor: monitor leve para MATE, sem dependência do GNOME ou psutil."""
import os
import glob
import time
import shutil
import socket
import platform
import subprocess

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk, cairo

APP_DIR = "/usr/share/forja-monitor"
INSTALL_INFO = "/var/lib/forja-os/install-info.json"
BG = "#171717"
PANEL = "#222222"
CARD = "#292929"
TEXT = "#e5e5e5"
MUTED = "#a0a0a0"
LINE = "#555555"
ACCENT = "#bdbdbd"


def read_text(path, default=""):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
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
    used = max(0, total - available)
    return used, total


def cpu_total():
    line = read_text("/proc/stat").splitlines()
    if not line:
        return None
    parts = line[0].split()[1:]
    try:
        nums = [int(x) for x in parts]
        idle = nums[3] + (nums[4] if len(nums) > 4 else 0)
        return sum(nums), idle
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
        p = data.split()
        try:
            total += int(p[0]) + int(p[8])
        except (ValueError, IndexError):
            pass
    return total


def temp_celsius():
    for path in glob.glob("/sys/class/hwmon/hwmon*/temp*_input"):
        raw = read_text(path).strip()
        try:
            value = int(raw) / 1000
            if -10 < value < 150:
                return value
        except ValueError:
            pass
    return None


class MiniGraph(Gtk.DrawingArea):
    def __init__(self):
        super().__init__()
        self.values = []
        self.set_size_request(240, 58)
        self.connect("draw", self.draw_graph)

    def push(self, value):
        self.values.append(max(0.0, min(100.0, value)))
        self.values = self.values[-48:]
        self.queue_draw()

    def draw_graph(self, widget, cr):
        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        cr.set_source_rgb(0.24, 0.24, 0.24)
        cr.set_line_width(1)
        for y in (height * .33, height * .66):
            cr.move_to(0, y)
            cr.line_to(width, y)
        cr.stroke()
        if len(self.values) < 2:
            return False
        cr.set_source_rgb(.78, .78, .78)
        cr.set_line_width(2)
        step = width / max(47, len(self.values) - 1)
        for i, value in enumerate(self.values):
            x = i * step
            y = height - (value / 100.0 * (height - 5)) - 2
            if i == 0:
                cr.move_to(x, y)
            else:
                cr.line_to(x, y)
        cr.stroke()
        return False


class MetricCard(Gtk.Box):
    def __init__(self, title, subtitle=""):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=7)
        self.get_style_context().add_class("metric-card")
        head = Gtk.Box(spacing=6)
        name = Gtk.Label(label=title, xalign=0)
        name.get_style_context().add_class("card-title")
        head.pack_start(name, True, True, 0)
        self.value = Gtk.Label(label="--", xalign=1)
        self.value.get_style_context().add_class("metric-value")
        head.pack_end(self.value, False, False, 0)
        self.pack_start(head, False, False, 0)
        self.graph = MiniGraph()
        self.pack_start(self.graph, False, False, 0)
        self.detail = Gtk.Label(label=subtitle, xalign=0)
        self.detail.get_style_context().add_class("muted")
        self.pack_start(self.detail, False, False, 0)


class ForjaMonitor(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="br.forja.monitor")
        self.prev_cpu = cpu_total()
        self.prev_net = network_total()
        self.prev_time = time.monotonic()
        self.last_cpu = 0.0
        self.last_net = 0.0

    def do_activate(self):
        self.win = Gtk.ApplicationWindow(application=self)
        self.win.set_title("Forja Monitor")
        self.win.set_default_size(900, 590)
        self.win.set_size_request(720, 480)
        self.apply_css()

        root = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        root.get_style_context().add_class("root")
        self.win.add(root)

        side = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        side.set_size_request(190, -1)
        side.get_style_context().add_class("sidebar")
        root.pack_start(side, False, False, 0)

        brand = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        brand.set_margin_top(22)
        brand.set_margin_start(18)
        brand.set_margin_bottom(22)
        flame = Gtk.Image.new_from_file(os.path.join(APP_DIR, "forja-flame.svg"))
        flame.set_pixel_size(34)
        brand.pack_start(flame, False, False, 0)
        word = Gtk.Label()
        word.set_markup('<span foreground="#bdbdbd" weight="bold" size="large">FORJA OS</span>')
        word.set_xalign(0)
        brand.pack_start(word, False, False, 0)
        side.pack_start(brand, False, False, 0)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.NONE)
        self.stack.set_transition_duration(0)
        self.stack.set_hexpand(True)
        self.stack.set_vexpand(True)
        self.monitor_page = self.make_monitor_page()
        self.info_page = Gtk.Box()
        self.info_loaded = False
        self.stack.add_named(self.monitor_page, "monitor")
        self.stack.add_named(self.info_page, "info")
        root.pack_start(self.stack, True, True, 0)

        self.nav_buttons = []
        for label, page in (("Monitor do Sistema", "monitor"), ("Informações", "info")):
            button = Gtk.ToggleButton(label=label)
            button.set_relief(Gtk.ReliefStyle.NONE)
            button.set_halign(Gtk.Align.FILL)
            button.set_margin_start(10)
            button.set_margin_end(10)
            button.connect("clicked", self.change_page, page)
            side.pack_start(button, False, False, 0)
            self.nav_buttons.append((button, page))
        self.nav_buttons[0][0].set_active(True)

        self.win.show_all()
        GLib.timeout_add_seconds(2, self.refresh_metrics)

    def apply_css(self):
        css = b"""
        window, .root { background: #171717; color: #e5e5e5; }
        .sidebar { background: #202020; border-right: 1px solid #393939; }
        .metric-card { background: #292929; border: 1px solid #3a3a3a; border-radius: 9px; padding: 14px; }
        .card-title { color: #bdbdbd; font-size: 10pt; font-weight: 600; }
        .metric-value { color: #f0f0f0; font-size: 17pt; font-weight: 600; }
        .muted { color: #9b9b9b; font-size: 9pt; }
        .page-title { color: #eeeeee; font-size: 19pt; font-weight: 600; }
        .nav-title { color: #eeeeee; font-size: 10pt; }
        button { color: #d0d0d0; background: transparent; border: 0; border-radius: 6px; padding: 10px; }
        button:checked { background: #383838; color: #ffffff; }
        .info-card { background: #252525; border: 1px solid #393939; border-radius: 8px; padding: 12px; }
        .info-key { color: #9e9e9e; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
                                                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def page_shell(self, title, description):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_margin_top(24)
        box.set_margin_bottom(22)
        box.set_margin_start(26)
        box.set_margin_end(26)
        heading = Gtk.Label(label=title, xalign=0)
        heading.get_style_context().add_class("page-title")
        box.pack_start(heading, False, False, 0)
        if description:
            desc = Gtk.Label(label=description, xalign=0)
            desc.get_style_context().add_class("muted")
            box.pack_start(desc, False, False, 0)
        return box

    def make_monitor_page(self):
        page = self.page_shell("Monitor do Sistema", "Uso de recursos em tempo real")
        grid = Gtk.Grid()
        grid.set_row_spacing(12)
        grid.set_column_spacing(12)
        grid.set_column_homogeneous(True)
        self.cpu = MetricCard("Processador")
        self.memory = MetricCard("Memória")
        self.disk = MetricCard("Armazenamento", "Uso da partição principal")
        self.net = MetricCard("Rede", "Tráfego combinado de entrada e saída")
        grid.attach(self.cpu, 0, 0, 1, 1)
        grid.attach(self.memory, 1, 0, 1, 1)
        grid.attach(self.disk, 0, 1, 1, 1)
        grid.attach(self.net, 1, 1, 1, 1)
        page.pack_start(grid, True, True, 0)
        self.temp_label = Gtk.Label(label="Temperatura: verificando sensores…", xalign=0)
        self.temp_label.get_style_context().add_class("muted")
        page.pack_start(self.temp_label, False, False, 0)
        return page

    def info_row(self, grid, row, key, value):
        k = Gtk.Label(label=key, xalign=0)
        k.get_style_context().add_class("info-key")
        v = Gtk.Label(label=value or "Não disponível", xalign=1)
        v.set_selectable(True)
        grid.attach(k, 0, row, 1, 1)
        grid.attach(v, 1, row, 1, 1)

    def command(self, args):
        try:
            return subprocess.check_output(args, stderr=subprocess.DEVNULL,
                                           text=True, timeout=1).strip()
        except (OSError, subprocess.SubprocessError):
            return ""

    def make_info_page(self):
        page = self.page_shell("Informações do Sistema", "Identificação do computador e da instalação")
        grid = Gtk.Grid()
        grid.set_row_spacing(12)
        grid.set_column_spacing(30)
        grid.get_style_context().add_class("info-card")
        cpu = ""
        for line in read_text("/proc/cpuinfo").splitlines():
            if line.lower().startswith("model name"):
                cpu = line.split(":", 1)[-1].strip()
                break
        used, total = meminfo()
        ram = f"{total // (1024**3)} GB" if total else "Não disponível"
        gpu = ""
        for vendor in glob.glob("/sys/class/drm/card[0-9]*/device/vendor"):
            vendor_id = read_text(vendor).strip()
            gpu = {"0x8086": "Intel", "0x1002": "AMD", "0x10de": "NVIDIA"}.get(vendor_id, vendor_id)
            break
        root = shutil.disk_usage("/")
        disk = f"{root.total // (1024**3)} GB"
        resolution = self.command(["sh", "-c", "xrandr 2>/dev/null | awk '/\*/ {print $1; exit}'"])
        install_date = "Data de instalação indisponível"
        try:
            import json
            data = json.loads(read_text(INSTALL_INFO, "{}"))
            stamp = data.get("installed_at")
            if stamp:
                from datetime import datetime
                install_date = datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone().strftime("%d/%m/%Y")
        except (ValueError, TypeError, OSError):
            pass
        rows = [
            ("Sistema", "Forja OS"),
            ("Base", "EndeavourOS / Arch Linux"),
            ("Ambiente", "MATE"),
            ("Kernel", platform.release()),
            ("Arquitetura", platform.machine()),
            ("Processador", cpu),
            ("Gráficos", gpu),
            ("Memória RAM", ram),
            ("Armazenamento total", disk),
            ("Resolução", resolution),
            ("Placa-mãe", self.command(["sh", "-c", "cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null"])),
            ("BIOS / UEFI", self.command(["sh", "-c", "cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null"])),
            ("Instalação", install_date),
        ]
        for i, (key, value) in enumerate(rows):
            self.info_row(grid, i, key, value)
        page.pack_start(grid, False, False, 0)
        return page

    def change_page(self, button, page):
        if not button.get_active():
            return
        self.stack.set_visible_child_name(page)
        for other, name in self.nav_buttons:
            if other is not button:
                other.set_active(name == page)
        if page == "info" and not self.info_loaded:
            self.stack.remove(self.info_page)
            self.info_page = self.make_info_page()
            self.stack.add_named(self.info_page, "info")
            self.info_loaded = True
            self.stack.set_visible_child_name("info")
            self.info_page.show_all()

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
        self.cpu.detail.set_text("Uso total do processador")
        self.cpu.graph.push(self.last_cpu)
        self.memory.value.set_text(f"{mem_pct:.0f}%")
        self.memory.detail.set_text(f"{used / 1024**3:.1f} GB de {total / 1024**3:.1f} GB")
        self.memory.graph.push(mem_pct)
        self.disk.value.set_text(f"{disk_pct:.0f}%")
        self.disk.detail.set_text(f"{disk.used / 1024**3:.1f} GB usados de {disk.total / 1024**3:.1f} GB")
        self.disk.graph.push(disk_pct)
        self.net.value.set_text(f"{rate / 1024:.0f} KB/s")
        self.net.detail.set_text("Recebimento + envio")
        self.net.graph.push(min(100, rate / (1024 * 1024) * 100))
        temp = temp_celsius()
        self.temp_label.set_text(f"Temperatura: {temp:.0f} °C" if temp is not None
                                 else "Temperatura: não disponível pelo driver/sensor")
        return True


if __name__ == "__main__":
    ForjaMonitor().run(None)
