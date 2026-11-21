# AGENTS.md

Esta branch implementa a edição **VENOM Window Maker** da VENOM OS, baseada no Arch Linux oficial.

- Ambiente gráfico exclusivo: Window Maker + LightDM.
- Não instalar MATE, XFCE, LXQt ou outro desktop subjacente.
- Base/repositórios: somente Arch Linux oficial.
- Mídia: Archiso oficial, perfil em `build/`.
- Instalador: Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`.
- Instalação exclusivamente online via pacstrap/Pacman. Sem unpackfs, rsync ou cópia da raiz live.
- Idioma pt_BR.UTF-8, teclado br-abnt2.
- Pacman atualiza: `sudo pacman -Syu`; VENON é independente e manual.
- Não alterar `main`, não interromper workflows ativos, não disparar build ISO nem publicar release sem autorização expressa.
- Não declarar instalação funcional sem teste completo em VM BIOS e UEFI.
- Registrar alterações, commits, testes e pendências em `docs/PROJECT-CONTINUITY.md`.
