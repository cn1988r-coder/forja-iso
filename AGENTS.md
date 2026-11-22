# AGENTS.md

## Produto e arquitetura

- Nome: VENOM OS.
- Base única: Arch Linux oficial e repositórios oficiais.
- Duas edições completas: XFCE e MATE. Não adicionar Cinnamon.
- A mídia inicia diretamente no instalador TUI ncurses na tty1. Não existe Live desktop, sessão de demonstração ou instalador GTK.
- LightDM no sistema instalado, sem autologin.
- Idioma padrão: Português do Brasil (`pt_BR.UTF-8`); teclado padrão Brasil ABNT2.
- Sistema instalado em Btrfs com subvolumes `@` e `@home`, Timeshift e GRUB-Btrfs.
- Atualizações normais via Pacman. Não criar atualização automática.

## Repositório e branch

- Repositório: `cn1988r-coder/forja-iso`.
- Branch ativa de trabalho: `feature/venom-graphical-installer`.
- Confirmar HEAD e arquivos atuais antes de editar.
- Não alterar `main`, outras branches ou repositórios.
- Fazer commits pequenos, claros e verificáveis.

## Instalador

- Código da interface: C + ncurses.
- Tela de escolha de edição deve manter a arte da serpente VENOM e oferecer somente XFCE/MATE.
- Fluxo: edição, disco inteiro, idioma/teclado, conta, revisão, confirmação literal `APAGAR`, instalação e reinicialização.
- A senha não pode ser passada em argumentos de processo nem gravada em disco.
- O backend está em `build/airootfs/usr/lib/venom/install-system`.
- A instalação é limpa, sem dual boot e sem particionamento manual.
- Nenhuma escrita em disco antes da revisão e confirmação explícita.
- Validar novamente disco, tamanho, estado somente leitura, montagens e mídia de boot antes de apagar.
- Instalação offline por repositório local de pacotes e dependências incluídos na ISO.
- Não declarar backend funcional sem testes completos em VMs descartáveis BIOS e UEFI.

## Aplicativos e desktops

- Manter a mesma seleção de aplicativos nas duas edições, exceto componentes próprios de cada desktop.
- XFCE: Thunar, XFCE Terminal, Whisker Menu, Docklike, bandeja, volume e relógio.
- MATE: Caja, MATE Terminal, Marco, painel inferior único, janelas agrupadas por aplicativo, bandeja, volume e relógio.
- Tema padrão: Materia Dark; ícones Yaru Blue; cursor Bibata; papel de parede VENOM.
- Não declarar Ferdium ou Pamac incluídos até que os pacotes e dependências estejam efetivamente no repositório offline.

## Builds e validação

- Compilar e testar C, Meson, scripts, manifestos e configuração estática é permitido.
- Não executar particionamento em discos reais.
- Testes destrutivos futuros devem usar imagens descartáveis e VMs isoladas.
- Não gerar/publicar ISO nem iniciar build de mídia sem autorização expressa.
- Nunca afirmar que a ISO, o boot ou os dois desktops funcionam sem executar e registrar os testes correspondentes.
- Atualizar `docs/PROJECT-CONTINUITY.md` com branch, HEAD, commits, testes reais, falhas, pendências e confirmação de que nenhuma ISO foi gerada.
