# Instalador VENOM OS

## Arquitetura

O instalador é próprio, com interface C + GTK4 e backend privilegiado separado. A instalação é **online e baseada nos repositórios oficiais do Arch Linux**.

Fluxo:
1. O usuário inicia a sessão live e conecta o computador à internet.
2. O instalador identifica discos e solicita confirmação explícita do disco de destino.
3. O backend verifica acesso HTTPS ao mirror oficial Arch.
4. O disco é particionado automaticamente em GPT para BIOS ou UEFI.
5. O `pacstrap` instala o Arch Linux e todos os pacotes listados em `build/packages.x86_64`, usando `/etc/pacman.conf` e os repositórios oficiais.
6. O backend configura fstab, usuário, senha, hostname, locale pt_BR, teclado ABNT2 e serviços.
7. Instala GRUB, gera initramfs e configura o boot.

## Segurança e limitações conhecidas

- A instalação exige internet funcional. Sem conexão ou sem acesso ao mirror oficial, a instalação é interrompida com erro; não existe modo offline ou cópia da sessão live.
- O disco selecionado é apagado integralmente. O instalador exige confirmação explícita.
- A instalação automática GPT é o único modo implementado no momento. Particionamento manual/personalizado ainda não está disponível.
- O backend deve ser testado em discos virtuais descartáveis em BIOS e UEFI, incluindo falhas de rede e primeiro boot do sistema instalado.
- Uma compilação bem-sucedida da ISO não comprova que o instalador conclui a instalação corretamente.

Não declarar o instalador pronto para hardware real antes de completar os testes de integração e validar o primeiro boot pós-instalação.
