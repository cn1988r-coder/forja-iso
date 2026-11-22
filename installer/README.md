# Instalador gráfico VENOM OS

## Direção visual e fluxo

Aplicativo nativo GTK4, em Português do Brasil, com identidade visual VENOM: fundo escuro em grafite/preto, detalhes prata e azul-elétrico, cabeçalho com a marca VENOM OS e navegação vertical à esquerda. A organização é sequencial, inspirada na clareza de etapas do Archinstall, mas com interface gráfica própria.

A seleção de edição oferece **somente**:
- VENOM OS XFCE
- VENOM OS MATE

Cinnamon não faz parte das opções.

## Identidade visual das edições

- Tema GTK: Materia Dark.
- Ícones: Yaru Blue.
- Cursor: Bibata.
- Temas futuristas VENOM disponíveis como opções de Aparência.
- Papel de parede e arte de marca VENOM compartilhados.

### XFCE
XFCE/Xfwm4, Thunar e XFCE Terminal; painel inferior escuro de 40 px; Whisker Menu com símbolo V; Docklike Taskbar; quatro áreas de trabalho; indicadores discretos; rede, Bluetooth e volume; ícones Início e Lixeira no canto superior esquerdo.

### MATE
MATE/Marco, Caja e MATE Terminal; MATE Menu com símbolo V; painel inferior escuro compacto; agrupamento de janelas por aplicativo com contador e alternância/visualização; indicadores de rede, Bluetooth e volume.

## Etapas da interface

1. Boas-vindas e seleção da edição XFCE/MATE.
2. Seleção do disco de destino e modo automático/personalizado.
3. Configuração da conta local.
4. Revisão das escolhas e confirmação antes de qualquer operação destrutiva.
5. Instalação offline e conclusão/reinicialização, após implementação do backend.

Idioma padrão: Português do Brasil. Teclado padrão: Brasil ABNT2. O sistema instalado deverá iniciar no LightDM, sem autologin.

## Estado técnico atual

A interface GTK4 já oferece navegação gráfica vertical, escolha XFCE/MATE, enumeração de discos via `lsblk` em JSON e prévia validada de planos automáticos/personalizados. A prévia não grava em discos.

**A instalação real permanece bloqueada.** O backend privilegiado, particionamento/formatação, montagem, instalação offline a partir de pacotes assinados da mídia, criação de usuário, configuração de sistema, initramfs/GRUB, progresso real e tratamento seguro de falhas ainda precisam ser implementados e testados em máquinas virtuais e discos descartáveis. Não habilitar operações destrutivas antes dessa validação.

## Compilação e testes

Requisitos: GTK4 >= 4.12, json-glib e gio. Build com Meson/Ninja; os testes de parser de discos e validação de planos estão definidos no projeto.
