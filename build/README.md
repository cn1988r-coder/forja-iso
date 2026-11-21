# Perfil Archiso da VENOM OS XFCE

Edição XFCE baseada no Arch Linux oficial e construída com Archiso oficial.

## Configuração
- XFCE e LightDM.
- Boot BIOS/Syslinux e UEFI/GRUB.
- Locale pt_BR.UTF-8 e teclado br-abnt2.
- NetworkManager, BlueZ, PipeWire e WirePlumber.
- Calamares upstream 3.3.14 com módulo VENOM de instalação online via pacstrap.
- Hooks PXE e dependências NFS/NBD.
- Compressão Zstandard no initramfs e na imagem SquashFS.

## Manifestos
- `packages.x86_64`: ambiente Live.
- `install-packages.x86_64`: sistema instalado.
- `install-overlay/`: configurações XFCE e identidade visual aplicadas pelo instalador.

## Validação
Execute `bash scripts/validate-xfce-profile.sh` na raiz do repositório em ambiente Arch. A validação estática não substitui build, boot BIOS/UEFI, inspeção visual ou instalação completa em VM descartável.
