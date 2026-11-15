# Static validation container for the Forja OS XFCE + Store integration.
# Build from the repository root:
#   docker build -f desktops/xfce/Dockerfile .

FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
      bash shellcheck grep coreutils python desktop-file-utils libxml2 \
    && pacman -Scc --noconfirm

WORKDIR /src
COPY build-manjaro.sh /src/build-manjaro.sh
COPY desktops/xfce /src/desktops/xfce
COPY forja-pamac-pacman /src/forja-pamac-pacman

RUN bash -n /src/build-manjaro.sh \
    /src/desktops/xfce/apply-forja-layout.sh \
    /src/desktops/xfce/install-branding.sh \
    /src/forja-pamac-pacman/install.sh \
    /src/forja-pamac-pacman/src/forja-pkexec-sudo \
    && shellcheck -S warning -e SC1091 \
      /src/desktops/xfce/apply-forja-layout.sh \
      /src/desktops/xfce/install-branding.sh \
      /src/forja-pamac-pacman/install.sh \
      /src/forja-pamac-pacman/src/forja-pkexec-sudo \
    && python -m py_compile \
      /src/forja-pamac-pacman/src/forja-store \
      /src/forja-pamac-pacman/src/forja-pacman-transaction \
      /src/forja-pamac-pacman/src/forja-update-indicator \
    && desktop-file-validate \
      /src/desktops/xfce/forja-xfce-appearance.desktop \
      /src/forja-pamac-pacman/forja-software.desktop \
      /src/forja-pamac-pacman/forja-update-indicator.desktop \
    && xmllint --noout \
      /src/desktops/xfce/forja-flame.svg \
      /src/desktops/xfce/forja-xfce-wallpaper.svg \
      /src/forja-pamac-pacman/icons/forja-update-current.svg \
      /src/forja-pamac-pacman/icons/forja-update-available.svg \
      /src/forja-pamac-pacman/icons/forja-update-error.svg \
    && bash /src/desktops/xfce/tests/validate-appearance.sh

CMD ["bash", "-n", "/src/desktops/xfce/apply-forja-layout.sh"]
