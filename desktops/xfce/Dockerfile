# Static validation container for the Forja XFCE appearance module.
# Build from the repository root:
#   docker build -f desktops/xfce/Dockerfile .
FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed bash shellcheck grep coreutils \
    && pacman -Scc --noconfirm

WORKDIR /src
COPY desktops/xfce/apply-forja-layout.sh /src/apply-forja-layout.sh
COPY desktops/xfce/install-branding.sh /src/install-branding.sh
COPY desktops/xfce/forja-gtk.css /src/forja-gtk.css
COPY desktops/xfce/packages.arch /src/packages.arch
COPY desktops/xfce/packages.manjaro /src/packages.manjaro

RUN bash -n /src/apply-forja-layout.sh /src/install-branding.sh \
    && shellcheck /src/apply-forja-layout.sh /src/install-branding.sh \
    && grep -q '^adw-gtk-theme$' /src/packages.arch \
    && grep -q '^adw-gtk-theme$' /src/packages.manjaro \
    && grep -q '^papirus-icon-theme$' /src/packages.arch \
    && grep -q '^papirus-icon-theme$' /src/packages.manjaro \
    && grep -q '^bibata-cursor-theme$' /src/packages.arch \
    && grep -q '^bibata-cursor-theme$' /src/packages.manjaro \
    && ! grep -q '^materia-gtk-theme$' /src/packages.arch \
    && ! grep -q '^materia-gtk-theme$' /src/packages.manjaro \
    && grep -q 'GTK_THEME="adw-gtk3-dark"' /src/apply-forja-layout.sh \
    && grep -q 'ICON_THEME="Papirus-Dark"' /src/apply-forja-layout.sh \
    && grep -q 'CURSOR_THEME="Bibata-Modern-Classic"' /src/apply-forja-layout.sh

CMD ["bash", "-n", "/src/apply-forja-layout.sh"]
