# Layout XFCE

## Arquitetura do painel

A configuração segue a arquitetura do painel XFCE usada pelo BigCommunity, adaptada à seleção de pacotes e à identidade própria da VENOM OS. A referência técnica é o projeto público comm-xfce-config, especialmente o arquivo xfce4-panel.xml e o docklike-2.rc.

- Um único painel horizontal inferior.
- Largura de 100% da tela, com ajuste automático do comprimento.
- Altura de 40 px e uma única linha.
- Painel bloqueado, sem ocultação automática.
- Whisker Menu fixo no início.
- Docklike Taskbar imediatamente depois do Whisker, como lista única de aplicativos e janelas.
- Um separador expansível depois do Docklike, ocupando o espaço livre e empurrando os indicadores para a direita.
- Área de notificação, volume, relógio, gerenciador de energia, notificações, área de transferência e mostrar área de trabalho integrados ao mesmo painel.
- Sem painel superior e sem dock separado.

## Ordem dos componentes

1. Whisker Menu.
2. Docklike Taskbar.
3. Separador expansível.
4. Plugin de notificações.
5. Área de notificação, incluindo os ícones do NetworkManager e Blueman.
6. Indicador de volume do PulseAudio/PipeWire.
7. Indicador do gerenciador de energia.
8. Área de transferência (Clipman).
9. Relógio digital.
10. Mostrar área de trabalho.

## Componentes

- Painel: xfce4-panel.
- Menu: xfce4-whiskermenu-plugin.
- Lista de aplicativos e janelas: xfce4-docklike-plugin.
- Gerenciador de janelas: xfwm4.
- Rede: network-manager-applet.
- Bluetooth: blueman-applet, com serviço bluetooth.
- Áudio: PipeWire, WirePlumber, xfce4-pulseaudio-plugin e pavucontrol.
- Energia: xfce4-power-manager e plugin de painel.
- Notificações: xfce4-notifyd e o item de painel correspondente.
- Área de transferência: xfce4-clipman-plugin.
- Login gráfico: LightDM com lightdm-gtk-greeter.

## Docklike Taskbar

O Docklike é o único componente de lista de janelas e aplicativos. Ele fica logo após o Whisker Menu e usa o espaço restante do painel antes do separador expansível. Não adicionar Window Buttons, DockBarX ou outro tasklist junto dele.

As preferências iniciais seguem o docklike-2.rc do BigCommunity: pré-visualizações ativadas, indicadores ativos/inativos no estilo 1, tamanho de ícone automático e atalhos de tecla desativados. A lista de aplicativos fixados começa vazia para não introduzir aplicativos exclusivos do BigCommunity na VENOM OS.

## Organização dos arquivos

- `Packages-Root`: cópia sem alterações do manifesto da base Manjaro em `../base/Packages-Root`, para deixar o perfil XFCE completo para o sistema de construção do Manjaro.
- `profile.conf`: perfil XFCE e serviços NetworkManager/Bluetooth.
- `Packages-Desktop`: seleção de pacotes do desktop e aplicativos básicos, incluindo Clipman.
- `desktop-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml`: configuração inicial do painel.
- `desktop-overlay/etc/skel/.config/xfce4/panel/docklike-2.rc`: preferências iniciais do Docklike, com o identificador correspondente à nova ordem dos plugins.

A base `manjaro/base/` permanece separada e sem ambiente gráfico. A edição XFCE acrescenta somente os componentes desta camada. O manifesto `Packages-Root` da edição XFCE é uma cópia do manifesto base, não uma nova base ou uma distribuição diferente.

## Estado do trabalho

A configuração foi escrita nos arquivos do perfil XFCE. Ela reproduz a estrutura declarada pelo perfil do BigCommunity, com os ajustes de posição e de aplicativos próprios da VENOM OS. Isso não comprova o funcionamento visual dos plugins.

Não houve compilação de pacotes, construção de ISO, execução de testes, validação em sessão gráfica ou disparo de workflows. A aparência final e o comportamento dos indicadores permanecem sem comprovação prática.
