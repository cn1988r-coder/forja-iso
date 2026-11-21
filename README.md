# VENOM OS Window Maker

Edição independente da VENOM OS baseada no Arch Linux oficial, com Window Maker como único gerenciador de janelas e LightDM como login gráfico.

## Arquitetura
- Perfil de mídia: Archiso oficial.
- Ambiente gráfico: Window Maker, sem MATE, XFCE ou LXQt.
- Sessão LightDM própria: `windowmaker`.
- Tint2 fornece painel e bandeja; NetworkManager, BlueZ/Blueman e PipeWire fornecem rede, Bluetooth e áudio.
- Instalador: Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`.
- Instalação exclusivamente online via pacstrap/Pacman, dos repositórios oficiais Arch.
- Locale pt_BR.UTF-8; teclado Brasil ABNT2.
- Atualizações normais: `sudo pacman -Syu`. VENON permanece independente e manual.

## Construção
Workflow: `.github/workflows/build-arch-iso.yml`. Nenhum build foi disparado nesta migração.

## Estado
Perfil Archiso e sessão Window Maker preparados. Ainda requer validação estática em runner Arch, build autorizado, testes BIOS/UEFI e instalação completa em VM descartável.
