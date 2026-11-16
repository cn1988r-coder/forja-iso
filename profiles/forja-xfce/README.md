# Perfil Forja OS XFCE para EndeavourOS

Este é o perfil ativo da edição XFCE da Forja OS. A base oficial é EndeavourOS, derivada do Arch Linux, e o framework de imagem é o projeto oficial EndeavourOS-ISO, baseado em Archiso.

O perfil é mantido separado do checkout upstream. A preparação copia os arquivos necessários para uma pasta de trabalho própria e não modifica os arquivos originais do EndeavourOS.

## Escopo atual

- Perfil Archiso com modos de inicialização BIOS e UEFI alinhados ao framework EndeavourOS.
- Conjunto inicial de pacotes Arch/EndeavourOS para XFCE, LightDM e identidade visual Forja.
- Integração inicial da sessão Live com as configurações XFCE da Forja.
- Preparação de pacotes locais necessários ao ambiente Live.
- Atualizador próprio em estágio inicial, ainda bloqueado até a implantação de assinatura confiável.

## Preparação do perfil

1. Clone o repositório oficial EndeavourOS-ISO.
2. Execute este script apontando para o checkout upstream:
   `ENDEAVOUROS_ISO_DIR=/caminho/EndeavourOS-ISO ./prepare-forja.sh`
3. Entre no diretório `forja-xfce-profile` criado ao lado do checkout upstream.
4. Revise os arquivos copiados e execute `./prepare.sh` em um ambiente EndeavourOS/Arch compatível para preparar os pacotes locais.

A preparação não compila uma ISO. O checkout original do EndeavourOS é preservado.

## Pendências técnicas antes da primeira compilação

- Auditar e adaptar os pressupostos KDE do ambiente Live upstream para a sessão XFCE.
- Confirmar a disponibilidade e a compatibilidade de todos os pacotes nos repositórios Arch e EndeavourOS.
- Integrar uma versão compatível do Calamares, incluindo branding, configuração de instalação e suporte Btrfs.
- Validar o fluxo de inicialização e a geração do initramfs com dracut.
- Definir e testar a integração do Plymouth com dracut e com os modos de boot suportados.
- Revisar serviços, usuário Live, rede, áudio, Bluetooth, Flatpak e permissões.
- Implementar e validar a chave pública e o keyring de assinatura dos pacotes próprios da Forja.
- Criar uma validação de dependências em ambiente limpo, além das verificações estáticas atuais.
- Testar inicialização Live e instalação completa em máquina virtual antes de qualquer divulgação.

## Separação das edições

Este perfil é exclusivamente XFCE. i3 poderá receber um perfil próprio no futuro. MATE e Window Maker continuam em avaliação e não devem ser adicionados a este perfil antes de uma decisão explícita.

A base Manjaro permanece apenas como código legado preservado no repositório. Nenhuma ferramenta ou pacote exclusivo do Manjaro deve ser usado nesta edição EndeavourOS.

**Nenhuma ISO é compilada pelos scripts de preparação descritos aqui.**