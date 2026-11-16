# Forja OS XFCE: avaliação de porte para EndeavourOS

Status: avaliação técnica inicial. Esta branch é experimental e independente da edição Manjaro.

## Objetivo

Avaliar e portar a edição XFCE da Forja OS para a infraestrutura de construção do EndeavourOS, preservando a identidade visual e os recursos próprios da Forja. A edição Manjaro original permanece intacta.

## Resultado da inspeção inicial

O porte é tecnicamente possível, mas não é uma troca simples de repositório ou de nome da distribuição. O construtor atual é fortemente acoplado ao Manjaro.

### Componentes reaproveitáveis

- Configurações XFCE: painel, Whisker Menu, tema GTK, papel de parede, ícones, cursor, fontes e atalhos.
- Scripts de aplicação da aparência e arquivos de identidade visual.
- Estrutura de configuração do LightDM, sujeita à validação no ambiente live do EndeavourOS.
- Preferência Btrfs do Calamares, sujeita à validação da versão/configuração do Calamares usada pelo EndeavourOS.
- Integração Flatpak, após verificar a sessão live e a instalação offline.

### Componentes que não podem ser copiados sem adaptação

1. **Construtor:** `build-manjaro.sh` usa `manjaro-tools`, `buildiso` e perfis ISO do Manjaro. O EndeavourOS usa seu próprio framework derivado de Archiso e `mkarchiso`.
2. **Repositórios:** o perfil atual adiciona `community-stable` e `community-extra` do BigCommunity. Esses repositórios não fazem parte da base EndeavourOS.
3. **Pacotes e identidade da base:** `manjaro-release`, `manjaro-keyring`, `manjaro-system`, `pacman-mirrors` e `mhwd` precisam ser substituídos por equivalentes compatíveis ou removidos.
4. **Chroot:** comandos `manjaro-chroot` precisam ser substituídos pelo mecanismo `arch-chroot`/chroot previsto pelo framework.
5. **Initramfs:** os scripts atuais configuram Plymouth por meio de hooks do mkinitcpio. EndeavourOS usa dracut; é necessário portar a configuração para dracut e validar a geração do initramfs.
6. **Boot:** o perfil EndeavourOS define systemd-boot para UEFI e Syslinux para BIOS. Os parâmetros de boot e o splash precisam ser integrados a esse perfil, sem presumir que a configuração GRUB do Manjaro seja aplicável.
7. **DockbarX e Shelly:** as receitas e origens atuais precisam ser revistas. DockbarX vem do repositório BigCommunity e não pode continuar dependendo dele. Os pacotes devem ser construídos a partir de fontes/receitas auditadas e incluídos no mecanismo de pacotes locais do ISO, se necessário.

## Referência do framework EndeavourOS

O projeto oficial usa um perfil Archiso com `profiledef.sh`, `packages.x86_64`, overlays em `airootfs/` e o script `run_before_squashfs.sh`. A compilação é executada com `mkarchiso`. O ambiente usa dracut e a instalação gráfica é iniciada pelo fluxo EndeavourOS/Calamares.

Referências:
- https://github.com/endeavouros-team/EndeavourOS-ISO
- https://endeavouros-team.github.io/EndeavourOS-Development/

## Etapas obrigatórias antes de qualquer ISO

1. Criar um perfil EndeavourOS XFCE próprio, sem alterar os perfis originais.
2. Criar uma lista de pacotes específica para Arch/EndeavourOS e verificar cada pacote nos repositórios habilitados.
3. Substituir dependências do Manjaro e BigCommunity por pacotes oficiais ou pacotes locais auditados.
4. Portar Plymouth de mkinitcpio para dracut.
5. Adaptar o fluxo Calamares, incluindo Btrfs, usuários, idioma e seleção de bootloader.
6. Adicionar validações estáticas para shell, XML, arquivos .desktop, nomes de pacotes, serviços e caminhos dos overlays.
7. Executar uma construção de teste em ambiente limpo.
8. Verificar checksum, boot UEFI/BIOS, sessão live, rede, áudio, loja, Flatpak e instalação real em máquina virtual.

## Critério de segurança

Nenhuma alteração nesta branch deve substituir ou apagar a branch Manjaro. Nenhuma ISO deve ser anunciada como funcional até concluir a construção e os testes de inicialização e instalação. A criação da ISO fica separada da validação estática e exige autorização explícita.
