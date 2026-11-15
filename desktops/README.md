# Desktop do Forja OS

O Forja OS possui uma única interface gráfica: **XFCE**. Não há edição MATE nem seleção de ambiente durante a compilação.

## XFCE

A edição usa um conjunto enxuto de componentes, sem instalar o grupo completo de extras. Inclui Thunar, Whisker Menu personalizado, Docklike, painel inferior, gerenciador de janelas e somente os plugins necessários.

- `apply-forja-layout.sh`: aplica o painel inferior, Whisker com identidade Forja, Docklike, bandeja e relógio.
- `forja-gtk.css`: acabamento escuro para painel e Whisker.
- `install-branding.sh`: instala ícone, CSS e configuração da sessão XFCE.
- Tema GTK: Adwaita Dark (Adw GTK3 Dark), com decoração de janelas Materia Dark.
- Ícones: Papirus Dark com pastas cinza.
- Cursor: Bibata Modern Classic.

O Dockerfile em `desktops/xfce/Dockerfile` fornece validação estática e sintática do conjunto XFCE + Forja Store. Ele não gera a ISO.

## Base

A edição atual utiliza Manjaro como base técnica. O ambiente de compilação usa Docker para isolar as ferramentas de validação e montagem.
