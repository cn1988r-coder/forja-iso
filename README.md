# VENOM OS

Distribuição baseada diretamente no **Arch Linux oficial**, com duas edições completas: **XFCE** e **MATE**.

## Padrões do sistema

- Base e repositórios: Arch Linux oficial.
- Edições: VENOM OS XFCE e VENOM OS MATE.
- Gerenciador de sessão: LightDM, sem autologin.
- Idioma padrão: Português do Brasil (`pt_BR.UTF-8`).
- Teclado padrão: Brasil ABNT2 (`br-abnt2`).
- Áudio: PipeWire, PipeWire Pulse e WirePlumber.
- Sistema de arquivos: Btrfs, subvolumes `@` e `@home`.
- Snapshots: Timeshift e integração GRUB-Btrfs.
- Atualizações normais: `sudo pacman -Syu`.

## Instalador

A mídia inicia diretamente no instalador próprio VENOM em modo texto ncurses. Não existe sessão Live nem desktop de demonstração.

O fluxo oferece:
1. Escolha da edição XFCE ou MATE, com a arte da serpente VENOM.
2. Seleção do disco inteiro de destino.
3. Idioma e teclado.
4. Criação de usuário e senha.
5. Revisão e confirmação digitando `APAGAR`.
6. Instalação pela internet e reinicialização.

O backend implementa particionamento GPT, formatação Btrfs, subvolumes, instalação via repositórios oficiais do Arch Linux, configuração de usuário, LightDM, initramfs e GRUB. Antes de alterar o disco, sincroniza os bancos e tenta resolver todos os pacotes do manifesto; se algum não estiver disponível, deve interromper sem apagar o disco. A partição EFI é montada em /boot/efi.

**Limites atuais:** nenhuma ISO desta revisão foi compilada ou testada em USB/VM. A instalação ainda depende de internet. O manifesto inclui yaru-icon-theme, que não está nos repositórios oficiais do Arch Linux e exige resolver a origem do tema antes que o preflight permita instalar. Ferdium e Pamac também ainda não foram incorporados. Portanto, ainda não considerar a ISO pronta para uso.

## Edições e identidade visual

- Tema GTK: Materia Dark.
- Ícones: Yaru Blue.
- Cursor: Bibata Modern Ice.
- Papel de parede VENOM compartilhado.

### XFCE
XFCE/Xfwm4, Thunar e XFCE Terminal; painel inferior de 40 px, Whisker Menu com símbolo V, Docklike Taskbar, bandeja, volume e relógio; quatro áreas de trabalho.

### MATE
MATE/Marco, Caja e MATE Terminal; painel inferior único compacto, agrupamento permanente de janelas por aplicativo, bandeja, volume e relógio.

## Compilação e validação

- Projeto Meson em `installer/`.
- Testes de leitura de discos e validação do plano de instalação.
- Validação do perfil e dos scripts em `scripts/validate-arch-profile.sh`.
- Build da mídia em `scripts/build-venom-iso.sh`, protegido por autorização explícita.

Nenhuma ISO foi gerada nesta etapa. O estado de CI e o registro técnico estão em [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions) e [docs/PROJECT-CONTINUITY.md](docs/PROJECT-CONTINUITY.md).
