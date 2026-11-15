# Forja Store para Manjaro XFCE

Loja gráfica própria da Forja OS, independente do Pamac. Usa os repositórios configurados no Manjaro, o AUR por meio do yay e o Flathub por meio do Flatpak.

## Fontes e catálogo

- **Pacman / Manjaro:** pesquisa de pacotes dos repositórios sincronizados. O catálogo gráfico usa AppStream e filtra os resultados pelos pacotes realmente presentes nas bases locais do Pacman.
- **AUR:** pesquisa sob demanda com yay. O AUR é mantido pela comunidade; os PKGBUILDs devem ser revisados antes da instalação.
- **Flatpak:** pesquisa e catálogo do remoto Flathub, com o nome do remoto preservado até a instalação.
- **AppStream:** os pacotes `appstream` e `archlinux-appstream-data` fornecem o cliente e os metadados de aplicativos. Os resultados sem pacote disponível nos repositórios configurados não são oferecidos como instalação Pacman.

A seção “Todas as aplicações” reúne aplicativos gráficos AppStream disponíveis no Pacman e aplicativos publicados no Flathub. AUR é pesquisado sob demanda, pois não há um catálogo de categorias único e oficial para navegar por todo o AUR.

## Operações

- Instalar e remover pacotes dos repositórios oficiais com Pacman.
- Instalar e remover pacotes comunitários com yay, executando a compilação AUR como usuário normal e elevando somente a etapa privilegiada do Pacman por Polkit.
- Instalar Flatpaks no escopo do sistema a partir do remoto selecionado; reconhecer instalações Flatpak de usuário e sistema na interface e remover ambas quando existirem.
- Atualizar o sistema com `pacman -Syu`, depois pacotes AUR e Flatpaks do sistema. A loja também atualiza Flatpaks do usuário.
- Mostrar o resultado e a saída da operação, inclusive falhas e cancelamentos. Não apresentar falha de consulta como “tudo em dia”.

## Componentes

- `src/forja-store`: interface GTK3.
- `src/forja_store_core.py`: parsers e lógica de catálogo sem dependência de GTK, cobertos por testes unitários.
- `src/forja-pacman-transaction`: auxiliar de transações Pacman, AUR e Flatpak.
- `src/forja-pkexec-sudo`: ponte de elevação usada pelo yay.
- `src/forja-update-indicator`: indicador GTK3 de área de notificação integrado exclusivamente ao painel XFCE.
- Agente gráfico Polkit iniciado automaticamente na sessão XFCE para autenticar operações administrativas.
- `install.sh`: instala a loja, parsers, indicador, lançadores, ícones, agente Polkit e serviços de configuração do Flathub.

## Testes

Os testes automatizados cobrem os parsers AppStream/Pacman/AUR/Flatpak, os códigos de saída de consulta e a validação das transações. Eles não substituem o teste funcional em uma sessão Manjaro XFCE real, com rede, Polkit, Pacman, yay e Flathub disponíveis.

Este módulo pertence exclusivamente à edição XFCE do Forja OS sobre a base Manjaro.
