# Layout XFCE

## Objetivo visual

Desktop XFCE com aparência moderna inspirada na organização do Windows 10/11, mas com identidade visual própria. Não copiar temas, ícones, papéis de parede, cores ou marcas do BigCommunity.

## Painel único

- Um único painel horizontal na parte inferior da tela.
- Altura definida: 44 px.
- Menu Whisker no extremo esquerdo.
- Docklike Taskbar como único componente de lista/gerenciamento de aplicativos e janelas.
- Área de notificação e indicadores do sistema no lado direito.
- Indicador de volume próximo à área de notificação.
- Relógio no extremo direito.
- Sem painel superior e sem dock adicional.

## Ordem dos componentes

1. Whisker Menu.
2. Separador expansível para reservar espaço.
3. Docklike Taskbar para aplicativos fixados e janelas abertas.
4. Separador expansível.
5. Área de notificação, incluindo os ícones do NetworkManager e Blueman.
6. Indicador de volume do PulseAudio/PipeWire.
7. Relógio.

## Componentes

- Painel: xfce4-panel.
- Menu: xfce4-whiskermenu-plugin.
- Lista de aplicativos e janelas: xfce4-docklike-plugin.
- Gerenciador de janelas: xfwm4.
- Rede: network-manager-applet.
- Bluetooth: blueman-applet, com serviço bluetooth.
- Áudio: PipeWire, WirePlumber, xfce4-pulseaudio-plugin e pavucontrol.
- Login gráfico: LightDM com lightdm-gtk-greeter.

## Regra contra ícones duplicados

O Docklike Taskbar é o único componente de lista de janelas/aplicativos. Não adicionar Window Buttons, DockBarX ou outro tasklist junto dele. Os ícones de rede e Bluetooth ficam na área de notificação, separados da lista de aplicativos.

## Organização dos arquivos

- `Packages-Root`: cópia sem alterações do manifesto da base Manjaro em `../base/Packages-Root`, para deixar o perfil XFCE completo para o sistema de construção do Manjaro.
- `profile.conf`: perfil XFCE e serviços NetworkManager/Bluetooth.
- `Packages-Desktop`: seleção de pacotes do desktop e aplicativos básicos.
- `desktop-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml`: configuração inicial do painel.
- `desktop-overlay/etc/skel/.config/xfce4/panel/docklike-3.rc`: preferências iniciais do Docklike.

A base `manjaro/base/` permanece separada e sem ambiente gráfico. A edição XFCE acrescenta somente os componentes desta camada. O manifesto `Packages-Root` da edição XFCE é uma cópia do manifesto base, não uma nova base ou uma distribuição diferente.

## Estado do trabalho

A estrutura do perfil XFCE, a seleção de pacotes e a configuração inicial do painel foram escritas no repositório. Os arquivos representam a configuração pretendida, não uma comprovação de funcionamento.

Não houve compilação de pacotes, construção de ISO, execução de testes, validação em sessão gráfica ou disparo de workflows. A aparência final e o comportamento dos indicadores permanecem sem comprovação prática.
