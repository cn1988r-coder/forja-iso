# Instalador VENOM OS

## Estado

Instalador gráfico GTK4 simples para a edição VENOM OS XFCE baseada no Arch Linux.

## Fluxo

1. Selecionar o disco de destino.
2. Informar nome completo, usuário e senha.
3. Confirmar que o disco selecionado será apagado.
4. O instalador cria as partições automaticamente, instala os pacotes do manifesto Arch, aplica o overlay VENOM, configura usuário, idioma, teclado, rede, LightDM e GRUB.

O instalador exige conexão com a internet e um disco de pelo menos 20 GB. Funciona com inicialização UEFI e BIOS. O pendrive da sessão Live é protegido por uma verificação adicional e não pode ser selecionado como destino.

## Segurança e limitações

- A operação destrutiva só começa depois da confirmação explícita do disco.
- O backend valida que o destino é um disco inteiro e recusa o dispositivo de boot Live.
- A senha é passada por arquivo temporário com permissão restrita, removido assim que é lido.
- O log da instalação fica em `/var/log/venom-installer.log`.
- O backend usa pacstrap e os manifestos de pacotes/configuração da própria ISO; não copia a raiz Live.
- Ainda é necessário executar testes de instalação em discos virtuais descartáveis, nos modos BIOS e UEFI, antes de considerar o instalador validado para uso geral.
