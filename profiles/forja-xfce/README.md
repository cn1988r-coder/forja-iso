# Perfil Forja OS XFCE para EndeavourOS

Este é o perfil ativo da edição XFCE da Forja OS. EndeavourOS, derivado do Arch Linux, fornece a infraestrutura técnica de construção e o ambiente Live. A experiência visual, o painel e a seleção de componentes da sessão são definidos pela Forja OS.

O perfil é mantido separado do checkout upstream. A preparação cria uma pasta de trabalho própria e preserva os arquivos originais do EndeavourOS. O framework de construção está fixado no commit `0bbb1280ccd373262561453d85201f2707483990` para evitar mudanças inesperadas entre compilações.

## Escopo atual

- Perfil Archiso com modos de inicialização BIOS e UEFI alinhados ao framework EndeavourOS.
- XFCE com LightDM e personalização própria da Forja OS.
- Painel inferior da Forja com Whisker Menu e **DockbarX** como barra de tarefas.
- DockbarX e o plugin xfce4-dockbarx-plugin são construídos como pacotes locais a partir de PKGBUILDs revisados e versionados no repositório. Não são tratados como pacotes oficiais Arch/EndeavourOS e não dependem de repositórios Manjaro ou BigCommunity.
- Preparação e validação de seis pacotes locais Forja: DockbarX, plugin XFCE, Forja Recovery, Forja Snapshots e dois componentes Shelly. GRUB-Btrfs vem do repositório oficial Arch.
- Pré-build automatizado dos pacotes locais, sem executar o mkarchiso.
- Cliente Forja Updates integrado ao XFCE por manifesto estável independente; instala somente arquivos próprios em destinos permitidos, após validar SHA-256, criar backup e pedir confirmação. O canal permanece sem atualizações enquanto não houver artefatos publicados.

## Proteção por snapshots Btrfs

A edição XFCE fixa Btrfs como sistema de arquivos, com subvolumes `@`, `@home`, `@cache` e `@log`. O pacote Forja Snapshots configura o Snapper no primeiro boot do sistema instalado, habilita criação/limpeza por linha do tempo e hooks antes/depois de transações Pacman. O pacote oficial `grub-btrfs` integra os snapshots ao menu do GRUB e monitora novas criações com `grub-btrfsd`. O Forja Recovery permite diagnosticar e criar snapshots manuais. A raiz é protegida; `/home` permanece em subvolume separado e não é incluído nos snapshots root.

O workflow de pré-build executa um teste Btrfs real em imagem de loop: cria subvolume, configura Snapper, cria snapshot numerado e valida o par pre/post usado pelos hooks. Isso não substitui um teste de inicialização/rollback em máquina virtual, que continua obrigatório antes de distribuir a ISO.

## Preparação do perfil

1. Clone o repositório oficial EndeavourOS-ISO.
2. Execute este script apontando para o checkout upstream:
   ENDEAVOUROS_ISO_DIR=/caminho/EndeavourOS-ISO ./prepare-forja.sh
3. Entre no diretório forja-xfce-profile criado ao lado do checkout upstream.
4. Revise os PKGBUILDs locais em forja-packages/ e execute ./prepare.sh em um ambiente EndeavourOS/Arch compatível.

A preparação compila os pacotes locais, instala temporariamente DockbarX no ambiente de preparação para resolver a dependência de construção do plugin e prepara os arquivos para instalação no rootfs da ISO. O hook EndeavourOS instala os pacotes locais antes da geração do SquashFS.

**A preparação não compila uma ISO.** O checkout original do EndeavourOS é preservado. A construção da ISO é uma etapa separada e exige autorização explícita.

## Limitação importante do instalador

O Calamares ainda não está incluído. O pacote oficial do EndeavourOS foi descontinuado do repositório e a receita atual depende da configuração e da marca EndeavourOS. O perfil já contém apenas configurações iniciais de montagem e particionamento, não um instalador Forja completo. Portanto, a primeira ISO poderá ser usada para testar o ambiente Live XFCE, mas ainda não instalará o sistema pelo Calamares.

## Pendências técnicas antes de uma ISO de instalação completa

- Auditar e adaptar os pressupostos KDE do ambiente Live upstream para a sessão XFCE.
- Confirmar a disponibilidade e a compatibilidade de todos os pacotes nos repositórios Arch e EndeavourOS.
- Integrar uma versão compatível do Calamares, incluindo branding Forja, módulos de instalação, configuração de bootloader e suporte Btrfs.
- Validar o fluxo de inicialização e a geração do initramfs com dracut.
- Definir e testar a integração do Plymouth com dracut e com os modos de boot suportados.
- Revisar serviços, usuário Live, rede, áudio, Bluetooth, Flatpak e permissões.
- Implementar e validar a chave pública e o keyring de assinatura dos pacotes próprios da Forja.
- Executar e aprovar o pré-build em ambiente Arch limpo, que compila os seis pacotes locais Forja e valida a dependência oficial GRUB-Btrfs sem criar ISO.
- Testar a inicialização Live e a instalação completa em máquina virtual antes de qualquer divulgação.

## Separação das edições

Este perfil é exclusivamente XFCE. MATE é a próxima edição planejada, em perfil próprio. Window Maker permanece apenas em estudo. i3 não faz parte do escopo atual.

A base Manjaro permanece apenas como código legado preservado no repositório. Nenhuma ferramenta ou pacote exclusivo do Manjaro deve ser usado nesta edição EndeavourOS.

## Validação automatizada

O GitHub Actions executa verificações estáticas do perfil XFCE, incluindo scripts, XML do painel e bloqueio do construtor legado. Essa etapa não compila nem publica uma imagem ISO; a compilação só deve ocorrer depois da aprovação da validação.
