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

## Correções de segurança e configuração regional (2026-11-22)

- A TUI não oferece mais seleções de idioma/teclado: fixa pt_BR.UTF-8 e br-abnt2.
- O backend rejeita parâmetros de idioma e teclado diferentes dos valores brasileiros e aplica America/Sao_Paulo.
- A sincronização dos bancos oficiais do Arch foi movida para antes de wipefs/particionamento, reduzindo o risco de apagar o disco quando os repositórios já estão indisponíveis.
- Comandos arch-chroot que estavam unidos por sequências literais \\n foram separados em linhas/comandos independentes.
- A habilitação do NetworkManager usa explicitamente NetworkManager.service.
- O teste do painel MATE agora consulta os manifestos reais install-packages-xfce.x86_64 e install-packages-mate.x86_64, em vez de um manifesto inexistente.
- Foi adicionado scripts/test-installer-static.sh e ele é chamado pelo validador.

**Limitação ainda aberta:** esta correção não transforma a instalação atual em offline. O backend ainda usa pacstrap e depende de rede para instalar os pacotes. O requisito de mídia com pacotes incluídos, incluindo Pamac/Ferdium empacotados, continua pendente. Não declarar ISO final nem instalação offline concluída até implementar e testar essa etapa.
