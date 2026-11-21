# Instalador VENOM OS

O instalador está sendo desenvolvido como aplicação nativa em C com GTK4. A interface é exclusiva em Português do Brasil e apresenta Brasil ABNT2 como teclado padrão, sem seletor de outros idiomas ou países.

## Incrementos implementados

### Interface e descoberta de discos
- Aplicação GTK4 com navegação gráfica entre as etapas iniciais.
- Enumeração de discos por `lsblk`, com leitura estruturada da saída JSON.
- Identificação de caminho, modelo, capacidade e estado somente leitura.
- Interface de seleção de modo automático ou personalizado.
- Detecção do firmware da sessão atual (UEFI ou BIOS) para montar a prévia correspondente.

### Prévia gráfica e planejador declarativo
- Modo automático UEFI: tabela GPT, partição EFI FAT32 de 1 GiB e raiz ext4 ocupando o espaço disponível, preservando uma margem de 4 MiB.
- Modo automático BIOS: tabela GPT, partição BIOS de 2 MiB para o GRUB e raiz ext4.
- Modo personalizado inicial: o usuário define o tamanho da raiz em GiB e pode incluir swap opcional. A partição de boot é proposta automaticamente e tem tamanho fixo nesta etapa.
- Validação de tamanhos mínimos, alinhamento de 1 MiB, duplicatas, funções de partição, capacidade total, caminhos de dispositivo e discos somente leitura.
- Prévia em Português do Brasil com tipo de partição, tamanho, sistema de arquivos e ponto de montagem.

**Limite de segurança:** o planejador apenas cria e valida uma estrutura em memória. Não chama ferramentas de particionamento, não formata, não monta e não escreve em dispositivos. O botão de instalação permanece desabilitado.

## Testes automatizados

- Testes do parser JSON de `lsblk`, filtro de partições, estado somente leitura e entradas inválidas.
- Testes de planos automáticos UEFI/BIOS e personalizados, incluindo disco somente leitura, disco pequeno, boot ausente, alinhamento inválido, raiz duplicada, excesso de capacidade e caminho inseguro.
- Compilação C/GTK4 e execução dos testes pela workflow de validação.

## Próximas etapas obrigatórias

1. Completar o editor de particionamento personalizado e a revisão visual de todas as operações destrutivas.
2. Implementar um backend privilegiado pequeno e auditável, separado da interface, com confirmação vinculada ao disco e ao plano revisado.
3. Montar uma fonte local de pacotes oficiais assinados na própria mídia e instalar sem rede, sem copiar a raiz do sistema live.
4. Configurar usuário, senha, locale, teclado ABNT2, MATE, LightDM, serviços, initramfs e GRUB no destino.
5. Garantir o início do agente gráfico MATE Polkit, sem regras permissivas adicionais.
6. Exibir progresso real, logs úteis, erros compreensíveis e permitir abortar com segurança.
7. Testar em discos virtuais descartáveis em BIOS e UEFI antes de habilitar o botão de instalação.

A aplicação atual oferece navegação, descoberta de discos e prévia de planos somente leitura. Ela **não é um instalador funcional** e não altera discos.
