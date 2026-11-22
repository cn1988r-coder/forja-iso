# Continuidade técnica VENOM OS

## Correção de arquitetura: repositórios de pacotes

A VENOM OS utiliza exclusivamente os repositórios oficiais do Arch Linux. Não existe repositório de pacotes VENOM, banco `venom.db`, espelho local ou bundle de pacotes na ISO.

- `build/pacman.conf` e `build/airootfs/etc/pacman.conf` apontam para o mirror oficial `geo.mirror.pkgbuild.com`.
- O instalador sincroniza os bancos oficiais com `pacman -Sy` antes de qualquer operação destrutiva.
- O backend usa `pacstrap -C /etc/pacman.conf -K` e instala os manifestos XFCE/MATE diretamente dos repositórios oficiais.
- A ISO contém apenas os manifestos e os arquivos do instalador/configuração, não um repositório de pacotes.
- A instalação exige internet funcional. Sem conexão, o instalador deve parar antes de particionar/apagar o disco.
- Não usar `repo-add`, `pacman -Sw` nem `file:///usr/share/venom`.

## Edições

Duas edições completas: VENOM OS XFCE e VENOM OS MATE. A tela de escolha mantém a ilustração da serpente. O instalador é TUI ncurses e inicia diretamente na tty, sem desktop Live.

## Validação pendente

A alteração do caminho de instalação ainda precisa passar pelo CI. Depois disso, é necessário testar instalação completa em VMs descartáveis BIOS e UEFI, incluindo falha de rede antes da confirmação destrutiva, instalação dos dois desktops e primeiro login. Nenhuma ISO foi gerada nesta alteração.