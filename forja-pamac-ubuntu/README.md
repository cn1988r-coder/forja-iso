# Forja Software for Ubuntu LTS

Gerenciador de programas inspirado no Pamac, com interface própria e backend nativo do Ubuntu (APT/DPKG).

## Política de atualização contínua

A Forja mantém a instalação na mesma série Ubuntu LTS. O gerenciador atualiza pacotes, bibliotecas, aplicações, correções de segurança e pacotes de kernel disponíveis nos repositórios configurados para a versão instalada.

- Atualização normal: `apt-get update` e `apt-get --with-new-pkgs upgrade`.
- O modo de atualização pode instalar dependências novas necessárias para atualizar pacotes, mas não remove pacotes existentes.
- Não executa `do-release-upgrade`, `full-upgrade` ou `dist-upgrade`.
- Não troca automaticamente de Ubuntu 26.04 para uma futura versão LTS.
- Os repositórios APT configurados para a série instalada são a fonte dos pacotes.
- Flatpak é opcional e usa somente os remotes já configurados pelo usuário ou pela distribuição.
- Snap não é suportado: não instalar snapd, não exibir pacotes Snap e não adicionar serviços Snap.

Isso oferece atualizações contínuas dentro da versão LTS instalada, mas não transforma o Ubuntu em uma distribuição rolling release. Cada versão LTS tem um período oficial de suporte. Ao fim desse período, continuar recebendo correções de segurança exige uma decisão explícita sobre suporte estendido ou migração in-place para outra LTS. A Forja não deve formatar o computador nem iniciar essa migração por conta própria.

## Fontes de software

- **APT:** pesquisa, instalação, remoção e atualização dos pacotes dos repositórios configurados no próprio Ubuntu.
- **Flatpak:** fonte opcional, sem adicionar Flathub ou qualquer remote automaticamente.
- **Snap:** deliberadamente fora do escopo.

O repositório Forja guarda código-fonte e artefatos de lançamento. Não é um repositório APT, espelho de pacotes ou servidor de atualizações.

## Segurança das transações

As operações privilegiadas passam por `pkexec` e pelo helper `forja-apt-transaction`. Os nomes de pacotes são validados antes de executar operações. A atualização comum usa `--with-new-pkgs`, evitando remoções automáticas durante a atualização.

## Estado de implementação

O frontend GTK4 e o indicador Ayatana ainda são protótipos. A política de transação APT foi preparada para atualizações dentro da mesma série, mas a integração com a sessão MATE, instalação no sistema, suporte completo a Flatpak, testes em Ubuntu real e validação ponta a ponta ainda precisam ser concluídos. Não considerar pronto para uma ISO de produção antes desses testes.

## Dependências

Consulte `packages.ubuntu`. Dependências relacionadas a Snap são intencionalmente excluídas.

## Licença

Este projeto é uma implementação independente inspirada no fluxo de uso do Pamac. Não incorpora código-fonte do Pamac.
