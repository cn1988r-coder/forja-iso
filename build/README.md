# Perfil Archiso da VENOM OS XFCE

Edição XFCE baseada no Arch Linux oficial e construída com o Archiso oficial.

## Ambiente Live
- Desktop XFCE com LightDM e configurações visuais próprias da VENOM OS.
- Idioma pt_BR.UTF-8 e teclado br-abnt2.
- NetworkManager, BlueZ, PipeWire e WirePlumber.
- Temas, ícones, cursor e papel de parede incluídos no perfil.
- Inicialização UEFI com GRUB como caminho de validação da ISO.

## Instalador
O ambiente Live inclui o instalador gráfico próprio da VENOM OS (GTK4), com backend separado para particionamento, instalação do Arch Linux, configuração do sistema e instalação do GRUB. A instalação apaga integralmente o disco selecionado após confirmação explícita.

## Manifestos
- `packages.x86_64`: ambiente Live.
- `install-packages.x86_64`: sistema instalado.
- `install-overlay/`: configurações XFCE e identidade visual aplicadas ao sistema instalado.
- `profiledef.sh`: identidade da ISO, parâmetros e modos de boot do Archiso.

## Validação
A validação estática verifica os arquivos e integrações do perfil. A validação de entrega também precisa compilar o instalador, gerar a ISO, iniciar a sessão Live em VM UEFI e testar a instalação em um disco virtual descartável. Uma compilação concluída, isoladamente, não significa que a distribuição esteja pronta.
