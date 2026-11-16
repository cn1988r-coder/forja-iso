# Fundação oficial Arch Linux

Esta é a **base oficial escolhida para a Forja OS**. A distribuição será derivada diretamente do Arch Linux, usando seus repositórios e espelhos oficiais para o sistema-base.

## Responsabilidade

O Arch Linux fornece kernel, firmware, drivers, bibliotecas, ferramentas essenciais e pacotes oficiais. A Forja não substituirá esses componentes por versões próprias.

O repositório binário Forja será uma fonte adicional e separada, restrita a aplicativos e componentes próprios. Não terá prioridade sobre os repositórios oficiais e não será usado para atualizar o sistema-base.

## Perfil e construção

- `packages.x86_64`: seleção inicial de pacotes da base Arch.
- `pacman.conf`: somente repositórios oficiais Arch (`core` e `extra`).
- `profiledef.sh`: metadados iniciais do perfil Archiso.
- `build-profile.sh`: obtém o perfil oficial `releng` do Archiso em commit fixo, combina os pacotes Arch/MATE e aplica a árvore `airootfs` da Forja.
- `airootfs/`: configurações do MATE, LightDM, usuário live, locale pt_BR, fuso de São Paulo, teclado ABNT2 e atalhos de instalação.

## Instalador

A sessão live inclui o Archinstall oficial, aberto pelo atalho **Instalar Forja OS**. Ele é um instalador interativo em terminal, não o Calamares. O usuário deverá selecionar o disco, particionamento, bootloader, usuário e os pacotes necessários. A integração que garante a instalação automática de todas as personalizações Forja no sistema de destino ainda precisa ser concluída e testada.

## Validação

O GitHub Actions valida os nomes de pacotes, scripts e estrutura do perfil e executa a tentativa de build da ISO. Uma validação estática ou um build de CI não substitui boot real em VM, teste de hardware, instalação no disco e teste do sistema instalado.

**Estado:** perfil e fluxo de construção inicial integrados ao branch de desenvolvimento. A primeira ISO ainda não foi validada como mídia inicializável ou instalável. Não executar build no Dell Inspiron com SSD de 128 GB; usar GitHub Actions ou um host Arch com espaço livre suficiente.