# VENOM OS

Distribuição independente baseada diretamente no **Arch Linux oficial**, com identidade própria e um único ambiente gráfico: **MATE + LightDM**.

## Padrões do sistema

- Base e repositórios: Arch Linux oficial.
- Idioma: Português do Brasil (`pt_BR.UTF-8`).
- Teclado: Brasil ABNT2 (`br-abnt2`).
- Desktop: MATE.
- Gerenciador de sessão: LightDM.
- Áudio: PipeWire, PipeWire Pulse e WirePlumber.
- Atualizações do sistema: `sudo pacman -Syu`.
- VENON: ferramenta separada e manual para atualizações próprias.

## Instalador VENOM

O instalador próprio está em desenvolvimento em C + GTK4. O primeiro incremento entrega a interface gráfica em Português do Brasil e a descoberta de discos em modo somente leitura, com testes unitários do parser.

**A instalação permanece desabilitada.** Ainda faltam o backend privilegiado, particionamento automático e personalizado, repositório local de pacotes oficiais para instalação offline, configuração do usuário e do sistema, GRUB, progresso real e testes em VM. A interface atual não altera discos e não deve ser apresentada como instalador funcional.

## Painel MATE

A configuração estática prevê:

- **Rede:** NetworkManager, `nm-applet` e Notification Area.
- **Bluetooth:** BlueZ, Blueman, `blueman-applet` e serviço Bluetooth.
- **Volume/áudio:** applet Gvc do painel MATE, PipeWire e WirePlumber, sem ícone de volume duplicado.

Os pacotes, arquivos de autostart, layout e serviços são verificados por scripts. A confirmação visual dos três indicadores após login e reinicialização ainda depende de sessão gráfica/VM.

## Estado do projeto

Em desenvolvimento. O perfil Archiso existe, o instalador C/GTK4 está no primeiro incremento e a validação estática é separada da geração da mídia. Nenhuma nova ISO foi gerada neste trabalho. A compilação permanece bloqueada até autorização expressa do usuário.
