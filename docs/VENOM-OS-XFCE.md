# VENOM OS XFCE

## Arquitetura atual

A edição VENOM OS XFCE é baseada no Arch Linux oficial, construída com Archiso oficial e pacotes dos repositórios oficiais. Este documento substitui as instruções históricas da antiga base Manjaro.

- Branch de desenvolvimento: `feature/venom-community-xfce`.
- Desktop: XFCE com LightDM.
- Boot: BIOS/Syslinux e UEFI/GRUB.
- Idioma: pt_BR.UTF-8; teclado: br-abnt2.
- Rede: NetworkManager; Bluetooth: BlueZ; áudio: PipeWire/WirePlumber.
- Instalador: Calamares upstream 3.3.14 com módulo VENOM próprio.
- Instalação online via pacstrap/Pacman. Não copiar a raiz Live.
- Atualizações normais pelo Pacman; VENON permanece separado e manual.

## Experiência XFCE

O perfil utiliza painel inferior, menu Whisker, bandeja, áudio, energia, notificações, clipboard e relógio. O tema escuro e os ícones Papirus Dark são configurados nos perfis Live e instalado.

O terminal permanece instalado para manutenção e recuperação, mas não deve ser necessário nas tarefas cotidianas nem ficar entre os favoritos do menu.

## Manifestos

- `build/packages.x86_64`: ambiente Live e ferramentas da mídia.
- `build/install-packages.x86_64`: sistema instalado.
- `build/install-overlay/`: configurações XFCE e identidade visual copiadas pelo módulo VENOM.

O grupo oficial `xfce4-goodies` fornece os plugins adicionais do XFCE utilizados pelo painel. Verificar a composição do grupo nos repositórios oficiais antes de duplicar dependências.

## Inicialização e instalação

O root login shell no tty1 chama `/root/.automated_script.sh`, que executa diretamente o caminho indicado por `script=` ou utiliza fallback para `/root/venom-live-setup`. O setup cria a sessão Live e habilita NetworkManager, Bluetooth e LightDM. `VENOM_LIVE_READY` só é emitido após LightDM ficar ativo.

O Calamares prepara partições e montagem, executa o módulo VENOM para instalar pacotes oficiais via pacstrap e aplicar somente o overlay, depois configura fstab, locale, teclado, usuário, display manager, serviços, initramfs e bootloader.

## Critérios de prontidão

Não declarar a ISO pronta apenas com validação estática ou compilação. Exigir:
1. Validação estática e de sintaxe.
2. Manifestos, XML, tema e painel coerentes entre Live e instalado.
3. ISO gerada e SHA-256 registrado.
4. Boot BIOS e UEFI com `VENOM_LIVE_READY` e LightDM ativo.
5. Inspeção visual da sessão XFCE.
6. Instalação completa em VM e primeiro boot do sistema instalado.

Falhas devem ser investigadas e corrigidas antes de nova tentativa. Não remover gates para forçar aprovação.
