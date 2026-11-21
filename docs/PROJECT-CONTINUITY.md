# Continuidade técnica: VENOM OS Window Maker

Atualizado em 21/11/2026.

## Arquitetura
- Branch: `feature/forja-window-maker-endeavouros`.
- Base: Arch Linux oficial e repositórios oficiais.
- Ambiente gráfico exclusivo: Window Maker, com sessão LightDM própria.
- Não incluir MATE, XFCE ou LXQt como desktop subjacente.
- Painel/bandeja: Tint2; rede NetworkManager; Bluetooth BlueZ/Blueman; áudio PipeWire.
- Locale pt_BR.UTF-8; teclado br-abnt2.
- Mídia Archiso oficial.
- Instalador Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`, instalação online via pacstrap.

## Migração executada
- Importada a estrutura Archiso e Calamares aprovada na branch Arch/MATE.
- Manifest live separado do manifesto de pacotes do sistema instalado. O destino não recebe ferramentas exclusivas da ISO.
- Manifest instalado contém Window Maker, Xorg, LightDM, Tint2, dmenu, feh, xterm, rede, Bluetooth, áudio, GRUB e dependências básicas, sem outro desktop.
- LightDM configurado para `user-session=windowmaker`, sem autologin no sistema instalado.
- Overlay de instalação inclui sessão `windowmaker.desktop`, launcher executável, menu, wallpaper, Tint2, GTK e configuração de LightDM.
- Launcher inicia Tint2, applets de rede/Bluetooth e agente Polkit, define wallpaper e executa `wmaker`.
- Módulo VENOM usa pacstrap e copia somente o overlay explícito, antes da criação do usuário. Não copia a raiz live.
- Sequência Calamares executa locale, keyboard e users, além de fstab, displaymanager, serviços, initramfs e bootloader.
- Workflow Archiso e validador específico `scripts/validate-windowmaker-profile.sh`.

## Validação estática atual
- Run `44857753360`, commit `134ff5bd5627c1b9388136959fac8423a3e6a5c1`: sucesso.
- Instalação das ferramentas, validação do perfil e disponibilidade dos pacotes oficiais, sintaxe dos scripts e conclusão do job passaram.
- Validações anteriores `44857321135` e `44857174391` também passaram.
- Essa validação não compila a ISO nem testa boot ou instalação real.

## Validação de mídia pendente
- Build ISO e instalação real em VM ainda não foram executados.
- Não iniciar build ISO sem autorização expressa.
- Após autorização de build, validar boot BIOS/UEFI e instalação completa em VM descartável, incluindo primeiro login gráfico Window Maker.
