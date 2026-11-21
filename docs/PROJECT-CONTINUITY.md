# Continuidade: snapshot histórico VENOM OS

Atualizado em 20/11/2026.

Esta branch é um snapshot histórico arquivado. Não é uma edição ativa e não deve gerar ISO.

## Arquitetura ativa
- Base: Arch Linux oficial.
- Instalador: Calamares upstream 3.3.14, branding VENOM e módulo customizado.
- Instalação exclusivamente online via pacstrap e repositórios oficiais.
- Edições ativas: MATE (`optimize/venom-iso-size`), XFCE (`feature/venom-community-xfce`) e Window Maker (`feature/forja-window-maker-endeavouros`).
- Não usar C/GTK4 offline nem bases Manjaro/EndeavourOS/BigLinux/Soplos.
- Pacman atualiza o sistema; VENON é separado e manual.

## Estado desta branch
- Workflow `.github/workflows/build-iso.yml` permanece bloqueado com job `if: false`.
- Script `scripts/build-venom-iso.sh` permanece como barreira.
- Arquivos e histórico foram preservados.
- Nenhum build ou release deve ser iniciado aqui.
