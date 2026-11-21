# VENOM OS XFCE

Edição independente da VENOM OS baseada diretamente no Arch Linux oficial, com ambiente XFCE e LightDM.

## Arquitetura
- Perfil de mídia: Archiso oficial.
- Desktop: XFCE, sem MATE como ambiente subjacente.
- Instalador: Calamares upstream 3.3.14, branding VENOM e módulo customizado `venominstall`.
- Instalação exclusivamente online por pacstrap/Pacman, usando repositórios oficiais Arch.
- Sem instalação offline, unpackfs ou cópia da raiz live.
- Idioma: pt_BR.UTF-8; teclado: Brasil ABNT2.
- Atualizações normais: `sudo pacman -Syu`. VENON permanece independente e manual.

## Construção
Workflow: `.github/workflows/build-arch-iso.yml`. O workflow só compila quando iniciado manualmente ou pelo marcador explícito de build configurado no próprio workflow. Nenhum build foi disparado nesta migração.

## Estado
Perfil XFCE reconstruído sobre Archiso. Ainda requer validação estática em runner Arch, build autorizado, smoke tests BIOS/UEFI e instalação completa em VM antes de ser considerado pronto.
