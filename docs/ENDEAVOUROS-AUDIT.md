# Auditoria técnica: framework EndeavourOS e adaptação Forja OS

## Fontes upstream

- Framework: https://github.com/endeavouros-team/EndeavourOS-ISO
- Receita Calamares: https://github.com/endeavouros-team/PKGBUILDS/tree/master/calamares
- Fork Calamares: https://github.com/endeavouros-team/calamares
- Shelly: https://github.com/Seafoam-Labs/Shelly-ALPM

## Revisões fixadas no compilador

- EndeavourOS-ISO: `90376d8f52ab19e19073eed33d6f36c46ec7c409`.
- PKGBUILDS: `474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd`.
- Shelly-ALPM: `6840658b19d72205c38bd320c1cef6ff3076bc7c`.

## Pontos upstream confirmados

1. O framework EndeavourOS é uma versão modificada do Archiso e precisa dos repositórios EndeavourOS para instalar seus pacotes e dependências.
2. O perfil upstream inclui KDE Plasma, pacotes KDE, `eos-settings-plasma` e configurações de sessão específicas.
3. `prepare.sh` gera o wallpaper com data, baixa o wallpaper do EndeavourOS, busca `eos-settings-plasma` e constrói o pacote `endeavouros-skel-liveuser`.
4. `run_before_squashfs.sh` cria liveuser, instala o pacote de esqueleto, instala pacotes locais de `airootfs/root/packages`, define o alvo systemd e prepara os arquivos de Calamares.
5. A lista de pacotes upstream comenta que Calamares não está mais disponível no repositório e que deve ser construído. O PKGBUILD oficial do EndeavourOS compila o fork e instala a configuração EOS.
6. O PKGBUILD de Shelly exige Zig 0.17.1 e constrói a interface GTK4 e o CLI. O pacote está fixado ao commit indicado acima.
7. Ferdium e Bibata são obtidos por receitas AUR, que são conteúdo comunitário e não binários oficiais.

## Ambiente de compilação isolado

O repositório agora inclui um Dockerfile que parte de Arch Linux e configura os
repositórios EndeavourOS usando o `pacman.conf` do commit fixado do framework e
a mirrorlist do commit fixado de PKGBUILDS. O wrapper `scripts/build-container.sh`
permite iniciar a compilação em Manjaro ou outra distribuição com Docker/Podman,
sem instalar repositórios EndeavourOS no sistema hospedeiro.

## Adaptação implementada no repositório

- Lista inicial de pacotes MATE, LightDM e Xorg em `build/packages.mate`.
- Perfil dconf de sistema com Materia Dark, Papirus, Bibata, fonte Noto Sans e fundo preto sólido.
- Configurações GTK3/GTK4 para o usuário live e esqueleto.
- Configuração LightDM para sessão MATE live.
- Script que clona o framework em revisão fixada, remove a seleção KDE e os aplicativos Welcome/Partition Manager, injeta MATE, remove a etapa `eos-settings-plasma`, compila o Calamares usando o PKGBUILD original do EndeavourOS sem alterar sua receita nem seus arquivos internos, prepara Shelly, Ferdium e Bibata, e chama `mkarchiso`.
- O atalho gráfico original do Calamares é mantido e ajustado para iniciar diretamente `pkexec calamares`, sem depender do `eos-welcome` e sem criar um instalador próprio. Na preparação da ISO, a configuração offline é ativada como `/etc/calamares/settings.conf` e passa a apontar para o branding `forja`.
- A receita do Calamares é adaptada durante o build para compilar em `Release`, instalar identidade visual Forja própria e corrigir a duplicidade do grupo `wheel` e as expressões de validação QML da etapa `usersq`. O fork e os módulos upstream continuam sendo utilizados.
- A análise detalhada da identidade, das correções de usuários e dos testes pendentes está em `docs/CALAMARES-FORJA-IDENTITY-AND-USERS.md`.
- Validador estático separado para estrutura, revisões e sintaxe.

## Pontos que ainda precisam de execução e correção

- Confirmar se todos os nomes de pacotes MATE estão disponíveis nos repositórios habilitados no host de build.
- Confirmar a disponibilidade do Zig 0.17.1 requerido pelo PKGBUILD de Shelly.
- Revisar as receitas AUR de Ferdium e Bibata e testar a construção delas no host.
- Confirmar se o pacote adaptado do Calamares abre pelo atalho gráfico na sessão MATE e carrega a identidade Forja e a configuração offline.
- Verificar se o liveuser entra automaticamente no MATE via LightDM e se o dconf system database é aplicado.
- Verificar o perfil final para que não restem pacotes, serviços ou referências KDE.
- Compilar a ISO e testar boot UEFI/BIOS, rede, MATE, Firefox, Ferdium, Shelly, Calamares, particionamento, criação de usuário, senha e instalação completa em VM.

## Limite de validação

