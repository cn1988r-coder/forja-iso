# AGENTS.md

## Objetivo
Desenvolver a VENOM OS como distribuição independente baseada diretamente no Arch Linux oficial, com MATE, LightDM, identidade própria e instalador gráfico próprio.

## Regras de trabalho
- Repositório: cn1988r-coder/forja-iso.
- Branch autorizada: optimize/venom-iso-size.
- Confirme HEAD e branch antes de editar.
- Nunca altere main ou outras branches sem autorização expressa.
- Não gere, publique ou dispare compilação de ISO sem autorização expressa do usuário.
- Não declare funcionalidades ou testes sem evidências reais.
- Registre separadamente feito, pendente, bloqueios e não testado.
- Não inclua credenciais, tokens ou segredos no repositório.

## Arquitetura
- Nome: VENOM OS.
- Base única: Arch Linux oficial e seus repositórios oficiais.
- Desktop único: MATE.
- Gerenciador de login: LightDM.
- Idioma exclusivo: Português do Brasil.
- Teclado padrão: Brasil ABNT2.
- Identidade visual escura e monocromática VENOM.
- Não introduza frameworks, pacotes, serviços, repositórios, configurações ou identidade de outras distribuições.

## Instalador
O instalador será próprio, 100% gráfico, desenvolvido em C + GTK4, com backend separado. Não usar instaladores de terceiros nem adotar Python como implementação sem nova autorização.

Requisitos: seleção de disco; instalação automática e personalizada; confirmação explícita de operações destrutivas; instalação offline a partir da própria mídia; criação de usuário; configuração de MATE, LightDM, rede e GRUB; progresso real, logs e tratamento seguro de falhas. Nenhuma etapa pode exigir terminal do usuário.

Usar ferramentas oficiais do Arch somente através de backend validado. Operações privilegiadas devem ser estritamente validadas e testadas com mocks e imagens descartáveis.

## MATE
Manter MATE + LightDM. Auditar individualmente os indicadores de rede/NetworkManager, Bluetooth e volume/áudio. Verificar pacotes, serviços, painel, autostart, ícones e persistência. Não declarar validação gráfica sem teste real de sessão e reinicialização.

## Atualizações
Pacman é responsável por atualizações normais: sudo pacman -Syu.
VENON é separado do Pacman e manual. venon-upgrade apenas consulta/lista. venon-update instala apenas após confirmação. Não criar timers ou atualizações automáticas.

## Desenvolvimento e validação
- Construir a mídia somente com o perfil oficial Archiso mantido no projeto.
- Não executar build ISO durante o desenvolvimento sem autorização expressa.
- Validar scripts, perfil, manifests, locale e teclado com testes estáticos.
- Não declarar instalador funcional antes de testes de integração e instalação em VM descartável.
- Atualizar docs/PROJECT-CONTINUITY.md com HEAD, commits, arquivos alterados, testes reais e pendências.
