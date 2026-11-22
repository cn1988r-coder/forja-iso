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
- Tema de ícones: **Papirus Dark**.
- Cursor: **Bibata**.
- Identidade visual VENOM: base preta/escura, prata e azul elétrico discreto.

## Regra de continuidade

Esta seleção é uma decisão já tomada pelo usuário. Em especial, **Ferdium, Pamac e Timeshift são obrigatórios nas duas edições**. Não esquecer, retirar, tornar opcionais ou solicitar nova confirmação sobre esses aplicativos. Antes de declarar a seleção implementada, conferir os manifests de instalação, os pacotes disponíveis no meio offline e os testes de instalação de ambas as edições.


## Política obrigatória de instalação: sem dual boot

A VENOM OS **não oferece dual boot**. Não existe modalidade de instalação lado a lado, preservação de outro sistema operacional ou instalação em espaço livre mantendo sistemas existentes.

A única modalidade é **instalação limpa com substituição integral do sistema no disco selecionado**:
- O usuário escolhe um disco físico de destino.
- O instalador informa claramente o modelo, a capacidade e a identificação do disco.
- O instalador avisa que todos os dados e todas as partições desse disco serão apagados.
- Antes de qualquer operação destrutiva, exige confirmação explícita e inequívoca do usuário.
- Somente depois da confirmação poderá particionar e formatar o disco inteiro e instalar a VENOM OS.
- Não tocar em outros discos conectados.
- Não iniciar particionamento, formatação ou escrita no disco antes da confirmação.

Essa regra é idêntica para VENOM OS XFCE e VENOM OS MATE. Não adicionar opção de dual boot em menus, telas, documentação ou backend. A seleção de disco e a tela de revisão já existentes são apenas protótipos; enquanto o backend não estiver implementado e testado, a instalação deve permanecer bloqueada e nenhum disco pode ser alterado.


## Política obrigatória de snapshots e recuperação

- O sistema instalado usa **Btrfs** na partição raiz, com layout plano compatível com Timeshift: subvolume `@` montado em `/` e `@home` montado em `/home`.
- **Timeshift** deve operar em modo Btrfs e permanecer instalado nas duas edições.
- **GRUB permanece como único gerenciador de inicialização**. Não instalar nem configurar systemd-boot.
- Instalar `grub-btrfs` e `inotify-tools`; o serviço `grub-btrfsd` deve observar snapshots do Timeshift e atualizar o submenu de snapshots do GRUB.
- O initramfs do sistema instalado deve incluir o módulo `btrfs` via configuração do mkinitcpio.
- Não alterar o subvolume padrão do Btrfs nem gravar IDs de subvolume no fstab. Usar `subvol=@` e `subvol=@home` para permitir restauração sem IDs obsoletos.
- A integração só pode ser considerada funcional depois de criar snapshots reais em VM, verificar sua aparição no GRUB e testar o boot de um snapshot em BIOS e UEFI.
