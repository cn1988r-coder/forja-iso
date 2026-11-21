# Instalador VENOM OS

O instalador está sendo desenvolvido como aplicação nativa em C com GTK4. A interface é exclusiva em Português do Brasil e apresenta Brasil ABNT2 como teclado padrão, sem seletor de outros idiomas ou países.

## Etapa entregue neste incremento

- Aplicação GTK4 com navegação gráfica entre as etapas iniciais.
- Enumeração de discos por `lsblk`, com leitura estruturada da saída JSON.
- Identificação de caminho, modelo, capacidade e estado somente leitura.
- Testes unitários do parser, incluindo filtro de partições, preservação do estado somente leitura e rejeição de JSON inválido.
- Botão de instalação desabilitado. Nenhum comando de particionamento, formatação, montagem ou gravação é executado.

## Próximas etapas obrigatórias

1. Implementar um backend privilegiado pequeno e auditável, separado da interface.
2. Implementar seleção de modo automático e personalizado, com plano de partições revisável e confirmação explícita antes de qualquer escrita.
3. Montar uma fonte de pacotes local assinados na própria mídia e instalar sem rede, sem copiar a raiz do sistema live.
4. Configurar usuário, senha, locale, teclado ABNT2, MATE, LightDM, serviços, initramfs e GRUB no destino.
5. Exibir progresso real, logs úteis, erros compreensíveis e permitir abortar com segurança.
6. Testar em discos virtuais descartáveis em BIOS e UEFI antes de habilitar o botão de instalação.

A interface atual é um protótipo funcional de navegação e descoberta somente leitura. Ela **não é um instalador funcional** e não altera discos.
