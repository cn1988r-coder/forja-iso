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
      btrfs-progs \
      mkinitcpio \
      inotify-tools \
      cronie \
      jq \
      xorriso \
      python \
      python-pip \
      sudo \
      shadow \
      cmake \
      ninja \
      extra-cmake-modules \
      qt6-base \
      qt6-declarative \
      qt6-svg \
      qt6-tools \
      kconfig \
      kcoreaddons \
      kcrash \
      kparts \
      kirigami \
      kpackage \
      kpmcore \
      yaml-cpp \
      python-yaml \
      python-jsonschema \
      libpwquality \
      hwinfo \
      polkit-qt6 \
      appstream-qt \
      pybind11 \
      meson \
      glib2 \
      json-glib \
      ncurses \
      pkgconf \
      shellcheck \
      qemu-system-x86 \
      edk2-ovmf \
      xorg-server-xvfb \
      xorg-xwininfo \
      dbus \
    && pacman -Scc --noconfirm

ARG BUILD_UID=1001
ARG BUILD_GID=1001

RUN getent group "${BUILD_GID}" >/dev/null || groupadd --gid "${BUILD_GID}" builder; \
    useradd --create-home --uid "${BUILD_UID}" --gid "${BUILD_GID}" --groups wheel builder && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

WORKDIR /workspace
USER builder
CMD ["/bin/bash"]
