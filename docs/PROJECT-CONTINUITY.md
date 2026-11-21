# Atualização de continuidade em 21/11/2026 20:50 BRT

## Referência desta execução

- Repositório: `cn1988r-coder/forja-iso`.
- Branch exclusiva: `optimize/venom-iso-size`.
- HEAD-base antes deste incremento: `76abc033ab48ad37349ac8a1bd25c701829dd55b`.
- HEAD de implementação antes desta atualização documental: `1a51ed7d7d9f2c0c918f6976d71ec9ddf2190150` (inclui reforço da verificação Wi-Fi/Ethernet).
- Nenhuma outra branch foi alterada.

## Alterações de código

- Adicionado `installer/src/plan.h` e `installer/src/plan.c`: modelo declarativo de plano de partições, sem chamadas privilegiadas ou escrita em disco.
- Plano automático UEFI: GPT, EFI FAT32 de 1 GiB e raiz ext4; plano automático BIOS: GPT, partição BIOS GRUB de 2 MiB e raiz ext4.
- Plano personalizado inicial: EFI/BIOS boot fixo, tamanho de raiz definido em GiB e swap opcional. Validação de capacidade, alinhamento de 1 MiB, tamanho mínimo, duplicatas, papel das partições, caminho de dispositivo e discos somente leitura.
- Adicionados `installer/tests/test-plan.c` e alvo Meson próprio para testes do planejador.
- A interface GTK4 agora oferece seleção de modo automático/personalizado, detecta UEFI/BIOS e apresenta uma prévia em Português do Brasil com partições, tamanhos, sistemas de arquivos e pontos de montagem.
- O botão “Instalar VENOM OS” continua desabilitado. O planejador e a prévia não executam particionamento, formatação, montagem ou escrita.
- Atualizada a API de CSS GTK4 para `gtk_css_provider_load_from_string`, removendo a chamada depreciada identificada na primeira compilação.
- Atualizados `AGENTS.md`, `README.md`, `build/README.md` e `installer/README.md` para descrever somente o que existe.

## Commits desta execução

- `65122c6a0ed86581aee346cf42514d93c2f6fdaf`: cabeçalho do planejador.
- `3349a1e3ab5335b8b3c33cd1ceef0617e3377713`: implementação declarativa.
- `40d86a80cd9cb13ae7cad09901ee316ed9007989`: testes do planejador.
- `4912c2620448db119a6e9c26fa099c8452d63d79` e `c11d5f08cb1952a8fbf3f69a5b3a76065f3b11c3`: correção e teste do modo automático.
- `2b1f41fa0d50d3c8a5d85447e3c16930f2aee308`: integração Meson.
- `6a8c73e9b376e75a1727d12a5dc758ac6f8299bf`: validações estáticas do planejador.
- `87490092e8e24c81b63c17f9f2fb57fd5afe62eb`: documentação do primeiro incremento do planejador.
- `fc0ca6f57f8337ae5db80ceef36e623b169ff2fb`: API GTK4 de CSS atual.
- `a1b9d1bf43b8179bdf05edcd03ce4bed46e6c9ba` e `791662d326dff87cc09a0ad3391750bc2437f3be`: prévia gráfica e correção de escapes/seleção inicial.
- Commits de documentação e continuidade subsequentes permanecem nesta mesma branch.

## Validação realmente executada

- Workflow de validação #44962821058, commit `87490092e8e24c81b63c17f9f2fb57fd5afe62eb`: **sucesso**, incluindo o primeiro modelo de planos.
- Workflow de validação #44963213856, commit `791662d326dff87cc09a0ad3391750bc2437f3be`: **sucesso**, incluindo a prévia gráfica automática/personalizada, compilação C/GTK4 sem o aviso de API CSS depreciada, testes Meson e ShellCheck.
- Perfil Archiso, locale exclusivo `pt_BR.UTF-8`, teclado ABNT2, manifestos oficiais e bloqueio da mídia: aprovados.
- Varredura de referências operacionais proibidas nas áreas do produto/documentação: aprovada.
- Teste estático do painel MATE: aprovado.
- Compilação C/GTK4: aprovada.
- Testes Meson: 2 executáveis aprovados (parser de discos e planejador de partições).
- ShellCheck dos scripts ativos: aprovado.
- A primeira compilação registrou aviso de API GTK4 depreciada em `main.c`; a chamada foi substituída por `gtk_css_provider_load_from_string`. A segunda validação confirmou a compilação sem esse aviso.

