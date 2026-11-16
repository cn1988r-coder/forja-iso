# Ambiente isolado para validar o perfil-fonte Forja OS XFCE.
FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed bash coreutils grep python \
    && pacman -Scc --noconfirm

WORKDIR /src
COPY build-manjaro.sh /src/build-manjaro.sh
COPY desktops/xfce /src/desktops/xfce

RUN bash -n /src/build-manjaro.sh \
    && find /src/desktops/xfce -type f -name '*.sh' -print0 \
       | while IFS= read -r -d '' script; do bash -n "$script"; done \
    && bash /src/desktops/xfce/tests/validate-appearance.sh

CMD ["bash", "-n", "/src/build-manjaro.sh"]
