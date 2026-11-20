FROM archlinux:latest

ENV LANG=pt_BR.UTF-8
ENV LC_ALL=pt_BR.UTF-8

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed bash git shellcheck base-devel pkgconf gtk4 meson ninja archiso && \
    pacman -Scc --noconfirm

WORKDIR /workspace
CMD ["bash", "-lc", "meson setup /tmp/venom-installer-build installer && meson compile -C /tmp/venom-installer-build && shellcheck scripts/*.sh build/airootfs/usr/local/bin/venom-mate-first-login && bash -n build/airootfs/usr/local/bin/venom-mate-first-login && bash scripts/validate-scope.sh"]
