# Forja OS

A Forja OS é uma distribuição em desenvolvimento, derivada diretamente do **Arch Linux**. A base ativa está em `bases/archlinux/` e utiliza os repositórios e espelhos oficiais do Arch Linux para o sistema-base.

## Repositórios e atualizações

- **Arch Linux:** kernel, firmware, drivers, bibliotecas e pacotes oficiais do sistema, atualizados pelo Pacman.
- **EndeavourOS:** não integra a base ativa. A fundação antiga permanece preservada em `bases/endeavouros/` apenas como referência inativa.
- **Forja OS:** repositório binário adicional, separado, reservado exclusivamente a aplicativos e componentes próprios. Não substitui pacotes oficiais e não atualiza o sistema-base.

O Pacman continua sendo o gerenciador. O comando planejado `forja-repo check` consulta somente o catálogo binário Forja, usando uma base de dados isolada. Não executa `pacman -Syu` nem altera `/etc/pacman.conf`. O cliente e o fluxo de publicação estão em preparação; o repositório remoto ainda não contém pacotes.

## Ambiente gráfico

A edição gráfica oficial é **MATE upstream personalizado**, com identidade e aplicativos próprios da Forja OS. Consulte `DESKTOP-STRATEGY.md` e `desktop/mate/README.md`.

## Construção e instalação

O projeto agora possui um perfil de build que utiliza o perfil oficial `releng` do Archiso, fixado em um commit upstream, e sobrepõe os pacotes, configurações e aplicativos MATE da Forja. O workflow GitHub Actions tenta compilar a ISO e publicar um artefato; a primeira compilação ainda precisa concluir com sucesso e ser testada em máquina virtual.

O ambiente live está preparado para iniciar MATE pelo LightDM e oferece o Archinstall oficial como instalador em terminal. O instalador ainda precisa de testes de instalação completa e integração pós-instalação das configurações Forja. Não declarar a ISO pronta para instalação até esses testes.