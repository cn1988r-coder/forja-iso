#!/usr/bin/env bash
set -Eeuo pipefail
# Run as the desktop user inside an XFCE session, never with sudo.
command -v xfconf-query >/dev/null 2>&1 || exit 0
command -v xfce4-panel >/dev/null 2>&1 || exit 0

xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/position -n -t string -s 'p=8;x=0;y=0'
xfconf-query -c xfce4-panel -p /panels/panel-1/length -n -t int -s 100
xfconf-query -c xfce4-panel -p /panels/panel-1/length-adjust -n -t bool -s false
xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t int -s 42
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -n -t int -s 0
xfconf-query -c xfce4-panel -p /panels/panel-1/position-locked -n -t bool -s true
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n -a -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 -t int -s 5

xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s whiskermenu
xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s tasklist
xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s systray
xfconf-query -c xfce4-panel -p /plugins/plugin-4 -n -t string -s clock
xfconf-query -c xfce4-panel -p /plugins/plugin-5 -n -t string -s showdesktop
xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-title -n -t string -s Menu 2>/dev/null || true
xfce4-panel --restart
