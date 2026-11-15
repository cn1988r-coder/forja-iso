# Módulos de desktop

Os pacotes e as configurações de sessão ficam separados das bases do sistema operacional. Um construtor de base não deve instalar ferramentas de desktop.

## XFCE

O módulo XFCE mantém manifestos independentes para **Manjaro** e **Ubuntu LTS**. Inclui XFCE, Whisker Menu, Docklike e plugins selecionados, além de Firefox, Materia Dark, Papirus e Bibata como escolhas de desktop.

`apply-mint-layout.sh` configura a sessão XFCE com painel inferior, Whisker Menu à esquerda, lista de janelas, bandeja do sistema, relógio e controle de mostrar área de trabalho.

## MATE

O manifesto de pacotes MATE para Ubuntu é independente da base Ubuntu. A imagem Manjaro MATE utiliza o perfil próprio do construtor Manjaro.

## Bases suportadas

Somente Ubuntu LTS e Manjaro. Não manter manifestos, pacotes ou caminhos de compilação para Arch Linux.
