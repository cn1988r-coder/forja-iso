#!/usr/bin/env python3
"""Forja Luz Noturna: small MATE/X11 colour-temperature controller.

This is an experimental XRandR backend, not GNOME's Mutter implementation.
It changes the display gamma ramp directly and therefore requires an X11
session and an XRandR driver that accepts gamma changes.
"""
import argparse
import json
import math
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

APP_DIR = Path.home() / ".config" / "forja"
CONFIG = APP_DIR / "luz-noturna.json"
DEFAULTS = {
    "enabled": False,
    "automatic": True,
    "temperature": 4000,
    "day_temperature": 6500,
    "start": "20:00",
    "end": "07:00"
}


def load_config():
    try:
        data = json.loads(CONFIG.read_text(encoding="utf-8"))
        return {**DEFAULTS, **data}
    except (OSError, ValueError):
        return DEFAULTS.copy()


def save_config(cfg):
    APP_DIR.mkdir(parents=True, exist_ok=True)
    temp = CONFIG.with_suffix(".tmp")
    temp.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")
    temp.replace(CONFIG)


def rgb_for_temperature(kelvin):
    """Return normalized red, green and blue gamma multipliers."""
    t = max(1000, min(10000, int(kelvin))) / 100.0
    if t <= 66:
        red = 255.0
        green = 99.4708025861 * math.log(t) - 161.1195681661
        blue = 0.0 if t <= 19 else 138.5177312231 * math.log(t - 10) - 305.0447927307
    else:
        red = 329.698727446 * ((t - 60) ** -0.1332047592)
        green = 288.1221695283 * ((t - 60) ** -0.0755148492)
        blue = 255.0
    channels = [max(0.0, min(255.0, c)) / 255.0 for c in (red, green, blue)]
    peak = max(channels) or 1.0
    return tuple(round(c / peak, 4) for c in channels)


def connected_outputs():
    result = subprocess.run(["xrandr", "--query"], text=True, capture_output=True, check=True)
    return re.findall(r"^([A-Za-z0-9_.-]+) connected(?: primary)?(?: |$)", result.stdout, re.M)


def apply_temperature(kelvin):
    outputs = connected_outputs()
    if not outputs:
        raise RuntimeError("Nenhuma tela conectada foi encontrada pelo XRandR.")
    r, g, b = rgb_for_temperature(kelvin)
    gamma = f"{r}:{g}:{b}"
    for output in outputs:
        subprocess.run(["xrandr", "--output", output, "--gamma", gamma],
                       check=True, text=True, capture_output=True)


def reset_temperature():
    for output in connected_outputs():
        subprocess.run(["xrandr", "--output", output, "--gamma", "1:1:1"],
                       check=True, text=True, capture_output=True)


def is_night_now(cfg):
    now = datetime.now().strftime("%H:%M")
    start, end = cfg["start"], cfg["end"]
    return (start <= now < end) if start < end else (now >= start or now < end)


