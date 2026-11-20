FROM archlinux:latest

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
      archiso base-devel curl git imagemagick sudo squashfs-tools

ARG BUILD_UID=1000
ARG BUILD_GID=1000

RUN getent group "$BUILD_GID" >/dev/null || groupadd --gid "$BUILD_GID" builder; \
    useradd --create-home --uid "$BUILD_UID" --gid "$BUILD_GID" --groups wheel builder && \
    printf 'builder ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

WORKDIR /workspace
USER builder
ENTRYPOINT ["bash", "scripts/build-venom-iso.sh"]
