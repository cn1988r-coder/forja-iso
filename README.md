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

O instalador próprio está em desenvolvimento em C + GTK4. A interface gráfica está em Português do Brasil e a descoberta de discos é somente leitura. Um segundo incremento adicionou um planejador declarativo para layouts automáticos UEFI/BIOS e personalizados, com validação de capacidade, tamanhos, alinhamento, partições obrigatórias e confirmação explícita.

**A instalação permanece desabilitada.** O planejador ainda não está integrado à interface e não executa operações. Faltam a revisão visual do plano, backend privilegiado, particionamento real, repositório local de pacotes oficiais assinados para instalação offline, configuração do usuário e do sistema, GRUB, progresso real, recuperação de falhas e testes em VM. A aplicação não deve ser apresentada como instalador funcional.

## Painel MATE

A configuração estática prevê:

- **Rede:** NetworkManager, `nm-applet` e Notification Area.
- **Bluetooth:** BlueZ, Blueman, `blueman-applet` e serviço Bluetooth.
- **Volume/áudio:** applet Gvc do painel MATE, PipeWire e WirePlumber, sem ícone de volume duplicado.

A validação automatizada confere pacotes oficiais, arquivos de autostart, executáveis, ícones, layout, configuração dconf e serviços no live e no sistema instalado. A confirmação visual dos três indicadores após login e reinicialização ainda depende de sessão gráfica/VM.

## Estado do projeto

Em desenvolvimento. O perfil Archiso próprio existe, o instalador C/GTK4 possui interface inicial e planejador declarativo testado, e a validação estática é separada da geração da mídia. Nenhuma ISO foi gerada nesta etapa. A compilação permanece bloqueada até autorização expressa do usuário.
