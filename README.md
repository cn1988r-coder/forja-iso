# VENOM OS

Distribuição independente baseada diretamente no **Arch Linux oficial**, com identidade própria e três edições planejadas:

- **VENOM MATE**: MATE e LightDM.
- **VENOM XFCE**: XFCE independente.
- **VENOM Window Maker**: Window Maker independente.

## Arquitetura
- Mídia construída com Archiso oficial.
- Instalador gráfico Calamares upstream 3.3.14, com branding VENOM e módulo customizado.
- Instalação exclusivamente online via pacstrap/Pacman, a partir dos repositórios oficiais Arch.
- Sem instalação offline e sem cópia do sistema live para o disco.
- Idioma padrão: Português do Brasil; teclado: Brasil ABNT2.

## Atualizações
Pacman administra o sistema e os aplicativos com `sudo pacman -Syu`. VENON é um mecanismo separado, acionado manualmente: `venon-upgrade` consulta/lista atualizações; `venon-update` instala atualizações VENON somente após confirmação.

## Estado do projeto
Em desenvolvimento. A compilação Arch/MATE #44 falhou durante a geração do initramfs e compactação SquashFS. Não há ISO validada dessa execução. Boot live não comprova instalação funcional. A distribuição só será considerada pronta após build bem-sucedido, testes BIOS/UEFI e instalação completa em VMs descartáveis, incluindo primeiro boot e validação dos serviços.
