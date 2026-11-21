# AGENTS.md

Esta branch implementa a edição **VENOM XFCE** da VENOM OS, baseada no Arch Linux oficial.

- Desktop exclusivo desta edição: XFCE + LightDM. Não instalar MATE.
- Base/repositórios: somente Arch Linux oficial.
- Mídia: Archiso oficial, perfil em `build/`.
- Instalador final: implementação própria e independente da VENOM OS, ainda pendente. Não compilar enquanto houver dependência de instalador externo.
- Instalação exclusivamente online via pacstrap/Pacman. Sem unpackfs, rsync ou cópia da raiz live.
- Idioma pt_BR.UTF-8, teclado br-abnt2.
- Pacman atualiza o sistema: `sudo pacman -Syu`.
- VENON é independente e manual: `venon-upgrade` consulta; `venon-update` instala após confirmação.
- Não alterar `main`, não interromper workflows ativos, não disparar build ISO nem publicar release sem autorização expressa.
- Validar scripts, YAML, manifest e perfil antes de build; não declarar instalação funcional sem teste completo em VM.
- Registrar alterações, commits, testes e pendências em `docs/PROJECT-CONTINUITY.md`.
