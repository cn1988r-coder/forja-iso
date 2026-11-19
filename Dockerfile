FROM archlinux:latest

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed curl wget sudo shadow git base-devel archiso squashfs-tools imagemagick python

RUN pacman-key --init && pacman-key --populate archlinux && \
    curl -fsSL https://raw.githubusercontent.com/endeavouros-team/EndeavourOS-ISO/90376d8f52ab19e19073eed33d6f36c46ec7c409/pacman.conf -o /etc/pacman.conf && \
    mkdir -p /etc/pacman.d && \
    curl -fsSL https://raw.githubusercontent.com/endeavouros-team/PKGBUILDS/474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd/endeavouros-mirrorlist/endeavouros-mirrorlist -o /etc/pacman.d/endeavouros-mirrorlist && \
    pacman-key --recv-key 0F20FADC599D1C46EB556455AED8858E4B9813F1 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key 0F20FADC599D1C46EB556455AED8858E4B9813F1 && \
    pacman-key --recv-key 497AF50C92AD2384C56E1ACA003DB8B0CB23504F --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key 497AF50C92AD2384C56E1ACA003DB8B0CB23504F && \
    pacman -Syy --noconfirm endeavouros-keyring endeavouros-mirrorlist && \
    pacman -Syu --noconfirm

ARG BUILD_UID=1000
ARG BUILD_GID=1000

RUN getent group "$BUILD_GID" >/dev/null || groupadd --gid "$BUILD_GID" builder; \
    useradd --create-home --uid "$BUILD_UID" --gid "$BUILD_GID" --groups wheel builder && \
    printf 'builder ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

WORKDIR /workspace
USER builder
ENTRYPOINT ["bash", "scripts/build-forja-iso.sh"]
