# Forja Store para Manjaro XFCE

Loja gráfica própria da Forja OS. A interface GTK3 herda o tema GTK ativo do sistema, seja escuro ou claro. O realce de passagem do mouse é neutro e discreto, sem superfícies fixas cinzas nem cores de ação impostas.

## Backend e fontes

- **Pamac CLI / libpamac:** backend de pesquisa, instalação, remoção, consulta de pacotes instalados e atualização dos repositórios Manjaro.
- **AUR:** operações encaminhadas ao próprio Pamac, com suporte de compilação AUR. O AUR é mantido pela comunidade; os PKGBUILDs devem ser revisados antes da instalação.
- **Flatpak:** pesquisa e instalação pelo Flatpak, com Flathub configurado para o sistema. A loja consulta instalações de usuário e sistema.
- **AppStream:** catálogo de aplicativos gráficos e metadados de nomes, descrições e ícones.

## Operações

- Instalar e remover pacotes oficiais pelo Pamac.
- Compilar/instalar e remover pacotes AUR pelo Pamac.
- Atualizar repositórios oficiais e pacotes AUR em uma única transação: `pamac upgrade --aur`.
- Atualizar Flatpaks do sistema e do usuário pela própria Forja Store.
- Mostrar o resultado da operação, incluindo falhas e cancelamentos.
- O indicador XFCE consulta Pamac e Flatpak periodicamente e abre a Forja Store na seção de atualizações.

O Pamac deve ser executado como usuário da sessão. Não o execute com `sudo` ou `pkexec`: o próprio Pamac solicita a autorização necessária. As operações Flatpak usam Polkit quando exigem privilégios administrativos.

## Componentes

- `src/forja-store`: interface GTK3.
- `src/forja_store_core.py`: parsers de catálogo e atualizações.
- `src/forja-pacman-transaction`: adaptador que encaminha as transações ao Pamac e Flatpak; não implementa um gerenciador de pacotes próprio.
- `src/forja-update-indicator`: indicador GTK3 integrado exclusivamente ao painel XFCE.
- `install.sh`: instala a loja, indicador, lançadores, ícones, agente Polkit e configuração do Flathub.

## Validação

Os testes automatizados verificam parsers e encaminhamento das transações. Eles não substituem um teste funcional em uma sessão Manjaro XFCE real, com Pamac, Polkit, rede e Flathub disponíveis.

Esta loja pertence exclusivamente à edição XFCE do Forja OS sobre a base Manjaro.
