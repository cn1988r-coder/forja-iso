# Instalador VENOM OS

O instalador está sendo desenvolvido como aplicação nativa em C com GTK4. A interface é exclusiva em Português do Brasil e apresenta Brasil ABNT2 como teclado padrão, sem seletor de outros idiomas ou países.

## Incrementos implementados

### Interface e descoberta de discos
- Aplicação GTK4 com navegação gráfica entre as etapas iniciais.
- Enumeração de discos por `lsblk`, com leitura estruturada da saída JSON.
- Identificação de caminho, modelo, capacidade e estado somente leitura.
- Testes unitários do parser, incluindo filtro de partições, preservação do estado somente leitura e rejeição de JSON inválido.

### Planejador declarativo de partições
- Modo automático UEFI: tabela GPT, partição EFI FAT32 de 1 GiB e raiz ext4 ocupando o espaço disponível, preservando uma margem de 4 MiB.
- Modo automático BIOS: tabela GPT, partição BIOS de 2 MiB para o GRUB e raiz ext4.
- Modo personalizado: validação de partições EFI, BIOS, raiz e swap, tamanhos mínimos, alinhamento de 1 MiB, duplicatas e capacidade total.
- Recusa discos somente leitura, caminhos de dispositivo malformados e discos menores que 20 GiB.
- Cada plano registra que exige confirmação explícita e identifica a tabela GPT.

**Limite de segurança desta etapa:** o planejador apenas cria uma estrutura em memória. Não chama ferramentas de particionamento, não formata, não monta e não escreve em dispositivos. O plano ainda não está conectado à interface gráfica ou a um backend privilegiado. O botão de instalação permanece desabilitado.

## Próximas etapas obrigatórias

1. Integrar a seleção automática/personalizada e a revisão visual do plano na interface GTK4.
2. Implementar um backend privilegiado pequeno e auditável, separado da interface, com confirmação vinculada ao disco e ao plano revisado.
3. Montar uma fonte local de pacotes oficiais assinados na própria mídia e instalar sem rede, sem copiar a raiz do sistema live.
4. Configurar usuário, senha, locale, teclado ABNT2, MATE, LightDM, serviços, initramfs e GRUB no destino.
5. Criar a conta instalada nos grupos wheel, audio, video e storage, para que as operações administrativas gráficas tenham a autorização correta.
6. Garantir o início do agente gráfico MATE Polkit, sem regras permissivas adicionais.
7. Exibir progresso real, logs úteis, erros compreensíveis e permitir abortar com segurança.
8. Testar em discos virtuais descartáveis em BIOS e UEFI antes de habilitar o botão de instalação.

A interface atual continua sendo um protótipo de navegação e descoberta somente leitura. O planejador de partições é uma biblioteca de validação, não um executor. O instalador **não é funcional ainda** e não altera discos.
