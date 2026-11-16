# Perfil Forja OS XFCE para EndeavourOS

Este é o perfil ativo da edição XFCE da Forja OS. EndeavourOS, derivado do Arch Linux, fornece a infraestrutura técnica de construção e o ambiente Live. A experiência visual, o painel e a seleção de componentes da sessão são definidos pela Forja OS.

O perfil é mantido separado do checkout upstream. A preparação cria uma pasta de trabalho própria e preserva os arquivos originais do EndeavourOS.

## Escopo atual

- Perfil Archiso com modos de inicialização BIOS e UEFI alinhados ao framework EndeavourOS.
- XFCE com LightDM e personalização própria da Forja OS.
- Painel inferior da Forja com Whisker Menu e **DockbarX** como barra de tarefas.
- DockbarX e o plugin xfce4-dockbarx-plugin são construídos como pacotes locais a partir de PKGBUILDs revisados e versionados no repositório. Não são tratados como pacotes oficiais Arch/EndeavourOS e não dependem de repositórios Manjaro ou BigCommunity.
- Preparação de pacotes locais necessários ao ambiente Live.
- Atualizador próprio em estágio inicial, ainda bloqueado até a implantação de assinatura confiável.

## Preparação do perfil

1. Clone o repositório oficial EndeavourOS-ISO.
2. Execute este script apontando para o checkout upstream:
   ENDEAVOUROS_ISO_DIR=/caminho/EndeavourOS-ISO ./prepare-forja.sh
3. Entre no diretório forja-xfce-profile criado ao lado do checkout upstream.
4. Revise os PKGBUILDs locais em forja-packages/ e execute ./prepare.sh em um ambiente EndeavourOS/Arch compatível.

A preparação compila os pacotes locais, instala temporariamente DockbarX no ambiente de preparação para resolver a dependência de construção do plugin e prepara os arquivos para instalação no rootfs da ISO. O hook EndeavourOS instala os pacotes locais antes da geração do SquashFS.

**A preparação não compila uma ISO.** O checkout original do EndeavourOS é preservado. A construção da ISO é uma etapa separada e exige autorização explícita.

## Pendências técnicas antes da primeira compilação

- Auditar e adaptar os pressupostos KDE do ambiente Live upstream para a sessão XFCE.
- Confirmar a disponibilidade e a compatibilidade de todos os pacotes nos repositórios Arch e EndeavourOS.
- Integrar uma versão compatível do Calamares, incluindo branding, configuração de instalação e suporte Btrfs.
- Validar o fluxo de inicialização e a geração do initramfs com dracut.
- Definir e testar a integração do Plymouth com dracut e com os modos de boot suportados.
- Revisar serviços, usuário Live, rede, áudio, Bluetooth, Flatpak e permissões.
- Implementar e validar a chave pública e o keyring de assinatura dos pacotes próprios da Forja.
- Criar uma validação de dependências em ambiente limpo, além das verificações estáticas atuais.
- Testar a inicialização Live e a instalação completa em máquina virtual antes de qualquer divulgação.

## Separação das edições

Este perfil é exclusivamente XFCE. MATE é a próxima edição planejada, em perfil próprio. Window Maker permanece apenas em estudo. i3 não faz parte do escopo atual.

A base Manjaro permanece apenas como código legado preservado no repositório. Nenhuma ferramenta ou pacote exclusivo do Manjaro deve ser usado nesta edição EndeavourOS.
