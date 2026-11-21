# VENOM OS

Distribuição independente baseada diretamente no Arch Linux oficial, com MATE, LightDM, identidade própria e instalador gráfico Calamares.

- Base e repositórios: Arch Linux oficial.
- Mídia: perfil próprio Archiso.
- Idioma: Português do Brasil; teclado: Brasil ABNT2.
- Instalação exclusivamente online via pacstrap/Pacman.
- Sem instalação offline ou cópia do sistema live para o disco.

Projeto em desenvolvimento. Boot live não comprova instalação funcional. Só declarar pronto após instalação completa em VMs BIOS e UEFI, primeiro boot e validação do sistema instalado.

Pacman administra o sistema com sudo pacman -Syu. VENON é separado e manual: venon-upgrade consulta; venon-update instala após confirmação.
