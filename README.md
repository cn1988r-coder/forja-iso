# VENOM OS: snapshot histórico arquivado

Esta branch é um snapshot antigo de desenvolvimento. Não é uma edição ativa, não deve ser usada para gerar ISO e não representa a arquitetura final da VENOM OS.

## Edições ativas
- VENOM MATE: `optimize/venom-iso-size`
- VENOM XFCE: `feature/venom-community-xfce`
- VENOM Window Maker: `feature/forja-window-maker-endeavouros`

## Arquitetura definitiva
- Arch Linux oficial e somente repositórios oficiais.
- Calamares upstream 3.3.14 com módulo VENOM de instalação exclusivamente online via pacstrap.
- Não usar instalador C/GTK4 offline, Manjaro, EndeavourOS, BigLinux ou outra base.
- Pacman administra o sistema: `sudo pacman -Syu`.
- VENON é separado e manual: `venon-upgrade` consulta; `venon-update` instala somente após confirmação.

## Segurança
- Workflow e script de build permanecem bloqueados nesta branch.
- Preservar arquivos e histórico como referência; não iniciar build nem publicar ISO aqui.
