# Continuidade técnica: VENOM OS XFCE

Atualizado em 21/11/2026.

## Arquitetura
- Branch: `feature/venom-community-xfce`.
- Base: Arch Linux oficial e repositórios oficiais.
- Desktop: XFCE real + LightDM; sem MATE ou Window Maker.
- Idioma pt_BR.UTF-8; teclado br-abnt2.
- Mídia Archiso oficial.
- Instalador Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`.
- Instalação exclusivamente online via pacstrap/Pacman. Sem unpackfs, rsync ou cópia da raiz live.
- Atualizações normais pelo Pacman; VENON separado e manual.

## Migração executada
- Reconstruída a estrutura operacional sobre Archiso e arquivos Calamares aprovados na branch Arch/MATE.
- Manifest live XFCE separado do manifesto de pacotes do sistema instalado.
- Pacotes do sistema instalado incluem XFCE, Thunar, LightDM, Xorg, rede, Bluetooth, áudio, GRUB e dependências básicas, sem ferramentas de criação da ISO.
- LightDM configurado para a sessão `xfce`; sem autologin no sistema instalado.
- Overlay de instalação inclui configurações XFCE/GTK, tema XFWM4, wallpaper, ícones e configuração de LightDM.
- Módulo VENOM instala pacotes oficiais com pacstrap e copia somente o overlay explícito, antes da criação do usuário. Não copia a raiz live.
- Sequência Calamares executa locale, keyboard e users, além de fstab, displaymanager, serviços, initramfs e bootloader.
- Removidos workflows e diretórios operacionais Manjaro, perfis antigos, Pamac, MHWD e credenciais padrão.
- Workflow Archiso e validador específico `scripts/validate-xfce-profile.sh`.

## Histórico de migração
- Run #76, ID `44843598356`, falhou por pacote `adwaita-gtk-theme` não encontrado.
- Perfil antigo continha `mhwd`, autologin e senha padrão `venom`.
- Nenhuma ISO desse estado é considerada instalável.

## Validação estática atual
- Run `44857750371`, commit `66210f76e6d2e50981d414081123782fc519467d`: sucesso.
- Instalação das ferramentas, validação do perfil e disponibilidade dos pacotes oficiais, sintaxe dos scripts e conclusão do job passaram.
- A validação estática anterior `44857473296` também passou.
- Essa validação não compila a ISO nem testa boot ou instalação real.

## Validação de mídia: primeira compilação ISO XFCE
- Run `44859735918` (21/11/2026), commit `205097039701b5fd7d4ee6efb19aae66e8749a80`: falhou na etapa `Verify Calamares payload`.
- Calamares upstream 3.3.14 compilou; validação estática do perfil Arch passou; `mkarchiso` concluiu e gerou no runner `out/venom-2026.11.21-x86_64.iso` (2,1 GiB; SHA-256 `3f124c8d4c96037bec31eec2d123146889a92da67cd1434e5391e1760e2a27f4`).
- A verificação falhou porque o workflow exigia literalmente `Exec=calamares`, mas o lançador válido usa `Exec=sudo -n /usr/bin/calamares`. O ISO não foi publicado como artefato; os testes BIOS/UEFI foram ignorados.
- Correção preparada no workflow: validar uma linha `Exec` que aponte para `calamares`, aceitando o caminho absoluto e o prefixo `sudo`.
- Próximo passo: executar novamente a compilação após autorização, confirmar a verificação do payload, executar os testes BIOS/UEFI e publicar o artefato somente se todos passarem.
- A imagem gerada no runner foi descartada ao encerrar o job; não há link de download disponível.

- Após autorização, validar boot BIOS/UEFI e instalação completa em VM descartável, incluindo primeiro login XFCE.

## Identidade visual e interfaces VENOM OS
Palavra-chave de recuperação solicitada pelo usuário: **INTERFACES**. Quando o usuário disser “chat, interfaces” ou pedir “as interfaces”, recuperar e apresentar este acordo.

Princípio: **uma identidade visual VENOM compartilhada, com três experiências de desktop distintas**. Não padronizar os três ambientes a ponto de parecerem cópias uns dos outros.

- **VENOM XFCE:** experiência moderna e objetiva; painel inferior robusto, menu próprio VENOM e identidade azul metálica.
- **VENOM MATE:** experiência elegante, familiar e organizada; preservar a personalidade e os recursos próprios do MATE, mantendo a identidade VENOM.
- **VENOM Window Maker:** experiência própria do Window Maker, inspirada na filosofia OpenStep; valorizar o Dock, o menu raiz e os elementos característicos do ambiente, sem imitar XFCE ou LXQt.

Elementos comuns às três edições:
- Identidade VENOM OS, com preto e azul metálico como cores principais e a marca/serpente VENOM nos elementos próprios do sistema.
- Aplicativos mantêm seus ícones e marcas originais. Não aplicar máscara ou recoloração que descaracterize Firefox e outros aplicativos.
- Usar base, ferramentas e pacotes do Arch Linux oficial. Não incluir identidade, ferramentas ou dependências operacionais do Manjaro.
- Manter consistência de marca sem apagar a identidade funcional e visual de cada ambiente.

Esta seção registra a direção visual aprovada pelo usuário. As referências são especificações conceituais, não evidência de que todos os elementos já estejam implementados ou testados nas ISOs.

## Preparação para retomada em 22/11/2026
- Prioridade: concluir a edição VENOM XFCE e entregar uma ISO verificável para o usuário testar.
- Correção do validador Calamares já está registrada no workflow, commit b943267bba0fb05a6152346ceca538c94f4b979a.
- O arquivo de trigger foi atualizado no commit 9514ba889b3ca1b5db30ef1b81e5fb51e383af57, mas a consulta posterior não mostrou uma nova execução do Actions. Portanto, a compilação #46 ainda não começou.
- Antes de iniciar: conferir se não há workflow ativo na branch e se o HEAD contém as correções esperadas.
- Iniciar manualmente o workflow VENOM OS XFCE Arch ISO em feature/venom-community-xfce usando Run workflow (workflow_dispatch). Não alterar arquivos enquanto a compilação estiver ativa, devido ao cancelamento automático por concorrência.
- Acompanhar a execução até o fim. Se passar: verificar testes BIOS/UEFI e artefato ISO, tamanho e SHA-256; só então fornecer o link do artefato para download.
- Se falhar: ler o log da etapa com erro, corrigir e registrar o resultado real. Não declarar ISO pronta sem artefato validado.
- Após o usuário baixar, instalar e testar a XFCE, revisar o resultado com ele. Só depois iniciar o desenvolvimento visual aprofundado do Window Maker, preservando a identidade VENOM e a personalidade OpenStep. A edição MATE permanece na sequência planejada.
- Limitação operacional: não existe compilação em segundo plano nesta conversa. A preparação fica registrada no repositório; a execução precisa ser iniciada e acompanhada quando a conversa for retomada.

