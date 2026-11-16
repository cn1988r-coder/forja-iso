# Fundação EndeavourOS preservada (não ativa)

Esta pasta contém uma fundação técnica anterior baseada no EndeavourOS. Ela é mantida no repositório para preservar o trabalho, as referências e o histórico já realizados.

## Situação atual

A decisão do projeto mudou: a edição principal da **Forja OS será derivada diretamente do Arch Linux**, usando os repositórios e espelhos oficiais do Arch. Esta fundação EndeavourOS não é a base ativa, não deve orientar builds, validações, seleção de pacotes ou decisões futuras da edição principal.

Não apagar nem reutilizar automaticamente estes arquivos na base Arch. Qualquer eventual reaproveitamento exige auditoria individual de compatibilidade, origem e finalidade.

## Conteúdo preservado

- `packages.x86_64`: seleção anterior de pacotes fundamentais e componentes próprios do EndeavourOS.
- `profiledef.sh`: parâmetros iniciais do perfil antigo.
- `pacman.conf`: configuração antiga que inclui repositório EndeavourOS e repositórios Arch.

## Origem histórica

- Projeto ISO oficial: https://github.com/endeavouros-team/EndeavourOS-ISO
- Commit consultado em 2026-11-16: `0bbb1280ccd373262561453d85201f2707483990`

Esta pasta é somente uma referência preservada. Não representa uma edição suportada ou validada da Forja OS.