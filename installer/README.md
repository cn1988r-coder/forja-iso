# Instalador VENOM OS

## Interface e fluxo

Aplicativo próprio em C + ncurses, executado diretamente na tty1. A mídia não inicia desktop Live, sessão de demonstração, GTK ou terminal de instalação genérico.

A interface oferece somente:
- VENOM OS XFCE
- VENOM OS MATE

A tela de escolha apresenta a arte da serpente VENOM. A navegação usa setas, Enter e Esc/Q.

Etapas:
1. Boas-vindas e edição.
2. Seleção do disco inteiro.
3. Idioma e teclado.
4. Conta local.
5. Revisão.
6. Confirmação explícita de apagamento e instalação.

A senha é mantida apenas em memória durante a sessão do instalador e enviada ao backend por entrada padrão, nunca como argumento de processo.

## Backend

O backend está em `build/airootfs/usr/lib/venom/install-system`. Ele valida a edição, firmware, disco, tamanho, estado somente leitura, montagens existentes e confirmação literal `APAGAR`. Depois prepara GPT, EFI ou BIOS boot, Btrfs, subvolumes `@` e `@home`, instala pacotes via repositório local, configura usuário, idioma, teclado, LightDM, initramfs e GRUB.

O build baixa pacotes e dependências das duas listas, cria um repositório local com `repo-add` e o inclui na mídia. A instalação não depende de rede.

## Edições

### XFCE
- XFCE/Xfwm4, Thunar e XFCE Terminal.
- Painel inferior de 40 px.
- Whisker Menu com ícone V VENOM.
- Docklike Taskbar, bandeja, volume e relógio.
- Quatro áreas de trabalho.
- Materia Dark, Yaru Blue, Bibata Modern Ice e papel de parede VENOM.

### MATE
- MATE/Marco, Caja e MATE Terminal.
- Painel inferior único compacto.
- Agrupamento permanente de janelas por aplicativo.
- Notification Area, volume e relógio.
- Materia Dark, Yaru Blue, Bibata Modern Ice e papel de parede VENOM.

## Testes e limitações

A compilação C e os testes unitários do TUI, parser de discos e planejador são executados pelo workflow de validação. O perfil também valida os dois manifestos, backend, scripts e arquivos de configuração.

**Ainda pendente:** teste integral do backend em VMs descartáveis BIOS e UEFI, validação visual dos dois desktops após primeiro boot e inclusão de Ferdium/Pamac no repositório offline. Nenhuma ISO foi gerada. Não usar o backend em disco com dados importantes até a validação completa.
