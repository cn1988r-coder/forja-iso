# Forja Store para Manjaro

Loja gráfica própria da Forja OS. É independente do Pamac e utiliza o Pacman nativo do Manjaro para instalar, remover e atualizar programas.

## Repositórios e atualizações

- **Pacotes Manjaro:** utiliza somente os repositórios e a lista de espelhos configurados pelo Manjaro (`pacman` e `pacman-mirrors`). A Forja não é um espelho de pacotes.
- **Aplicativos Flatpak:** utiliza o Flathub oficial. Nenhum repositório próprio da Forja é adicionado.
- Atualizações do sistema executam `pacman -Syu`, seguidas das atualizações Flatpak do sistema.
- A verificação de atualizações usa `checkupdates` e a listagem de atualizações do Flatpak. Não utiliza `pacman -Sy` isoladamente.

## Componentes

- `forja-store`: aplicativo próprio GTK4 com telas Visão geral, Instalados, Pesquisa e Atualizações.
- `forja-update-indicator`: indicador Ayatana para painéis XFCE e MATE.
- `forja-pacman-transaction`: auxiliar privilegiado restrito para transações Pacman e Flatpak.
- Ícone e identidade visual próprios da Forja Store.

Este módulo é exclusivo da base Manjaro. A base Ubuntu utiliza o módulo separado `forja-pamac-ubuntu/`.
