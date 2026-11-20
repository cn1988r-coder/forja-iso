# Instalador VENOM OS

## Estado: protótipo de interface, não instalador funcional

A primeira estrutura GTK4 foi iniciada em C. Ela apresenta:
- janela gráfica em Português do Brasil;
- enumeração informativa de discos por `lsblk`;
- seleção visual de disco;
- escolha entre modo automático e personalizado;
- aviso sobre operações destrutivas.

## Bloqueios deliberados

O botão de instalação permanece sem operações de escrita. Não há backend de particionamento, formatação, cópia offline do sistema, criação de usuário, configuração de bootloader ou recuperação transacional. Nenhum disco pode ser alterado por esta versão.

## Próximas etapas obrigatórias

1. Implementar backend privilegiado separado, com validação estrita dos dispositivos e argumentos.
2. Definir e testar particionamento UEFI/BIOS e instalação automática/personalizada usando somente discos virtuais descartáveis.
3. Implementar cópia offline do sistema da mídia para o destino, configuração de fstab, locale, ABNT2, MATE, LightDM, rede e GRUB.
4. Adicionar progresso baseado em etapas reais, logs persistentes e tratamento de falhas.
5. Criar testes unitários e de integração com mocks e loop devices/VM descartável.
6. Integrar o aplicativo à sessão live e validar em VM antes de habilitar qualquer ação destrutiva.

Não habilitar instalação real nem declarar o instalador pronto antes de concluir e testar todas as etapas.
