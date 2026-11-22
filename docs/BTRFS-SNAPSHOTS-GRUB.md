# Btrfs, Timeshift e recuperação pelo GRUB

## Decisão obrigatória

As edições VENOM OS XFCE e VENOM OS MATE usam **Btrfs** na partição raiz, mantêm **GRUB** como único gerenciador de inicialização e incluem **Timeshift** e **grub-btrfs**. Não instalar nem configurar systemd-boot.

## Layout compatível com Timeshift

A partição Btrfs deve usar o layout plano:
- `@` montado em `/`
- `@home` montado em `/home`

O instalador deve montar o top-level Btrfs temporariamente, criar esses subvolumes, desmontar o top-level e montar os subvolumes nos pontos definitivos. O `/etc/fstab` deve usar `subvol=@` e `subvol=@home`, nunca IDs fixos de subvolume. Não alterar o subvolume padrão do filesystem.

## GRUB e menu de snapshots

- Manter GRUB e gerar o menu normal com `grub-mkconfig`.
- Instalar `grub-btrfs` e `inotify-tools`.
- Configurar `grub-btrfsd` para observar snapshots do Timeshift com `--syslog --timeshift-auto`.
- Habilitar `grub-btrfsd.service` somente no sistema instalado, depois que o GRUB estiver instalado e a configuração inicial tiver sido gerada.
- O menu de snapshots deve ser regenerado quando snapshots forem criados ou removidos.

## Recuperação e limites

Snapshots Btrfs do Timeshift permitem iniciar uma versão anterior pelo submenu de snapshots do GRUB. O usuário deve poder restaurar a partir do Timeshift depois de iniciar o sistema ou usar uma mídia de recuperação. Snapshots não substituem cópia externa: falha física do disco pode destruir sistema e snapshots juntos.

## Estado da implementação

O plano de partição do instalador agora especifica Btrfs e declara os subvolumes `@` e `@home`. Os manifestos passam a incluir btrfs-progs, Timeshift, grub-btrfs e inotify-tools nas duas edições. Isso prepara os componentes, mas **não significa que a criação dos subvolumes, fstab, instalação do GRUB, ativação do serviço ou boot de snapshots já tenham sido executados pelo instalador**. Essas etapas dependem do backend de instalação e precisam ser validadas em VMs descartáveis BIOS e UEFI antes de liberar qualquer ISO.
