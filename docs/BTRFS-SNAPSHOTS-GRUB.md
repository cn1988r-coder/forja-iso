# Btrfs, Timeshift e recuperação pelo GRUB

## Decisão obrigatória

As edições VENOM OS XFCE e VENOM OS MATE usam **Btrfs** na partição raiz, mantêm **GRUB** como único gerenciador de inicialização e incluem **Timeshift**, **grub-btrfs**, **inotify-tools** e **cronie**. Não instalar nem configurar systemd-boot.

## Layout compatível com Timeshift

A partição Btrfs usa o layout plano:
- `@` montado em `/`
- `@home` montado em `/home`

O instalador precisa criar os subvolumes no top-level Btrfs antes de montar os pontos definitivos. O `/etc/fstab` usa `subvol=@` e `subvol=@home`, sem IDs fixos de subvolume. Não alterar o subvolume padrão do filesystem.

**O diretório `/boot` precisa permanecer dentro do subvolume raiz Btrfs.** A partição EFI, quando UEFI, é montada em `/boot/efi`. Assim kernel e initramfs fazem parte dos snapshots. Não usar UKI-only como único artefato de boot para esse fluxo.

## GRUB e menu de snapshots

- GRUB é o único bootloader suportado, em BIOS e UEFI.
- Instalar `grub-btrfs` e `inotify-tools`.
- O serviço upstream `grub-btrfsd.service` é preservado. Um drop-in redefine somente `ExecStart` para `/usr/bin/grub-btrfsd --syslog --timeshift-auto`, sem substituir o unit original e suas proteções.
- Habilitar `cronie.service` para agendamento do Timeshift.
- Habilitar `grub-btrfsd.service` somente no sistema instalado, depois da instalação do GRUB e da geração inicial de `/boot/grub/grub.cfg`.
- A configuração do Timeshift deve selecionar modo Btrfs e UUID da partição raiz.
- `mkinitcpio` inclui o módulo Btrfs e a ferramenta `btrfs` para recuperação.

## Helper de pós-instalação

`installer/scripts/configure-btrfs-snapshots.sh ROOT_DIR ROOT_BLOCK_DEVICE` prepara o fstab (validando `@` e `@home` e rejeitando `subvolid`), configura Timeshift, adiciona Btrfs ao initramfs, gera o GRUB e habilita os serviços no sistema de destino.

O helper **ainda não está conectado a um backend de instalação**. Não executá-lo manualmente em uma instalação real: o fluxo só poderá chamá-lo depois de criar e montar corretamente os subvolumes, instalar os pacotes e o kernel, montar a ESP em `/boot/efi` (UEFI) e instalar o GRUB no modo de firmware correto.

## Validação obrigatória antes de liberar ISO

Testar em VMs descartáveis, separadamente em BIOS e UEFI:
1. instalação limpa e criação dos subvolumes;
2. fstab sem `subvolid`, com `@` e `@home`;
3. kernel/initramfs sob `/boot` dentro do Btrfs;
4. GRUB normal e submenu de snapshots;
5. criação de snapshot Timeshift e atualização automática do menu;
6. boot real de snapshot e restauração para o sistema principal.

Snapshots não substituem cópia externa: falha física do disco pode destruir sistema e snapshots juntos. Nenhuma ISO deve ser liberada antes de todos os testes passarem.
