# Perfil Archiso da VENOM OS XFCE

Este diretório contém a edição XFCE independente da VENOM OS, construída com Archiso oficial e exclusivamente com pacotes dos repositórios oficiais do Arch Linux.

## Configuração
- Desktop XFCE e gerenciador de login LightDM.
- Boot BIOS Syslinux e UEFI GRUB.
- Locale pt_BR.UTF-8 e teclado br-abnt2.
- NetworkManager, Bluetooth/BlueZ e PipeWire.
- Calamares upstream 3.3.14 com módulo VENOM de instalação online via pacstrap.
- Hooks PXE completos, com dependências NFS/NBD instaladas.
- Compressão Zstandard no initramfs e na imagem SquashFS.

## Validação
`scripts/validate-xfce-profile.sh` verifica estrutura Archiso, pacotes XFCE, ausência de MATE/Manjaro no manifest, locale, teclado, hooks PXE, compressão e configurações do instalador.

Nenhuma ISO foi gerada nesta migração. Não declarar a edição pronta antes de build autorizado, testes BIOS/UEFI e instalação completa em VM descartável.
