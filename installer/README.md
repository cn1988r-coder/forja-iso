# Instalador VENOM OS

## Implementação atual

O instalador tem interface gráfica própria em C + GTK4 e backend privilegiado separado.

A interface oferece:
- detecção e seleção visual de discos inteiros;
- cadastro do usuário, hostname e senha;
- confirmação explícita antes de apagar o disco;
- chamada do backend por sudo não interativo, restrito ao executável do instalador no sudoers;
- apresentação do resultado e gravação de log em /var/log/venom-installer/.

O backend de instalação automática:
- valida o dispositivo, tamanho mínimo, partições montadas e a mídia de origem;
- cria tabela GPT para BIOS ou UEFI;
- formata ext4 e, em UEFI, a partição EFI FAT32;
- copia o sistema live para o destino com rsync, sem baixar pacotes;
- configura usuário, senha, hostname, locale pt_BR, teclado ABNT2 e fstab;
- remove configurações temporárias de autologin da sessão live;
- habilita NetworkManager, Bluetooth e LightDM;
- instala GRUB para BIOS ou UEFI e regenera initramfs.

## Limitações e segurança

- O modo automático é o único modo disponível na interface. Particionamento personalizado ainda não foi implementado.
- O backend é destrutivo: somente execute em discos descartáveis até a validação integral.
- A cópia offline do sistema live ainda precisa ser validada em VM. Uma compilação bem-sucedida não demonstra, por si só, que o sistema instalado inicializa corretamente.
- Ainda faltam testes de integração com discos virtuais, falhas simuladas, reinicialização e inspeção da sessão MATE.
- A interface mostra o estado geral da operação; o log do backend contém as etapas detalhadas.

Não declarar o instalador pronto para uso em hardware real antes de completar os testes BIOS/UEFI e validar o primeiro boot pós-instalação.
