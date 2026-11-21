# AGENTS.md

VENOM OS é uma distribuição independente baseada no Arch Linux oficial.

## Edições
- VENOM MATE: desktop principal, LightDM.
- VENOM XFCE: edição independente com XFCE real.
- VENOM Window Maker: edição independente com Window Maker real.
Não misturar ambientes nem criar edições adicionais.

## Arquitetura
- Repositório: cn1988r-coder/forja-iso.
- Branch principal Arch/MATE: optimize/venom-iso-size.
- Base e repositórios: Arch Linux oficial. Não usar Manjaro, EndeavourOS ou BigLinux como base operacional.
- Idioma: pt_BR.UTF-8; teclado: Brasil ABNT2.
- Mídia: Archiso oficial com perfil próprio.
- Instalador: Calamares upstream 3.3.14, branding VENOM e módulo customizado venominstall.
- Instalação exclusivamente online por pacstrap/Pacman, usando repositórios oficiais Arch.
- Sem internet, interromper com erro claro.
- Calamares deve particionar/montar, instalar no rootMountPoint e configurar fstab, locale, serviços, initramfs e bootloader.
- Proibido unpackfs, rsync ou cópia da raiz live como mecanismo de instalação.
- Não substituir Calamares por instalador C/GTK4 sem autorização explícita.

## Atualizações
- Pacman administra o sistema: sudo pacman -Syu.
- VENON é independente e manual: sudo venom.
- venon-upgrade apenas consulta/lista atualizações.
- venon-update instala atualizações VENON somente após confirmação.
- Sem timers ou atualização automática.

## Segurança e validação
- Não alterar main.
- Antes de editar uma branch, verificar workflows ativos.
- Não interromper builds ativos.
- Não publicar ISO/release nem iniciar novo build sem autorização expressa.
- Não declarar funcionalidade ou teste sem evidência.
- Não remover branches, ISOs ou documentos sem autorização inequívoca.
- Não declarar a distribuição pronta antes de instalação completa em VMs BIOS e UEFI e validação do primeiro boot.
- Registrar testes, pendências e hashes em docs/PROJECT-CONTINUITY.md.