## Painel MATE: resultados individuais

1. **REDE:** validação estática aprovada. Pacote `network-manager-applet`, `nm-applet`, autostart oficial, ícones de conexão, Notification Area e serviço NetworkManager conferidos no perfil live e no sistema instalado.
2. **BLUETOOTH:** validação estática aprovada. BlueZ, Blueman, `blueman-applet`, `blueman-manager`, autostart, ícone de bandeja, Notification Area e serviço Bluetooth conferidos.
3. **VOLUME/ÁUDIO:** validação estática aprovada. Applet Gvc do `mate-media`, biblioteca e controle de dispositivos, PipeWire, PipeWire Pulse, WirePlumber, sockets, ícones Papirus e desativação do ícone de status duplicado conferidos.

**Reforço recente da REDE:** o teste agora exige também os ícones de sinal Wi-Fi (`nm-signal-00.png` e `nm-signal-100.png`) e o executável `nm-connection-editor`, além do ícone Ethernet e de desconexão. Os caminhos foram conferidos na lista oficial de arquivos do pacote Arch. Essa ampliação entrou no commit `1a51ed7d7d9f2c0c918f6976d71ec9ddf2190150` após a última execução de CI aprovada e ainda aguarda nova execução automatizada.

**Pendente para os três:** não houve sessão gráfica/VM com login e reinicialização. Portanto, visibilidade e funcionamento real dos indicadores não estão comprovados.

## Pendências e bloqueios

- O modo personalizado atual é inicial: não é ainda um editor completo de partições arbitrárias.
- Não existe backend privilegiado; nenhuma operação de escrita está implementada.
- Repositório local de pacotes oficiais assinados e instalação offline ainda não implementados.
- Criação de usuário, configuração do destino, initramfs, GRUB, progresso real, cancelamento e recuperação ainda pendentes.
- Nenhuma VM de instalação BIOS/UEFI foi executada.
- Nenhuma sessão gráfica MATE foi executada para comprovar os três indicadores após reinicialização.

## Segurança e mídia

- Nenhuma operação de particionamento ou formatação foi executada.
- Nenhuma workflow de geração de ISO foi disparada.
- Nenhuma ISO foi iniciada ou gerada.
- A workflow de mídia continua bloqueada e o script exige autorização explícita.

## Próximos passos

1. Confirmar na workflow de validação a compilação da interface com a prévia gráfica e os testes atualizados.
2. Expandir o editor personalizado para plano completo e revisão de todas as operações destrutivas.
3. Implementar o backend privilegiado separado, com confirmação vinculada ao disco/plano.
4. Implementar o repositório local assinado e a instalação offline por pacotes oficiais.
5. Testar em VMs descartáveis BIOS e UEFI.
6. Validar visualmente REDE, BLUETOOTH e VOLUME/ÁUDIO após login e reinicialização MATE.
7. Aguardar autorização expressa antes de qualquer geração de ISO.

---

# Continuidade técnica da VENOM OS

Atualizado em 21/11/2026 (BRT).

## Referência desta execução

- Repositório: `cn1988r-coder/forja-iso`.
- Branch autorizada: `optimize/venom-iso-size`.
- HEAD-base confirmado antes das alterações: `a0f50214587a0e4947383528bf9c221c2f5abe90`.
- Commit do primeiro incremento C/GTK4: `f220ccd224b444779fbf67405a5e3a00904ac398`.
- Commit de configuração estática do painel MATE: `dcc2a58d4dfc0a45e6b6dfdc7cefab701b79548c`.

## Arquitetura vigente

- Base única: Arch Linux oficial.
- Desktop único: MATE + LightDM.
- Idioma único: Português do Brasil (`pt_BR.UTF-8`).
- Teclado padrão: Brasil ABNT2 (`br-abnt2`).
- Perfil de mídia: Archiso oficial em `build/`.
- Instalador próprio: C + GTK4.
- Instalação final prevista: offline, por repositório local com pacotes oficiais assinados.
- Atualizações normais: Pacman. VENON continua separado e manual.
- Nenhuma ISO pode ser gerada sem autorização expressa posterior.

## Instalador: primeiro incremento

