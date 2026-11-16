# Forja OS XFCE: porte para EndeavourOS

Status: perfil EndeavourOS independente em implementação. A edição Manjaro original permanece preservada no código legado.

## Objetivo

Manter a identidade visual, o painel e os componentes próprios da Forja OS, usando EndeavourOS/Arch apenas como infraestrutura técnica. A sessão XFCE não deve reproduzir a aparência padrão do EndeavourOS nem depender de repositórios Manjaro ou BigCommunity.

## Componentes e decisões

- Painel inferior próprio da Forja OS, com Whisker Menu identificado como Forja OS.
- Barra de tarefas **DockbarX**, integrada ao painel XFCE pelo pacote xfce4-dockbarx-plugin. Docklike não faz parte desta edição.
- Os pacotes dockbarx e xfce4-dockbarx-plugin são construídos localmente a partir de PKGBUILDs revisados e versionados em profiles/forja-xfce/forja-packages/. Não são pacotes oficiais Arch e não exigem repositório adicional.
- Shelly permanece como componente local, construído a partir da receita própria.
- Sessão XFCE sob X11 para compatibilidade com o plugin DockbarX.
- Identidade Forja OS, tema escuro e paleta neutra; EndeavourOS/Arch não são marcas visuais do produto.

## Infraestrutura técnica

O framework EndeavourOS usa um perfil Archiso com profiledef.sh, packages.x86_64, overlays em airootfs/ e run_before_squashfs.sh. A compilação é executada separadamente com mkarchiso. O ambiente usa dracut e o fluxo EndeavourOS/Calamares.

Referências:
- https://github.com/endeavouros-team/EndeavourOS-ISO
- https://endeavouros-team.github.io/EndeavourOS-Development/
- https://github.com/M7S/dockbarx
- https://github.com/xuzhen/xfce4-dockbarx-plugin

## Etapas obrigatórias antes de qualquer ISO

1. Confirmar a disponibilidade e compatibilidade dos pacotes Arch/EndeavourOS.
2. Validar a construção limpa dos dois pacotes DockbarX e suas dependências.
3. Auditar o ambiente Live upstream e remover pressupostos KDE desnecessários.
4. Integrar e validar o Calamares, incluindo branding, instalação e suporte Btrfs.
5. Portar Plymouth para dracut e validar os modos BIOS/UEFI.
6. Revisar serviços, usuário Live, rede, áudio, Bluetooth, Flatpak e permissões.
7. Implementar a assinatura confiável e o keyring dos pacotes próprios da Forja.
8. Testar inicialização Live e instalação completa em máquina virtual.

## Segurança

PKGBUILDs são receitas de terceiros e devem permanecer revisados. Os pacotes são construídos localmente e instalados por pacman a partir de arquivos locais no rootfs. Nenhum repositório adicional é adicionado ao pacman.conf. Nenhuma ISO deve ser anunciada como funcional antes dos testes completos. A criação da ISO exige autorização explícita.
