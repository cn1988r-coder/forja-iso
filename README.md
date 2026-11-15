# Forja OS

Projeto de uma distribuição própria com base **CachyOS**, mantendo somente os ambientes gráficos **XFCE** e **MATE**.

## Base escolhida

- **CachyOS:** base Arch Linux, com repositório e chaveiro CachyOS.
- **Construtor de ISO:** projeto oficial CachyOS Live ISO, baseado em Archiso.
- **Instalador:** Calamares da família CachyOS, a ser adaptado à identidade e ao processo de instalação do Forja OS.
- **Ambientes:** XFCE e MATE, sem KDE Plasma ou GNOME.

## Ambientes Forja

- **XFCE:** perfil próprio inspirado no BigLinux Community, com painel inferior, menu no canto inferior esquerdo, Docklike, Materia Dark, Papirus, Bibata e papel de parede Forja.
- **MATE:** perfil próprio Forja, com Materia Dark, Papirus, Bibata, papel de parede Forja e Fastfetch.

Os dois ambientes devem estar disponíveis na sessão Live e permanecer configurados após a instalação pelo Calamares.

## Estado da migração CachyOS

A definição inicial da base e o manifesto de pacotes XFCE/MATE estão em `bases/cachyos/`. A migração do pipeline antigo ainda não está concluída: `build-cloud.sh` e os workflows existentes continuam apontando para a compilação legada Manjaro/Ubuntu. Portanto, ainda não existe uma ISO Forja CachyOS pronta ou validada.

## Fontes técnicas oficiais

- CachyOS Live ISO: https://github.com/CachyOS/CachyOS-Live-ISO
- CachyOS Calamares: https://github.com/CachyOS/cachyos-calamares

## Regra de entrega

A ISO final deve ser um único arquivo `.iso`, completo e sem divisão em partes. Só será anunciada como pronta depois da compilação, verificação de conteúdo, checksum, download real e testes de inicialização/instalação que forem efetivamente executados.
