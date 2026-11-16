# Fundação EndeavourOS

Fundação independente baseada no EndeavourOS, preservando a identidade técnica da distribuição e seus componentes essenciais, sem importar a sessão gráfica da ISO oficial.

## Objetivo

Oferecer uma base técnica em modo texto para construir a Forja OS sobre EndeavourOS. Esta base não deve ser reduzida a uma cópia da base Arch: mantém os repositórios, chaves e ferramentas próprias do EndeavourOS que forem necessárias.

## Conteúdo

- `packages.x86_64`: seleção inicial de pacotes fundamentais e componentes próprios do EndeavourOS.
- `profiledef.sh`: parâmetros iniciais de perfil para construção de mídia.
- `pacman.conf`: repositório EndeavourOS e repositórios oficiais Arch.

## Limites atuais

Isto ainda não é uma ISO compilável validada. A estrutura precisa receber os arquivos de sistema realmente necessários, mirrorlists, serviços, boot, permissões e scripts, e depois ser testada. Nenhum build foi executado.

A ISO oficial consultada inclui KDE, ferramentas gráficas e componentes de sessão live. Esses elementos não foram incorporados nesta fundação.

## Origem

- Projeto ISO oficial: https://github.com/endeavouros-team/EndeavourOS-ISO
- Commit consultado em 2026-11-16: `0bbb1280ccd373262561453d85201f2707483990`

A seleção de pacotes abaixo é uma base inicial curada, não uma cópia integral da lista oficial da ISO.
