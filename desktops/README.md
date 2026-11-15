# Módulos de desktop

Os pacotes e as configurações de sessão ficam separados das bases do sistema operacional. Um construtor de base não deve instalar ferramentas de desktop.

## XFCE

O módulo XFCE usa um conjunto enxuto de componentes, sem instalar o grupo completo de extras. Inclui Thunar, Whisker Menu, Docklike, painel, gerenciador de janelas e plugins necessários.

- \`apply-forja-layout.sh\`: aplica painel inferior, Whisker com chama Forja, Docklike, bandeja e relógio.
- \`forja-gtk.css\`: acabamento escuro para painel e Whisker.
- \`install-branding.sh\`: instala ícone, CSS e configuração de sessão.
- Tema GTK: Materia Dark.
- Ícones: Papirus Dark com pastas cinza via Papirus Folders.
- Cursor: Bibata Modern Ice.

O Docklike é um plugin do painel XFCE, usado para favoritos, janelas abertas e indicadores discretos abaixo dos ícones. O Whisker permanece como menu funcional, com identidade visual Forja.

## MATE

O manifesto de pacotes MATE para Ubuntu é independente da base Ubuntu. A imagem Manjaro MATE utiliza o perfil próprio do construtor Manjaro.

## Bases suportadas

Somente Ubuntu LTS e Manjaro. Não manter manifestos, pacotes ou caminhos de compilação para Arch Linux.
