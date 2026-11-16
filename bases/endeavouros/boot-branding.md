# Identidade visual de inicializacao da Forja OS

## Estado desta etapa

- O perfil da ISO declara BIOS/Syslinux e UEFI/GRUB.
- Os menus de inicializacao BIOS e UEFI usam o nome **FORJA OS**.
- Os parametros essenciais do archiso foram preservados nos dois caminhos.
- O menu GRUB usa modo grafico e cores neutras, com fundo preto.
- A tela Plymouth com a chama preta ainda nao esta integrada. Ela depende da definicao e validacao do mecanismo de initramfs usado por esta base (dracut/mkinitcpio) e de um tema com recursos graficos adequados.

## Limites

Esta configuracao e uma primeira camada de identidade para o menu da ISO, nao uma declaracao de que a ISO compila ou inicializa corretamente. O perfil EndeavourOS ainda esta marcado como fundacao inicial e precisa de validacao integral com mkarchiso em ambiente de CI.

A marca tecnica dos pacotes, chaves e ferramentas EndeavourOS e mantida. Somente os textos dos menus desta ISO foram personalizados nesta etapa.
