# Estado do Pacman e do repositório Forja

Data do registro: 19/11/2026

## Decisão de arquitetura

- O Pacman do Arch Linux continua responsável pelas atualizações normais do sistema: kernel, bibliotecas, dependências, correções e segurança.
- O repositório Forja deve conter somente pacotes próprios da distribuição.
- O repositório Forja não deve substituir nem interferir nas atualizações normais do Pacman.
- O acesso ao repositório Forja deve ser isolado e ativado somente quando o usuário executar `sudo forja`, sendo desativado ao terminar.

## Estado encontrado na branch fix/forja-calamares-stability

Foi consultado `scripts/build-forja-iso.sh`. O script grava um `/etc/pacman.conf` com os repositórios oficiais `core`, `extra` e `multilib`, usando a mirrorlist do Arch Linux.

Na árvore da branch não foram encontrados:
- um comando executável `forja`;
- uma configuração Pacman separada para o repositório Forja;
- integração que habilite temporariamente esse repositório ao executar `sudo forja`;
- configuração de URL de hospedagem e chave de assinatura do repositório.

## Conclusão

A separação das atualizações normais do Arch está prevista no script, mas a integração isolada do repositório Forja ainda não está implementada. Portanto, não considerar o repositório Forja operacional nem afirmar que `sudo forja` funciona.

## Pendências para implementação

1. Criar o comando `forja` e sua configuração Pacman isolada.
2. Garantir que o comando use o repositório Forja somente durante sua execução e não altere a configuração normal do Pacman.
3. Restringir o repositório a pacotes próprios Forja.
4. Configurar hospedagem, URL e chave de assinatura.
5. Documentar o fluxo e, em etapa futura autorizada, realizar testes reais.

Nenhuma build, validação ou geração de ISO foi executada como parte deste registro.
