# Perfil Archiso da VENOM OS

A mídia é construída com o Archiso oficial e pacotes dos repositórios oficiais do Arch Linux. O perfil está em build/.

## Conteúdo implementado

- Perfil x86_64 com boot BIOS via Syslinux e UEFI via GRUB.
- Kernel Linux, initramfs Archiso e parâmetros de inicialização da sessão live.
- Pacotes MATE, LightDM, NetworkManager, Bluetooth, áudio PipeWire e instalador GTK4.
- Locale pt_BR.UTF-8 e teclado br-abnt2.
- Inicialização live que cria a conta temporária venom, habilita MATE/LightDM e inicia NetworkManager e Bluetooth.
- Instalador compilado e integrado à mídia pelo workflow, sem incluir binários compilados no repositório.

## Validação e compilação

O workflow .github/workflows/build-arch-iso.yml executa:
1. atualização do ambiente Arch e instalação das ferramentas oficiais;
2. verificação dos pacotes e da estrutura do perfil;
3. análise ShellCheck e compilação C/GTK4 com Meson;
4. geração da ISO com mkarchiso;
5. testes de inicialização BIOS e UEFI com QEMU;
6. publicação da ISO e do SHA-256 como artefatos da execução.

A existência do workflow não prova que a execução terminou com sucesso. A ISO só deve ser considerada validada depois que todos os passos concluírem e o artefato estiver disponível.

## Limitações que ainda exigem teste real

- A interface e o backend do instalador foram implementados para instalação automática, copiando offline a árvore do sistema live, configurando usuário, locale, serviços e GRUB.
- O modo de particionamento personalizado ainda não está implementado.
- A instalação ainda precisa ser testada de ponta a ponta em discos virtuais descartáveis, nos modos BIOS e UEFI, incluindo o primeiro boot do sistema instalado.
- O ambiente MATE precisa de inspeção visual e teste de persistência após reinicialização em VM.

Não confundir compilação da ISO com validação completa do instalador ou do desktop.
