# Fundação Arch Linux

Fundação independente baseada no projeto oficial Arch Linux e no perfil baseline do Archiso.

## Objetivo

Oferecer uma base técnica mínima para construir a Forja OS sobre Arch Linux, sem ambiente gráfico ou personalizações de interface.

## Conteúdo

- `packages.x86_64`: seleção inicial e enxuta de pacotes para uma base em modo texto e ferramentas fundamentais de preparação.
- `profiledef.sh`: parâmetros iniciais do perfil Archiso.
- `pacman.conf`: configuração inicial dos repositórios oficiais Arch.

## Limites atuais

Isto ainda não é uma ISO compilável validada. O perfil precisa receber os arquivos de sistema necessários, boot, permissões, serviços e scripts de construção, e depois passar por validação em ambiente Arch Linux. Nenhum build foi executado.

## Origem

- Archiso oficial: https://gitlab.archlinux.org/archlinux/archiso
- Repositório espelho de leitura: https://github.com/archlinux/archiso
- Commit de referência: `8e3ead17e1e5cfde503534d23be918b8787d3dd3`
- Perfil de referência: `configs/baseline`

A lista de pacotes é uma seleção inicial da Forja OS, não uma cópia integral da lista baseline oficial.
