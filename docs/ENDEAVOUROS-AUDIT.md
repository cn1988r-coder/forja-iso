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
