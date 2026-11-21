# Continuidade técnica: VENOM OS XFCE

Atualizado em 20/11/2026.

## Arquitetura
- Branch: `feature/venom-community-xfce`.
- Base: Arch Linux oficial e repositórios oficiais.
- Desktop: XFCE real + LightDM; sem MATE.
- Idioma pt_BR.UTF-8; teclado br-abnt2.
- Mídia Archiso oficial.
- Instalador Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`.
- Instalação exclusivamente online via pacstrap/Pacman. Sem unpackfs, rsync ou cópia da raiz live.
- Atualizações normais pelo Pacman; VENON separado e manual.

## Migração executada
- Reconstruída a estrutura operacional sobre Archiso e arquivos Calamares aprovados na branch Arch/MATE.
- Manifest live XFCE separado do manifesto de pacotes do sistema instalado.
- Pacotes do sistema instalado incluem XFCE, Thunar, LightDM, Xorg, rede, Bluetooth, áudio, GRUB e dependências básicas, sem ferramentas de criação da ISO.
- LightDM configurado para a sessão `xfce`; sem autologin no sistema instalado.
- Overlay de instalação inclui configurações XFCE/GTK, tema XFWM4, wallpaper, ícones e configuração de LightDM.
- Módulo VENOM instala pacotes oficiais com pacstrap e copia somente o overlay explícito, antes da criação do usuário. Não copia a raiz live.
- Sequência Calamares executa locale, keyboard e users, além de fstab, displaymanager, serviços, initramfs e bootloader.
- Removidos workflows e diretórios operacionais Manjaro, perfis antigos, Pamac, MHWD e credenciais padrão.
- Workflow Archiso e validador específico `scripts/validate-xfce-profile.sh`.

## Estado anterior
- Run #76, ID `44843598356`, falhou por pacote `adwaita-gtk-theme` não encontrado.
- Perfil antigo continha `mhwd`, autologin e senha padrão `venom`.
- Nenhuma ISO desse estado é considerada instalável.

## Validação pendente
- Concluir validação estática em container Arch, incluindo disponibilidade dos pacotes dos dois manifestos e sintaxe dos scripts.
- Não iniciar build ISO sem autorização expressa.
- Após build autorizado, validar BIOS/UEFI e instalação completa em VM descartável, incluindo primeiro login XFCE.
