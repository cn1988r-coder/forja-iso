# BuildMaker LXQt Dark

Perfil Manjaro/Arch com **LXQt** como ambiente principal e Openbox como gerenciador de janelas leve. Não instala KDE Plasma, SDDM, XFCE ou MATE como ambientes.

## Interface pronta no perfil
- Painel LXQt inferior, largura total e 40 px, com Fancy Menu, lista de janelas, bandeja, volume, rede, relógio e mostrar área de trabalho.
- Menu nativo Fancy Menu com pesquisa, categorias e favoritos, usando os lançadores .desktop instalados.
- Tema GTK Materia-dark, estilo Qt Kvantum/KvArcDark, ícones Papirus-Dark e cursor Bibata-Modern-Ice.
- LightDM com LightDM GTK Greeter, fundo grafite escuro. SDDM desabilitado.
- Sem compositor, blur, transparência ou animações pesadas.
- Pamac, Firefox e Calamares incluídos no perfil.

## Arquivos
- `Packages-Desktop`: dependências do desktop.
- `profile.conf`: metadados LXQt.
- `desktop-overlay/etc/skel/`: configurações padrão da sessão live e de novos usuários.
- `scripts/install-lxqt-dark.sh`: aplicação idempotente do perfil em Manjaro/Arch.

## Aplicar
`sudo bash scripts/install-lxqt-dark.sh`

O script instala os pacotes, configura o LightDM GTK Greeter e semeia as configurações do desktop. A ISO ainda precisa ser compilada e a sessão precisa passar por teste gráfico real antes de ser declarada validada.
