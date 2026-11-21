# Perfil Archiso da VENOM OS

A mídia usa o Archiso oficial e pacotes dos repositórios oficiais do Arch Linux. O perfil x86_64 está em `build/`.

## Conteúdo do perfil

- Boot BIOS via Syslinux e UEFI via GRUB.
- Sessão live MATE com LightDM.
- Locale exclusivo `pt_BR.UTF-8` e teclado Brasil ABNT2.
- NetworkManager, BlueZ, PipeWire e os três indicadores do painel MATE.
- Interface do instalador C + GTK4 compilada durante uma futura preparação autorizada da mídia.

## Estado do instalador

A interface atual identifica discos em modo somente leitura. O botão de instalação está desabilitado. Ainda não existe backend capaz de particionar, instalar pacotes offline, configurar usuário, sistema e GRUB ou reiniciar após a instalação.

A arquitetura offline prevista usa um repositório local com pacotes oficiais assinados, incluído na mídia. A preparação e a montagem desse repositório ainda precisam ser implementadas e testadas.

## Validação

A workflow de validação executa análise estática, ShellCheck, compilação do componente GTK4 e testes unitários. Ela não gera ISO.

A workflow de geração da mídia está bloqueada e apenas informa que aguarda autorização expressa do usuário. O script `scripts/build-venom-iso.sh` também recusa execução sem autorização explícita. Não iniciar uma compilação neste estágio.

## Testes ainda necessários

- Testar o backend em discos virtuais descartáveis.
- Validar instalação offline completa em BIOS e UEFI.
- Confirmar primeiro boot, conta criada, LightDM, MATE e serviços.
- Abrir uma sessão gráfica MATE e comprovar REDE, BLUETOOTH e VOLUME/ÁUDIO após login e reinicialização.

A presença de arquivos e pacotes não comprova o funcionamento gráfico ou a instalação completa.
