# Continuidade técnica: VENOM OS Window Maker

Atualizado em 20/11/2026.

## Arquitetura
- Branch: `feature/forja-window-maker-endeavouros`.
- Base: Arch Linux oficial e repositórios oficiais.
- Desktop: Window Maker exclusivo, com sessão LightDM própria.
- Não incluir MATE, XFCE ou LXQt como desktop subjacente.
- Painel/bandeja: Tint2; rede NetworkManager; Bluetooth BlueZ/Blueman; áudio PipeWire.
- Locale pt_BR.UTF-8; teclado br-abnt2.
- Mídia Archiso oficial.
- Instalador Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`, instalação online via pacstrap.

## Migração executada
- Removido o workflow antigo bloqueado e substituído por workflow Archiso com gatilho manual/marcador explícito.
- Importada a estrutura Archiso e Calamares aprovada na branch Arch/MATE.
- Manifest reconstruído para Window Maker, sem pacotes MATE/XFCE/LXQt.
- Configuração LightDM aponta para sessão Window Maker.
- Criados launcher da sessão, desktop entry do LightDM, wallpaper VENOM e configuração básica Tint2.
- Dependências PXE `mkinitcpio-nfs-utils` e `nbd` incluídas.
- Compressão zstd usada no initramfs e SquashFS.
- Nenhum build ISO foi iniciado.

## Validação pendente
- Confirmar pacotes/grupos no repositório Arch atualizado.
- Executar validador estático em container Arch.
- Não iniciar build sem autorização expressa.
- Após build autorizado, validar boot BIOS/UEFI e instalação completa em VM descartável, incluindo primeiro boot e sessão Window Maker.
