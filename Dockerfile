FROM archlinux:latest

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV MAKEFLAGS="-j2"

RUN pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm \
      base-devel \
      git \
      archiso \
      squashfs-tools \
      dosfstools \
      libisoburn \
      mtools \
      grub \
      efibootmgr \
      rsync \
      curl \
      wget \
      arch-install-scripts \
      xorriso \
      python \
      python-pip \
      sudo \
      shadow \
    && pacman -Scc --noconfirm

ARG BUILD_UID=1001
ARG BUILD_GID=1001

RUN getent group "${BUILD_GID}" >/dev/null || groupadd --gid "${BUILD_GID}" builder; \
    useradd --create-home --uid "${BUILD_UID}" --gid "${BUILD_GID}" --groups wheel builder && \
    printf 'builder ALL=(ALL) NOPASSWD: ALL\\n' > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

WORKDIR /workspace
USER builder
CMD ["/bin/bash"]
