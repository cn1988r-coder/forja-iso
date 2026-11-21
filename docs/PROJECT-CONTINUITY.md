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

## Próximos passos

1. Executar e registrar a validação estática, compilação C/GTK4 e testes unitários.
2. Concluir os testes automatizados do painel e revisar qualquer falha.
3. Implementar o backend privilegiado e o plano de partições seguro.
4. Implementar o repositório local assinado e a instalação offline.
5. Criar VMs descartáveis BIOS/UEFI para testar a instalação e o primeiro boot.
6. Validar os três indicadores MATE após login e reinicialização.
7. Aguardar autorização expressa antes de qualquer geração de ISO.
