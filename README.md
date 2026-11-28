# BuildMaker XFCE Dark

Perfil Manjaro/Arch com **XFCE** como ambiente principal e LightDM GTK Greeter para a tela de login.

## Interface
- Painel único inferior, largura total, 46 px de altura, fundo grafite e detalhes azul elétrico.
- Menu Whisker à esquerda, lançadores rápidos e lista de janelas agrupada por aplicativo. Duas janelas do mesmo programa ficam em um único botão agrupado.
- Monitor do sistema, bandeja, volume, rede, Bluetooth, energia, relógio e mostrar área de trabalho.
- Tema Materia-dark, ícones Papirus-Dark e cursor Bibata-Modern-Ice tamanho 24.
- Sem transparências, blur ou animações pesadas.
- Pamac, Firefox e Calamares incluídos no perfil.

## Personalização
Use o botão direito na barra para abrir **Painel > Adicionar novos itens**, remover itens ou abrir **Painel > Preferências do painel**. Os itens podem ser movidos e reorganizados graficamente. A lista de janelas usa agrupamento por aplicativo.

## Arquivos
- `Packages-Desktop`: dependências.
- `profile.conf`: metadados do perfil XFCE.
- `scripts/install-xfce-dark.sh`: instalação e configuração padrão.
- `desktop-overlay/etc/skel/`: preferências iniciais de novos usuários.

A ISO ainda precisa ser compilada e testada em sessão gráfica real antes de ser declarada validada.
