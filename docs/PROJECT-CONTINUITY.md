# Continuidade técnica da VENOM OS

Atualizado em 21/11/2026.

## Arquitetura definitiva
- Sistema: VENOM OS.
- Base: Arch Linux oficial e repositórios oficiais.
- Edições: VENOM MATE, VENOM XFCE e VENOM Window Maker.
- MATE é a edição principal, com LightDM, pt_BR.UTF-8 e teclado br-abnt2.
- Instalador: Calamares upstream 3.3.14, branding VENOM e módulo customizado `venominstall`.
- Instalação exclusivamente online via pacstrap/Pacman. Sem instalação offline, unpackfs, rsync ou cópia da raiz live.
- Pacman atualiza o sistema: `sudo pacman -Syu`.
- VENON é independente e manual: `venon-upgrade` consulta; `venon-update` instala somente após confirmação.
- Sem timers nem atualização automática.

## Branch e repositório
- Repositório: `cn1988r-coder/forja-iso`.
- Branch Arch/MATE: `optimize/venom-iso-size`.
- Preservar `main`, branches e histórico.
- Não publicar ISO/release nem iniciar build ISO sem autorização expressa.

## Execução #44
- Workflow `.github/workflows/build-arch-iso.yml`, run ID `44852869086`.
- Compilação Calamares 3.3.14, staging e validação do perfil passaram.
- mkinitcpio falhou por falta de `ipconfig`, `nfsmount` e `nbd-client` exigidos pelos hooks PXE.
- SquashFS falhou durante XZ com `xz uncompress failed with error code 9`, por volta de 78%.
- Sem ISO/artefatos. Smoke tests BIOS/UEFI e upload foram ignorados.
- Link: https://github.com/cn1988r-coder/forja-iso/actions/runs/44852869086

## Correções da mídia Arch/MATE
- Manifest live inclui `mkinitcpio-nfs-utils` e `nbd` para os hooks PXE.
- Initramfs e SquashFS usam Zstandard.
- Script de build usa Archiso oficial.
- Validador específico verifica BIOS/UEFI, locale, teclado, hooks PXE, manifestos, pacotes oficiais e Calamares.
- A edição MATE não usa AUR. O script de primeiro login aplica Materia-dark, Papirus-Dark, cursor Adwaita e wallpaper local.
- Layout MATE usa MenuBar oficial, área de notificação, controle de volume, relógio, lista de janelas e seletor de áreas de trabalho.

## Instalação no disco
- Separados `build/packages.x86_64` (mídia live) e `build/install-packages.x86_64` (sistema instalado). O destino não recebe ferramentas de build como Archiso, Syslinux, squashfs-tools ou base-devel.
- O workflow prepara o manifesto de destino e `build/install-overlay`.
- O módulo `venominstall` verifica HTTPS, executa pacstrap com pacotes oficiais, copia somente o overlay de configuração VENOM e compila dconf quando necessário. Não copia a raiz live.
- O overlay MATE inclui LightDM sem autologin, dconf, tema, ícones, wallpaper, layout do painel e configuração de primeiro login.
- A sequência Calamares executa também locale, keyboard e users, além de fstab, displaymanager, serviços, initramfs e bootloader.

## Validação estática
- Run `44857746827`, commit `6e5865d307533e56828165a89570d087875e0eba`: sucesso.
- Instalação das ferramentas, validação do perfil e disponibilidade dos pacotes oficiais, sintaxe dos scripts e conclusão do job passaram.
- Essa validação não compila a ISO nem testa boot ou instalação real.

## Validação de mídia pendente
- Não foi iniciado novo build ISO após a execução #44.
- Não iniciar build ISO sem autorização expressa.
- Após autorização: confirmar ISO/SHA256, boot BIOS/UEFI e instalação completa em VM descartável, incluindo reboot, primeiro login e serviços.
- Não declarar a ISO pronta antes de todos os testes.

## Branches históricas arquivadas
- Um conjunto de aliases antigos `feature/forja-*` foi identificado com a mesma árvore histórica `3fde0b6`. Eles foram alinhados ao commit de arquivo `bf404ef`, preservando todas as branches e seus históricos.
- Esses aliases agora documentam que não são edições ativas, mantêm build bloqueado e apontam para as três branches canônicas.
- `feature/venom-bigcommunity-mate` também foi arquivada separadamente, sem apagar seu conteúdo.
- A branch `feature/forja-window-maker-endeavouros` permanece ativa como edição Window Maker já migrada para Arch.

## Referência histórica
A ISO VENOM OS Manjaro MATE #21 e o script `manjaro-mate-dark-complete.sh` permanecem apenas como referências históricas de configuração MATE. Não são base operacional.
