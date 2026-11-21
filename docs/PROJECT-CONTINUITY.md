# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Arquitetura
- Base: Arch Linux oficial e repositórios oficiais.
- Desktop: MATE; login: LightDM.
- Idioma: pt_BR.UTF-8; teclado: Brasil ABNT2.
- Mídia: perfil próprio Archiso.
- Instalador: Calamares upstream, branding VENOM e módulo Python venominstall.
- Instalação exclusivamente online: o módulo verifica HTTPS e executa pacstrap sobre rootMountPoint.
- Não usar unpackfs, rsync ou cópia da raiz live para instalar.

## Repositório
cn1988r-coder/forja-iso, branch optimize/venom-iso-size. Preservar main e demais branches.

## Alterações desta revisão
- Retirado o instalador C/GTK4 de dentro da ISO.
- Adicionada configuração Calamares, branding VENOM e módulo online pacstrap.
- Desktop entry inicia Calamares com sudo restrito ao executável; o usuário live não recebe senha administrativa geral.
- Workflow compila Calamares upstream 3.3.14 com Qt6 e Python, fixa checksum do tarball e instala na mídia live.

## Limitações e validação pendente
- Calamares não está disponível como pacote binário nos repositórios oficiais Arch nesta revisão; o workflow compila o upstream. Dependências são instaladas dos repositórios oficiais.
- O repositório upstream oficial está arquivado/read-only desde agosto de 2025; 3.3.14 é a última release listada. A manutenção de longo prazo precisa considerar isso.
- Validar build CMake, YAML, carregamento dos módulos e inicialização gráfica.
- Ainda não foi realizada instalação completa em VM BIOS/UEFI, nem validado o primeiro boot. Boot live não prova instalação funcional.
- Não anunciar ISO pronta até completar esses testes.

## Atualizações
Pacman administra o sistema: sudo pacman -Syu. VENON é independente e manual: venon-upgrade consulta; venon-update instala após confirmação. Sem timers.

## Referência histórica
A ISO Manjaro MATE #21 e scripts de referência permanecem intocados e não são a base da edição Arch.
