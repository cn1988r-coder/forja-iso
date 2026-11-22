# VENOM OS

Distribuição baseada diretamente no **Arch Linux oficial**, com duas edições: **XFCE** e **MATE**.

## Padrões do sistema

- Base e repositórios: Arch Linux oficial.
- Edições: VENOM OS XFCE e VENOM OS MATE.
- Gerenciador de sessão instalado: LightDM, sem autologin.
- Idioma: Português do Brasil (`pt_BR.UTF-8`).
- Teclado: Brasil ABNT2 (`br-abnt2`).
- Áudio: PipeWire, PipeWire Pulse e WirePlumber.
- Sistema de arquivos: Btrfs, subvolumes `@` e `@home`.
- Snapshots: Timeshift e integração GRUB-Btrfs.

## Único instalador oficial

A VENOM OS possui **um único instalador: o instalador próprio em modo texto (TUI), escrito em C com ncurses**.

- A mídia inicia diretamente no instalador pela tty1.
- Não existe sessão Live, desktop de demonstração ou instalador gráfico.
- A navegação é feita por teclado, com setas, Enter e Esc.
- As únicas edições disponíveis são XFCE e MATE.

### Fluxo

1. Boas-vindas e escolha entre XFCE e MATE.
2. Seleção do disco inteiro de destino.
3. Criação de usuário e senha.
4. Revisão da instalação.
5. Confirmação explícita digitando `APAGAR`.
6. Instalação e reinicialização.

A instalação usa o repositório local de pacotes incluído na mídia, preparado para as duas edições. O backend configura GPT, EFI ou BIOS, Btrfs, subvolumes, usuário, idioma, teclado, LightDM, initramfs e GRUB.

## Edições e identidade visual

- Tema GTK: Materia Dark.
- Ícones: Papirus Dark.
- Cursor: Bibata Modern Ice.
- Papel de parede VENOM compartilhado.

### XFCE
XFCE/Xfwm4, Thunar e XFCE Terminal; painel inferior, Whisker Menu com símbolo V, Docklike Taskbar, bandeja, volume e relógio.

### MATE
MATE/Marco, Caja e MATE Terminal; painel inferior único compacto, agrupamento permanente de janelas por aplicativo, bandeja, volume e relógio.

## Compilação e validação

- Código do único instalador em `installer/src/`.
- Projeto Meson em `installer/`.
- Testes unitários do TUI, leitura de discos e planejamento.
- Validação do perfil em `scripts/validate-arch-profile.sh`.
- Geração da mídia em `scripts/build-venom-iso.sh`.

A compilação automatizada não substitui o teste real de inicialização BIOS/UEFI e a instalação completa em máquina virtual. A ISO só deve ser considerada pronta depois dessas verificações.
