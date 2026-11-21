# Continuidade técnica: VENOM OS XFCE

Atualizado em 20/11/2026.

## Arquitetura
- Branch: `feature/venom-community-xfce`.
- Base: Arch Linux oficial e repositórios oficiais.
- Desktop: XFCE real + LightDM; sem MATE.
- Idioma pt_BR.UTF-8; teclado br-abnt2.
- Perfil de mídia: Archiso oficial.
- Instalador: Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`.
- Instalação online via pacstrap/Pacman. Sem cópia da raiz live, unpackfs ou rsync.
- Atualizações normais pelo Pacman; VENON separado e manual.

## Migração executada
- Substituída a antiga estrutura operacional Manjaro por perfil Archiso e arquivos Calamares copiados da arquitetura aprovada na branch Arch/MATE.
- Manifest reconstruído para XFCE, sem pacotes MATE, Pamac, MHWD ou Manjaro.
- Dependências PXE `mkinitcpio-nfs-utils` e `nbd` adicionadas.
- Compressão initramfs e SquashFS ajustada para zstd.
- Configurações XFCE e GTK selecionadas foram migradas para o airootfs.
- Removidos workflows Manjaro antigos e credenciais padrão da árvore ativa.
- Novo workflow Archiso restrito a esta branch; não foi executado.

## Estado anterior
- Run #76, ID `44843598356`, falhou na instalação de pacotes por pacote `adwaita-gtk-theme` não encontrado.
- A branch continha workflows Manjaro, perfil MATE Manjaro e perfil XFCE com `mhwd`, autologin e senha padrão `venom`.
- Nenhuma ISO desse estado é considerada instalável.

## Validação pendente
- Conferir nomes de todos os grupos/pacotes no repositório oficial Arch atual.
- Executar o validador estático em container Arch.
- Não iniciar build ISO sem autorização expressa.
- Após build autorizado, validar boot BIOS/UEFI e instalação completa em VM descartável, incluindo primeiro boot.
