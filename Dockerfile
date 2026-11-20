FROM archlinux:latest

ENV LANG=pt_BR.UTF-8
ENV LC_ALL=pt_BR.UTF-8

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed bash git python shellcheck base-devel gtk4 meson ninja archiso && \
    pacman -Scc --noconfirm

WORKDIR /workspace
CMD ["bash", "scripts/validate-build.sh"]
