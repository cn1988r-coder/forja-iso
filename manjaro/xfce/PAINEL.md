# Layout XFCE

## Objetivo visual

Desktop XFCE com aparência moderna inspirada na organização do Windows 10/11, mas com identidade visual própria. Não copiar temas, ícones, papéis de parede, cores ou marcas do BigCommunity.

## Painel único

- Um único painel horizontal na parte inferior da tela.
- Altura definida: 44 px.
- Menu Whisker no extremo esquerdo.
- Docklike Taskbar como único componente de lista/gerenciamento de aplicativos e janelas.
- Área de notificação e indicadores do sistema no lado direito.
- Relógio no extremo direito.
- Sem painel superior e sem dock adicional.

## Componentes

- Painel: xfce4-panel.
- Menu: xfce4-whiskermenu-plugin.
- Lista de aplicativos e janelas: xfce4-docklike-plugin.
- Gerenciador de janelas: xfwm4.
- Indicadores: network-manager-applet, xfce4-pulseaudio-plugin e blueman.

## Regra contra ícones duplicados

O Docklike Taskbar deve ser o único plugin de lista de janelas/aplicativos no painel. Não adicionar Window Buttons, DockBarX ou outro tasklist junto dele. Os ícones de rede, volume e Bluetooth permanecem na área de notificação/indicadores, separados da lista de aplicativos.

## Estado da implementação

Este diretório registra o perfil e a seleção de pacotes da edição XFCE. A configuração visual efetiva do painel ainda precisa ser implementada e validada em ambiente Manjaro compatível. Nenhuma ISO foi construída e nenhum teste técnico foi executado.
