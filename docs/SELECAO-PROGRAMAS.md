# Seleção fixa de programas e aparência da VENOM OS

Esta é a referência aprovada para as edições **VENOM OS XFCE** e **VENOM OS MATE**. A seleção de aplicativos deve ser a mesma nas duas edições. Só podem variar os componentes estritamente necessários ao ambiente desktop.

## Aplicativos e componentes comuns obrigatórios

- **Ferdium**: obrigatório nas duas edições. Não remover, não tratar como opcional e não voltar a perguntar se deve ser incluído.
- **Firefox**: navegador.
- **Pamac**: loja e gerenciador de programas, instalado nas duas edições.
- **Timeshift**: backup e restauração, instalado nas duas edições.
- **NetworkManager**: gerenciamento de rede.
- **Blueman**: gerenciamento de Bluetooth.
- **PipeWire**: áudio.
- **GRUB**: carregador de inicialização.
- **LightDM**: gerenciador de login.
- Utilitários essenciais de discos, partições e sistemas de arquivos, incluindo suporte a Btrfs.
- Leitor de PDF.
- Compactador/gerenciador de arquivos compactados.
- Editor de texto.
- Monitor do sistema.

Os itens acima devem estar presentes nas duas edições instaladas. A lista real de pacotes e os artefatos offline precisam ser alinhados a esta referência; documentar a seleção não significa que todos já estejam empacotados ou testados.

## Componentes específicos de cada desktop

- **XFCE**: Thunar e XFCE Terminal, além dos componentes próprios do XFCE.
- **MATE**: Caja e MATE Terminal, além dos componentes próprios do MATE.

Não criar diferenças de aplicativos de uso geral entre as edições.

## Aparência aprovada para as duas edições

- Tema GTK: **Materia Dark Day**.
- Tema de ícones: **Yaru Blue**.
- Cursor: **Bibata**.
- Identidade visual VENOM: base preta/escura, prata e azul elétrico discreto.

## Regra de continuidade

Esta seleção é uma decisão já tomada pelo usuário. Em especial, **Ferdium, Pamac e Timeshift são obrigatórios nas duas edições**. Não esquecer, retirar, tornar opcionais ou solicitar nova confirmação sobre esses aplicativos. Antes de declarar a seleção implementada, conferir os manifests de instalação, os pacotes disponíveis no meio offline e os testes de instalação de ambas as edições.
