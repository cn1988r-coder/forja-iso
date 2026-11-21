# Continuidade técnica: VENOM OS Window Maker

Atualizado em 20/11/2026.

## Arquitetura
- Branch: `feature/forja-window-maker-endeavouros`.
- HEAD atual: `f88819bd8e012ab2a79bee59763d1c28a3a70b65`.
- Base: Arch Linux oficial e repositórios oficiais.
- Ambiente gráfico exclusivo: Window Maker, com sessão LightDM própria.
- Não incluir MATE, XFCE ou LXQt como desktop subjacente.
- Painel/bandeja: Tint2; rede NetworkManager; Bluetooth BlueZ/Blueman; áudio PipeWire.
- Locale pt_BR.UTF-8; teclado br-abnt2.
- Mídia Archiso oficial.
- Instalador Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`, instalação online via pacstrap.

## Migração executada
- Importada a estrutura Archiso e Calamares aprovada na branch Arch/MATE.
- Manifest específico com `windowmaker`, Xorg, LightDM, Tint2, dmenu, feh, xterm, rede, Bluetooth, áudio e dependências Calamares.
- Sem pacotes MATE, XFCE ou LXQt no manifest ativo.
- LightDM configurado para `user-session=windowmaker` e usuário live `venom`.
- Criados desktop entry em `/usr/share/xsessions/windowmaker.desktop`, launcher da sessão, menu Window Maker, wallpaper VENOM e configuração Tint2.
- Launcher inicia Tint2, applets de rede/Bluetooth e agente Polkit, define wallpaper e executa `wmaker`.
- Permissão executável do launcher declarada em `profiledef.sh`.
- Workflow antigo bloqueado removido; workflow Archiso restrito à branch e validador específico criado.
- Script de build chama `validate-windowmaker-profile.sh`.

## Validação pendente
- Executar `scripts/validate-windowmaker-profile.sh` em container Arch com pacman e repositórios atualizados.
- Conferir sessão Window Maker e menu em VM após build autorizado.
- Não iniciar build ISO sem autorização expressa.
- Depois de build autorizado, validar BIOS/UEFI e instalação completa em VM descartável, incluindo primeiro boot e login gráfico.
