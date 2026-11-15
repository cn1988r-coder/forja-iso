# Validação estática da edição Forja OS XFCE e da interface Pamac personalizada.
FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
      bash shellcheck grep coreutils python desktop-file-utils libxml2 appstream archlinux-appstream-data flatpak \
    && pacman -Scc --noconfirm \
    && appstreamcli refresh-cache

WORKDIR /src
COPY build-cloud.sh /src/build-cloud.sh
COPY build-manjaro.sh /src/build-manjaro.sh
COPY desktops/xfce /src/desktops/xfce
COPY forja-pamac-pacman /src/forja-pamac-pacman

RUN for script in \
      /src/build-cloud.sh \
      /src/build-manjaro.sh \
      /src/desktops/xfce/apply-forja-layout.sh \
      /src/desktops/xfce/install-branding.sh \
      /src/forja-pamac-pacman/install.sh \
      /src/forja-pamac-pacman/build-pamac.sh \
      /src/forja-pamac-pacman/src/forja-pkexec-sudo; do bash -n "$script"; done \
    && shellcheck -S warning -e SC1091 \
      /src/build-cloud.sh \
      /src/build-manjaro.sh \
      /src/desktops/xfce/apply-forja-layout.sh \
      /src/desktops/xfce/install-branding.sh \
      /src/forja-pamac-pacman/install.sh \
      /src/forja-pamac-pacman/build-pamac.sh \
      /src/forja-pamac-pacman/src/forja-pkexec-sudo \
    && python -m py_compile \
      /src/forja-pamac-pacman/src/forja_store_core.py \
      /src/forja-pamac-pacman/src/forja-pacman-transaction \
      /src/forja-pamac-pacman/src/forja-update-indicator \
    && python -m unittest discover -s /src/forja-pamac-pacman/tests -v \
    && desktop-file-validate \
      /src/desktops/xfce/forja-xfce-appearance.desktop \
      /src/forja-pamac-pacman/forja-software.desktop \
      /src/forja-pamac-pacman/forja-update-indicator.desktop \
    && python -c 'import xml.etree.ElementTree as ET; [ET.parse(p) for p in ["/src/desktops/xfce/forja-flame.svg", "/src/desktops/xfce/forja-black-wallpaper.svg", "/src/desktops/xfce/forja-xfce-desktop.xml", "/src/desktops/xfce/panel-default.xml", "/src/forja-pamac-pacman/icons/forja-store.svg", "/src/forja-pamac-pacman/icons/forja-update-current.svg", "/src/forja-pamac-pacman/icons/forja-update-available.svg", "/src/forja-pamac-pacman/icons/forja-update-error.svg"]]' \
    && bash /src/desktops/xfce/tests/validate-appearance.sh

CMD ["bash", "-n", "/src/build-cloud.sh"]
