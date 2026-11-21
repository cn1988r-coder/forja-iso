# VENOM OS XFCE

## Arquitetura atual

A edição VENOM OS XFCE é baseada no Arch Linux oficial e construída com Archiso oficial. Os pacotes do sistema vêm dos repositórios oficiais do Arch; Pamac e sua biblioteca são compilados separadamente a partir dos PKGBUILDs do AUR. Este documento substitui as instruções históricas da antiga base Manjaro.

- Branch de desenvolvimento: `feature/venom-community-xfce`.
- Desktop: XFCE com LightDM.
- Boot: BIOS/Syslinux e UEFI/GRUB.
- Idioma: pt_BR.UTF-8; teclado: br-abnt2.
- Rede: NetworkManager; Bluetooth: BlueZ; áudio: PipeWire/WirePlumber.
- Snapshots do sistema: Timeshift, incluído no ambiente Live e no sistema instalado para criar e restaurar snapshots.
- Gerenciador gráfico de pacotes: Pamac (`pamac-aur`), compilado a partir do AUR para Arch Linux, com AUR habilitado por padrão. A instalação usa um repositório local temporário empacotado na ISO; o sistema instalado mantém somente os repositórios oficiais do Arch e acessa o AUR diretamente pelo Pamac. `base-devel` fica disponível para compilar pacotes AUR.
- Instalador: Calamares upstream 3.3.14 com módulo VENOM próprio.
- Instalação online via pacstrap/Pacman. Não copiar a raiz Live.
- Atualizações normais pelo Pacman; VENON permanece separado e manual.

## Experiência XFCE

O perfil visual oficial chama-se **VENOM Calypso**. A base é XFCE com uma barra inferior única em estilo Windows: Whisker como menu Iniciar, lista de janelas agrupadas, separador expansível, bandeja do sistema, áudio, energia, clipboard e relógio com hora/data.

A identidade visual usa Adwaita Dark para GTK, Yaru Blue exclusivamente para os ícones e Bibata Modern Ice para o cursor. O tema Yaru Blue é obtido do repositório upstream do Ubuntu durante o workflow e copiado para o ambiente Live e para o overlay instalado. O wallpaper vetorial VENOM apresenta uma serpente metálica que se morde, com brilho azul, e o botão do Whisker usa o V azul próprio da distribuição. O script `scripts/setup-xfce-windows-dark.sh` aplica o perfil sem alterar a geometria aprovada do painel inferior de 40 px.

O terminal permanece instalado para manutenção e recuperação, mas não deve ser necessário nas tarefas cotidianas nem ficar entre os favoritos do menu.

## Manifestos

- `build/packages.x86_64`: ambiente Live e ferramentas da mídia.
- `build/install-packages.x86_64`: sistema instalado.
- `build/aur-packages.x86_64`: pacotes comunitários AUR compilados pela pipeline (`libpamac-aur` e `pamac-aur`).
- `build/install-overlay/`: configurações XFCE e identidade visual copiadas pelo módulo VENOM.

O grupo oficial `xfce4-goodies` fornece os plugins adicionais do XFCE utilizados pelo painel. Verificar a composição do grupo nos repositórios oficiais antes de duplicar dependências.

## Inicialização e instalação

O root login shell no tty1 chama `/root/.automated_script.sh`, que executa `/root/venom-live-setup`. O setup cria a sessão Live e habilita NetworkManager, Bluetooth e LightDM. `VENOM_LIVE_READY` só é emitido depois que LightDM está ativo e os processos `xfce4-session`, `xfce4-panel` e `xfdesktop` estão rodando para o usuário `venom`. O teste BIOS exige a diretiva `SERIAL 0 115200` como primeira diretiva do arquivo Syslinux efetivamente carregado, para que os logs do boot sejam observáveis na porta COM1.

O Calamares prepara partições e montagem, executa o módulo VENOM para instalar pacotes oficiais via pacstrap e aplicar somente o overlay, depois configura fstab, locale, teclado, usuário, display manager, serviços, initramfs e bootloader.

## Critérios de prontidão

Não declarar a ISO pronta apenas com validação estática ou compilação. Exigir:
1. Validação estática e de sintaxe.
2. Manifestos, XML, tema e painel coerentes entre Live e instalado.
3. ISO gerada e SHA-256 registrado.
4. Boot BIOS e UEFI com `VENOM_LIVE_READY`, LightDM ativo e sessão XFCE, painel e desktop efetivamente iniciados.
5. Inspeção visual da sessão XFCE.
6. Instalação completa em VM e primeiro boot do sistema instalado.

Falhas devem ser investigadas e corrigidas antes de nova tentativa. Não remover gates para forçar aprovação.