A estrutura de compilação foi criada, mas não foi executada em host Arch/EndeavourOS nesta etapa. Não há ISO compilada. A validação automatizada do repositório é estática e não comprova build, boot ou instalação.


## Fluxo de instalação Forja OS

A configuração do Calamares foi substituída nos dois modos (online e offline):
- Ambos instalam a imagem completa da sessão Live da Forja OS por meio de `unpackfs`.
- O modo online atualiza a base de dados dos repositórios Arch após copiar a imagem.
- O modo offline instala a mesma imagem sem depender de conexão.
- Foram removidos do fluxo os módulos EndeavourOS de pacotes, pacstrap, EOS pacman, limpeza EOS, netinstall e seleção de pacotes/desktop.
- A sequência de telas fica em idioma, teclado, particionamento, criação de usuário e resumo. Não há escolha de ambiente gráfico: MATE é fixo.
- O bootloader é configurado como GRUB e a identificação EFI é Forja OS.
- A configuração do sistema instalado usa somente os repositórios oficiais Arch Linux. O repositório EndeavourOS permanece, quando necessário, apenas no ambiente de compilação para dependências upstream, nunca como repositório do sistema final.
- Firefox, MATE, LightDM, Shelly, IPTVnator e demais componentes listados no perfil Forja permanecem na imagem que será copiada.

A configuração ainda requer compilação real e testes de instalação em VM nos dois modos. O fluxo não deve ser considerado validado até completar particionamento, usuário, bootloader, primeiro boot e conferência dos pacotes instalados.

### Garantias adicionadas ao fluxo Forja

- O atalho abre a configuração unificada: com internet, o Calamares atualiza a base de dados dos repositórios Arch; sem internet, a etapa é ignorada automaticamente. Em ambos os casos, a origem da instalação é o mesmo `airootfs.sfs` da ISO Forja.
- A sequência visível é idioma, teclado, particionamento, usuário e resumo. MATE e GRUB são fixos, sem seleção de desktop, netinstall ou escolha de pacotes.
- Uma etapa final executada dentro do sistema de destino remove o pacote Calamares, seus arquivos de configuração e resíduos de identificação/repositório EndeavourOS. O sistema instalado fica com `ID=forja`, `ID_LIKE=arch` e repositórios Arch.
- Firefox está declarado explicitamente no perfil. IPTVnator continua sendo preparado como pacote local e instalado na imagem Live, que é a imagem copiada para o disco.

A CI da branch executou com sucesso a validação estática e o patcher contra o código upstream fixado do Calamares. Isso valida a adaptação dos arquivos, não substitui a compilação da ISO nem a instalação em máquina virtual.


## Desempenho de inicialização da ISO

O perfil upstream fixado utilizava SquashFS com XZ e filtro BCJ. XZ prioriza tamanho de arquivo, mas custa mais CPU para descompactar os dados durante a inicialização da sessão Live e o acesso aos arquivos do sistema.

O build Forja substitui essa configuração por SquashFS com Zstandard nível 3 e bloco de 1 MiB. A escolha prioriza velocidade de descompressão e leitura, mantendo compressão real para a ISO. A consequência esperada é uma ISO maior que a variante XZ, em troca de menor custo de CPU ao carregar o sistema. Não se usa compressão máxima: o objetivo é responsividade, não o menor arquivo possível.

Nenhum serviço essencial do MATE, LightDM, NetworkManager, Bluetooth ou Shelly é desativado como atalho de desempenho. A otimização do boot deve continuar com medições em VM, comparando tempo até LightDM, tempo até a sessão MATE utilizável e consumo de RAM/CPU. Ainda não há benchmark de ISO compilada; portanto, o ganho precisa ser confirmado em teste real.


## Correções de Pacman e wallpaper (19/11/2026)

- O `pacman.conf` da imagem final declara somente os repositórios Arch Linux: core, extra e multilib.
- O build copia a mirrorlist do Arch Linux para `airootfs/etc/pacman.d/mirrorlist` e interrompe a compilação se ela estiver ausente, sem servidores ou contiver referências EndeavourOS.
- A mirrorlist do ambiente de compilação deve ser a oficial do Arch; o script não cria um repositório próprio da Forja nem inventa endereço ou chave de assinatura.
- O MATE passa a apontar para `/usr/share/backgrounds/forja/forja-wallpaper.png` com opção de zoom, preservando a possibilidade de o usuário substituir o fundo.
- O build deixa de fabricar imagens pretas e exige o arquivo oficial antes de compilar. Depois do prepare.sh, o arquivo é copiado para os caminhos de wallpaper Live e Calamares.
- **Bloqueio de asset:** o arquivo PNG espacial em resolução 8K ainda precisa ser incorporado em `build/airootfs/usr/share/backgrounds/forja/forja-wallpaper.png`. A compilação agora falha explicitamente enquanto esse arquivo não existir, em vez de gerar uma ISO com fundo preto.
