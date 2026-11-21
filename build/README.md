# Perfil Archiso da VENOM OS Window Maker

Edição independente baseada no Arch Linux oficial, com Window Maker como único ambiente gráfico, LightDM, Tint2 e Calamares online.

- Boot BIOS Syslinux e UEFI GRUB.
- Locale pt_BR.UTF-8 e teclado br-abnt2.
- NetworkManager, BlueZ/Blueman e PipeWire.
- Calamares 3.3.14 com módulo VENOM de instalação via pacstrap.
- Hooks PXE com dependências NFS/NBD.
- Compressão Zstandard no initramfs e SquashFS.

O validador `scripts/validate-windowmaker-profile.sh` verifica o perfil, o manifest e a sessão Window Maker. Nenhuma ISO foi gerada nesta migração.
