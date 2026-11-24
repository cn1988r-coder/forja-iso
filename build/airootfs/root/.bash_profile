# VENOM OS live session bootstrap: start the graphical XFCE session once on tty1.
if [[ "$(tty 2>/dev/null || true)" == "/dev/tty1" && -z "${VENOM_LIVE_SETUP_DISPATCHED:-}" ]]; then
  export VENOM_LIVE_SETUP_DISPATCHED=1
  systemctl start venom-live-setup.service
fi
