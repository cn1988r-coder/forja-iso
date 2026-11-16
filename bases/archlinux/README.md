# Fundação oficial Arch Linux

Esta é a **base oficial escolhida para a Forja OS**. A distribuição será derivada diretamente do Arch Linux, usando seus repositórios e espelhos oficiais para o sistema-base.

## Responsabilidade

O Arch Linux fornece kernel, firmware, drivers, bibliotecas, ferramentas essenciais e os pacotes oficiais do sistema. A Forja não substituirá esses componentes por versões próprias.

O repositório binário Forja será uma fonte adicional e separada, restrita a aplicativos e componentes desenvolvidos ou mantidos pelo projeto. Não terá prioridade sobre os repositórios oficiais e não será usado para atualizar o sistema-base.

## Conteúdo atual

- `packages.x86_64`: seleção inicial de pacotes para uma base mínima em modo texto.
- `profiledef.sh`: parâmetros iniciais de perfil Archiso.
- `pacman.conf`: configuração inicial dos repositórios oficiais Arch (`core` e `extra`).

## Estado e próximos passos

Esta fundação **ainda não é uma ISO compilável validada**. Antes do primeiro build instalável, precisamos completar e auditar o perfil Archiso: estrutura `airootfs`, bootloader, initramfs, serviços, permissões, mirrorlist, usuário live, instalador, integração MATE e inclusão dos aplicativos Forja. Também será necessário validar a instalação em máquina virtual e testar o sistema instalado.

Nenhum build de ISO ou instalação funcional foi realizado nesta etapa.

## Origem

- Archiso oficial: https://gitlab.archlinux.org/archlinux/archiso
- Repositório espelho de leitura: https://github.com/archlinux/archiso
- Commit de referência: `8e3ead17e1e5cfde503534d23be918b8787d3dd3`
- Perfil de referência: `configs/baseline`

A lista de pacotes é uma seleção inicial da Forja OS, não uma cópia integral da lista baseline oficial.