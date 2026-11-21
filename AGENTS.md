# AGENTS.md

VENOM OS é uma distribuição independente baseada no Arch Linux oficial, com MATE, LightDM e instalador Calamares.

- Repositório: cn1988r-coder/forja-iso.
- Branch autorizada: optimize/venom-iso-size.
- Não alterar main ou outras branches.
- Não declarar funcionalidade ou teste sem evidência.
- Base e repositórios: Arch Linux oficial.
- Idioma: pt_BR.UTF-8; teclado: Brasil ABNT2.
- Instalador: Calamares upstream, branding VENOM e módulo próprio.
- Instalação exclusivamente online via pacstrap/Pacman, dos repositórios oficiais Arch.
- Proibido unpackfs, rsync ou cópia da raiz live como mecanismo de instalação.
- Calamares particiona e monta; venominstall instala no rootMountPoint.
- Sem internet/mirror, interromper com erro claro.
- Não declarar funcional antes de instalação completa em VMs descartáveis BIOS e UEFI.
- Pacman atualiza: sudo pacman -Syu. VENON é separado e manual: venon-upgrade consulta; venon-update instala após confirmação. Sem timers.
- Registrar testes e pendências em docs/PROJECT-CONTINUITY.md.
