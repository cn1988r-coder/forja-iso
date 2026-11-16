# Perfil Forja OS XFCE para EndeavourOS

Este é o perfil ativo da edição XFCE da Forja OS. EndeavourOS, derivado do Arch Linux, fornece a infraestrutura técnica de construção e o ambiente Live. A experiência visual, o painel e a seleção de componentes da sessão são definidos pela Forja OS.

O perfil é mantido separado do checkout upstream. A preparação cria uma pasta de trabalho própria e preserva os arquivos originais do EndeavourOS. O framework de construção está fixado no commit `0bbb1280ccd373262561453d85201f2707483990`.

## Escopo atual

- Perfil Archiso com modos BIOS e UEFI alinhados ao framework EndeavourOS.
- XFCE com LightDM e personalização própria da Forja OS.
- Painel inferior com Whisker Menu e **DockbarX**.
- DockbarX, plugin XFCE e tema Bibata compilados como pacotes locais com fontes e checksum fixados.
- Forja Recovery e Forja Snapshots compilados localmente; GRUB-Btrfs e Timeshift são dependências do conjunto de pacotes.
- Pré-build automatizado dos pacotes locais, sem executar o mkarchiso.
- Cliente Forja Updates independente do pacman.conf.

## Proteção por snapshots Btrfs

A arquitetura definida para esta edição usa **Timeshift** como ferramenta única de criação, gerenciamento e restauração dos snapshots. Snapper foi removido do fluxo. O GRUB-Btrfs permanece responsável por detectar snapshots Timeshift e apresentá-los no menu do GRUB.

O layout Btrfs foi simplificado para o formato compatível com Timeshift: subvolume raiz `@` e subvolume opcional `@home`. A raiz não pode usar `subvolid=` no /etc/fstab, pois o Timeshift precisa conseguir trocar o subvolume raiz durante a restauração. /home fica fora dos snapshots root nesta configuração.

No primeiro boot instalado, Forja Snapshots configura o Timeshift em modo Btrfs, cria o snapshot inicial e habilita uma verificação agendada pelo systemd. Um hook do Pacman cria um snapshot antes de instalar, atualizar ou remover pacotes. Forja Recovery faz diagnóstico e delega a restauração à interface oficial do Timeshift. O GRUB-Btrfs monitora os snapshots e atualiza as entradas de boot.

O teste automatizado verifica a capacidade real do Btrfs de criar e ler snapshots de subvolumes em uma imagem de loop, além de validar os arquivos de integração. Isso não substitui o teste de restauração do Timeshift e de inicialização do snapshot em uma máquina virtual. Essa validação de ponta a ponta continua obrigatória antes de distribuir uma ISO.

## Preparação

1. Clone o repositório EndeavourOS-ISO.
2. Execute `ENDEAVOUROS_ISO_DIR=/caminho/EndeavourOS-ISO ./prepare-forja.sh`.
3. Entre em `forja-xfce-profile` e execute `./prepare.sh` em ambiente Arch/EndeavourOS compatível.

A preparação compila os pacotes locais e prepara o rootfs. **Não compila uma ISO.** A compilação da ISO exige autorização explícita.

## Instalador

O Calamares ainda não está integrado. O perfil atual é Live-only e não instala o sistema. A integração de um instalador Forja, com XFCE fixo, GRUB fixo e Btrfs fixo, permanece pendente.

## Pendências antes da ISO de instalação

- Confirmar disponibilidade e compatibilidade de todos os pacotes em ambiente Arch limpo.
- Integrar Calamares com identidade Forja, sem seletores de desktop, bootloader ou filesystem.
- Validar initramfs/dracut e Plymouth.
- Revisar usuário Live, rede, áudio, Bluetooth, Flatpak e permissões.
- Implementar assinatura e keyring dos pacotes próprios.
- Executar o pré-build de pacotes e teste Btrfs.
- Testar em VM a criação, listagem, restauração pelo Timeshift, atualização do GRUB e boot no snapshot restaurado.

A base Manjaro permanece apenas como código legado preservado. Esta edição usa a base EndeavourOS/Arch.
