# Perfil Archiso da VENOM OS

A mídia usa o Archiso oficial e pacotes dos repositórios oficiais do Arch Linux. O perfil x86_64 está em `build/`.

## Conteúdo do perfil

- Boot BIOS via Syslinux e UEFI via GRUB.
- Sessão live MATE com LightDM.
- Locale exclusivo `pt_BR.UTF-8` e teclado Brasil ABNT2.
- NetworkManager, BlueZ, PipeWire e os três indicadores do painel MATE.
- Aplicação gráfica do instalador em C + GTK4, compilada somente durante uma preparação futura autorizada da mídia.

## Estado do instalador

A interface identifica discos em modo somente leitura. A biblioteca de planejamento valida propostas automáticas UEFI/BIOS e layouts personalizados, sem executar operações de disco. O botão de instalação permanece desabilitado.

Ainda não existe backend que particione, instale pacotes offline, configure usuário, sistema e GRUB ou reinicie após a instalação. A arquitetura offline prevista usa um repositório local com pacotes oficiais assinados, incluído na mídia; a preparação e a montagem desse repositório ainda precisam ser implementadas e testadas.

## Validação

A workflow de validação executa análise estática, ShellCheck, compilação do componente GTK4 e testes unitários de descoberta de discos e planejamento de partições. Ela não gera ISO.

A workflow de geração da mídia está bloqueada e apenas informa que aguarda autorização expressa do usuário. O script `scripts/build-venom-iso.sh` também recusa execução sem autorização explícita. Não iniciar uma compilação neste estágio.

## Testes ainda necessários

- Integrar o planejador à revisão visual da interface.
- Implementar e testar o backend em discos virtuais descartáveis.
- Validar instalação offline completa em BIOS e UEFI.
- Confirmar primeiro boot, conta criada, LightDM, MATE e serviços.
- Abrir uma sessão gráfica MATE e comprovar REDE, BLUETOOTH e VOLUME/ÁUDIO após login e reinicialização.

A presença de arquivos e pacotes não comprova o funcionamento gráfico ou a instalação completa.