class ForjaNightLight:
    def __init__(self, background=False):
        self.cfg = load_config()
        self.window = None
        self.background = background
        self.icon = Gtk.StatusIcon.new_from_icon_name("weather-clear-night")
        self.icon.set_title("Forja Luz Noturna")
        self.icon.set_tooltip_text("Forja Luz Noturna")
        self.icon.connect("activate", self.show_window)
        self.icon.connect("popup-menu", self.popup_menu)
        if not background:
            self.show_window()
        self.refresh()
        GLib.timeout_add_seconds(30, self.refresh)

    def notify_error(self, message):
        if self.window:
            self.status.set_text(message)
        else:
            print("Forja Luz Noturna:", message, file=sys.stderr)

    def refresh(self):
        try:
            active = is_night_now(self.cfg) if self.cfg["automatic"] else self.cfg["enabled"]
            if active:
                apply_temperature(self.cfg["temperature"])
                self.icon.set_from_icon_name("weather-clear-night")
                self.icon.set_tooltip_text(f"Forja Luz Noturna: {self.cfg['temperature']} K")
            else:
                reset_temperature()
                self.icon.set_from_icon_name("weather-clear")
                self.icon.set_tooltip_text("Forja Luz Noturna: desligada")
            if self.window:
                self.status.set_text("Filtro noturno ativo" if active else "Cores normais")
        except (OSError, subprocess.SubprocessError, RuntimeError) as exc:
            self.notify_error(f"Não foi possível aplicar o filtro: {exc}")
        return GLib.SOURCE_CONTINUE

    def save_and_refresh(self, *_):
        self.cfg["enabled"] = self.toggle.get_active()
        self.cfg["automatic"] = self.auto.get_active()
        self.cfg["temperature"] = int(self.scale.get_value())
        self.cfg["start"] = self.start.get_text()
        self.cfg["end"] = self.end.get_text()
        save_config(self.cfg)
        self.refresh()

    def show_window(self, *_):
        if self.window:
            self.window.show_all()
            self.window.present()
            return
        self.window = Gtk.Window(title="Forja Luz Noturna")
        self.window.set_border_width(18)
        self.window.set_default_size(360, 250)
        self.window.set_resizable(False)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.window.add(box)
        title = Gtk.Label()
        title.set_markup("<b>FORJA LUZ NOTURNA</b>")
        box.pack_start(title, False, False, 0)
        self.toggle = Gtk.Switch()
        self.toggle.set_active(bool(self.cfg["enabled"]))
        row = Gtk.Box(spacing=10)
        row.pack_start(Gtk.Label(label="Ativar manualmente"), True, True, 0)
        row.pack_end(self.toggle, False, False, 0)
        box.pack_start(row, False, False, 0)
        self.auto = Gtk.CheckButton(label="Automático por horário")
        self.auto.set_active(bool(self.cfg["automatic"]))
        box.pack_start(self.auto, False, False, 0)
        box.pack_start(Gtk.Label(label="Temperatura noturna (Kelvin)"), False, False, 0)
        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 1800, 6500, 100)
        self.scale.set_value(int(self.cfg["temperature"]))
        self.scale.set_digits(0)
        box.pack_start(self.scale, False, False, 0)
        times = Gtk.Box(spacing=8)
        self.start = Gtk.Entry()
        self.start.set_placeholder_text("20:00")
        self.start.set_text(self.cfg["start"])
        self.end = Gtk.Entry()
        self.end.set_placeholder_text("07:00")
        self.end.set_text(self.cfg["end"])
        times.pack_start(Gtk.Label(label="Início"), False, False, 0)
        times.pack_start(self.start, True, True, 0)
        times.pack_start(Gtk.Label(label="Fim"), False, False, 0)
        times.pack_start(self.end, True, True, 0)
        box.pack_start(times, False, False, 0)
        self.status = Gtk.Label(label="Pronto")
        box.pack_start(self.status, False, False, 0)
        save = Gtk.Button(label="Aplicar")
        save.connect("clicked", self.save_and_refresh)
        box.pack_end(save, False, False, 0)
        self.toggle.connect("notify::active", self.save_and_refresh)
        self.auto.connect("toggled", self.save_and_refresh)
        self.scale.connect("value-changed", self.save_and_refresh)
        self.start.connect("changed", self.save_and_refresh)
        self.end.connect("changed", self.save_and_refresh)
        self.window.connect("delete-event", self.hide_window)
        self.window.show_all()

    def hide_window(self, *_):
        self.window.hide()
        return True

    def popup_menu(self, icon, button, activate_time):
        menu = Gtk.Menu()
        open_item = Gtk.MenuItem(label="Abrir configurações")
        open_item.connect("activate", self.show_window)
        menu.append(open_item)
        toggle_item = Gtk.MenuItem(label="Desativar filtro")
        toggle_item.connect("activate", lambda *_: self.force_off())
        menu.append(toggle_item)
        quit_item = Gtk.MenuItem(label="Sair")
        quit_item.connect("activate", self.quit)
        menu.append(quit_item)
        menu.show_all()
        menu.popup(None, None, Gtk.StatusIcon.position_menu, icon, button, activate_time)

    def force_off(self):
        self.cfg["enabled"] = False
        self.cfg["automatic"] = False
        save_config(self.cfg)
        self.refresh()

    def quit(self, *_):
        try:
            reset_temperature()
        except Exception:
            pass
        Gtk.main_quit()


def main():
    parser = argparse.ArgumentParser(description="Controle experimental de luz noturna para MATE/X11")
    parser.add_argument("--background", action="store_true", help="iniciar minimizado na área de notificação")
    parser.add_argument("--self-test", action="store_true", help="validar cálculo de temperatura sem alterar a tela")
    args = parser.parse_args()
    if args.self_test:
        for temp in (1800, 2700, 4000, 6500):
            values = rgb_for_temperature(temp)
            assert all(0.0 <= v <= 1.0 for v in values)
            print(f"{temp} K -> {values}")
        return 0
    if not os.environ.get("DISPLAY"):
        print("Forja Luz Noturna requer uma sessão gráfica X11.", file=sys.stderr)
        return 2
    app = ForjaNightLight(args.background)
    Gtk.main()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