Implementado:
- Aplicação GTK4 com navegação gráfica em Português do Brasil.
- Descoberta de discos por `lsblk`, sem executar operações de escrita.
- Parser JSON que filtra dispositivos do tipo disco e preserva tamanho, modelo e estado somente leitura.
- Testes unitários para filtragem de partições, estado somente leitura e respostas JSON inválidas.
- Entrada de menu própria para a aplicação.
- Removidos os arquivos de configuração, módulos, branding e dependências do instalador anterior.
- Script de mídia protegido por verificação explícita de autorização e preparado para compilar/instalar a aplicação em um perfil temporário.

Ainda pendente:
- Backend privilegiado separado da interface.
- Instalação automática e particionamento personalizado.
- Plano de partições revisável e confirmação destrutiva.
- Repositório local de pacotes oficiais assinados na mídia e instalação completamente offline.
- Criação de usuário, configuração do destino, fstab, locale, teclado, MATE, LightDM, serviços, initramfs e GRUB.
- Progresso real, logs, recuperação de falhas, cancelamento seguro e reinicialização.
- Testes completos em VMs BIOS e UEFI.

A aplicação atual é um protótipo gráfico de navegação e descoberta de discos somente leitura. O botão de instalação permanece desabilitado. Não declarar o instalador funcional.

## Auditoria estática do painel MATE

Pacotes e arquivos de autostart confirmados nas listas oficiais de arquivos do Arch Linux:
- `network-manager-applet` fornece `/usr/bin/nm-applet` e `/etc/xdg/autostart/nm-applet.desktop`.
- `blueman` fornece `/usr/bin/blueman-applet` e `/etc/xdg/autostart/blueman.desktop`.
- `mate-media` fornece `GvcAppletFactory::GvcApplet`, `mate-volume-control` e um autostart separado para o ícone de status de volume.
- O layout VENOM mantém uma Notification Area e um applet Gvc. O autostart separado do ícone de volume é desativado para evitar duplicidade.
- `pipewire-audio`, `pipewire-pulse` e `wireplumber` estão incluídos nos manifestos live e do sistema instalado.
- `NetworkManager.service` e `bluetooth.service` são habilitados na sessão live. O overlay do sistema instalado inclui os links de habilitação correspondentes.

Resultados individuais:
1. REDE: configuração estática presente; validação visual/funcional após login e reinicialização pendente.
2. BLUETOOTH: configuração estática presente; validação visual/funcional após login e reinicialização pendente.
3. VOLUME/ÁUDIO: applet Gvc e pilha PipeWire presentes, ícone de status duplicado desativado; validação visual/funcional após login e reinicialização pendente.

O teste estático não comprova que os ícones aparecem ou que os dispositivos funcionam numa sessão gráfica. Nenhuma VM/sessão MATE foi executada nesta etapa.

## Validações e bloqueios

- A validação estática e a compilação do instalador C/GTK4 devem ocorrer pela workflow específica de validação.
- Nenhum workflow de geração de ISO foi executado.
- Nenhuma ISO foi iniciada ou gerada.
- Não foi executado particionamento, formatação ou instalação em disco real.
- A comprovação visual do painel e a instalação completa permanecem pendentes por falta de sessão gráfica/VM nesta execução.

## Registro da primeira validação automatizada

- Run `44959078183`, commit `e93b2fb09ba8d9a10c4590b537982eb65c72726a`: falhou no teste estático do painel.
- O perfil Arch, os manifestos de pacotes, locale, ABNT2, links de serviços e bloqueio da mídia passaram.
- A falha ocorreu porque o container de validação não tinha `cmp`, a busca recursiva atravessou links absolutos do overlay e ainda existiam arquivos de uma edição histórica fora do escopo Arch/MATE. A compilação C/GTK4 não chegou a ser executada.
- Correções preparadas: comparação de layouts por SHA-256, varredura apenas de arquivos regulares, verificação explícita dos executáveis/autostarts/serviços dos pacotes oficiais e remoção dos arquivos/workflows legados desta branch.
- Nenhuma ISO foi iniciada ou gerada.

## Próximos passos

1. Executar e registrar a validação estática, compilação C/GTK4 e testes unitários.
2. Concluir os testes automatizados do painel e revisar qualquer falha.
3. Implementar o backend privilegiado e o plano de partições seguro.
4. Implementar o repositório local assinado e a instalação offline.
5. Criar VMs descartáveis BIOS/UEFI para testar a instalação e o primeiro boot.
6. Validar os três indicadores MATE após login e reinicialização.
7. Aguardar autorização expressa antes de qualquer geração de ISO.
