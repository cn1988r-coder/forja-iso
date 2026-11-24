# VENOM OS XFCE | Perfil Archiso

Perfil de mídia Live e instalação da VENOM OS baseado diretamente no Arch Linux oficial e no Archiso.

## Ambiente Live
- XFCE com LightDM e sessão automática no usuário temporário `venom`.
- Painel inferior único de 40 px.
- Whisker Menu com o emblema azul VENOM.
- Docklike Taskbar imediatamente depois do botão Iniciar, alinhado à esquerda.
- Materia Dark, Papirus Dark com pastas azuis e Bibata Modern Classic.
- NetworkManager, Bluetooth, PipeWire/WirePlumber e ferramentas de sistema.
- Inicialização BIOS/Syslinux e UEFI/GRUB, com kernel principal e LTS de reserva.

## Sistema instalado
- Arch Linux com XFCE e LightDM.
- Calamares com módulo VENOM que instala pacotes oficiais Arch via pacstrap e aplica o overlay da edição.
- Btrfs como sistema de arquivos padrão, com subvolumes `@` e `@home`.
- ESP montada em `/boot/efi`, mantendo kernel, initramfs e configuração GRUB dentro do subvolume raiz.
- Timeshift em modo Btrfs, snapshots diários/semanais e integração grub-btrfs.
- Serviço de primeira inicialização configura UUID, mkinitcpio, GRUB, cron e primeiro snapshot.

## Manifestos e diretórios
- `packages.x86_64`: pacotes da mídia Live.
- `install-packages.x86_64`: pacotes do sistema instalado.
- `aur-packages.x86_64`: pacotes AUR construídos separadamente e servidos por repositório local.
- `airootfs/`: personalização da sessão Live.
- `install-overlay/`: configurações aplicadas ao sistema instalado.
- `profiledef.sh`, `syslinux/`, `grub/`: configuração oficial do Archiso.
- `../installer/`: configurações e módulo Calamares da VENOM.

## Estado de preparação
Os arquivos do perfil e da instalação estão sendo integrados. Nenhuma ISO foi compilada nesta etapa. A recuperação Btrfs/Timeshift/GRUB ainda precisa passar por validação de instalação, boot e restauração em máquinas virtuais BIOS e UEFI antes de ser considerada estável.
