# AGENTS.md

## Objetivo do projeto

Desenvolver a **VENOM OS**, uma distribuição baseada diretamente no Arch Linux oficial, com ambiente MATE e LightDM, identidade visual própria e um instalador gráfico independente.

Este arquivo é a fonte de instruções operacionais para agentes de desenvolvimento, incluindo Codex Cloud. Leia-o antes de alterar qualquer arquivo.

## Regras obrigatórias de trabalho

- Repositório: `cn1988r-coder/forja-iso`.
- Branch autorizada para o trabalho: `optimize/venom-iso-size`.
- Confirme a branch e o HEAD antes de editar.
- Não altere `main`, não faça push para `main` e não migre o trabalho para outra branch sem autorização explícita.
- Faça alterações coerentes, verificáveis e documentadas. Commits pequenos são preferíveis a um commit monolítico.
- Não gere, publique ou dispare uma compilação de ISO. A geração de uma nova ISO depende de autorização explícita posterior do usuário.
- Não peça ao usuário para executar comandos, compilar, testar ou atuar como técnico. Use o ambiente de desenvolvimento e CI disponíveis.
- Nunca declare algo funcional sem executar e registrar o teste correspondente.
- Em cada relatório, separe: **feito**, **pendente**, **bloqueios** e **não testado**.
- Não invente resultados, hashes, artefatos, testes ou estado de workflows.
- Não use credenciais em arquivos, commits, logs ou saídas. Não tente obter ou alterar segredos do GitHub.

## Arquitetura e identidade da VENOM OS

- Nome do sistema: **VENOM OS**.
- Base: **Arch Linux oficial puro**. Arch é a base técnica, não o nome da distribuição.
- Desktop principal e único: **MATE**.
- Gerenciador de login: **LightDM**.
- Não incluir KDE/Plasma, XFCE ou outros desktops como sessões suportadas.
- Identidade visual escura, monocromática e consistente, com marca VENOM em toda a interface.
- Não deixar nomes, logotipos, temas, serviços, pacotes, repositórios, ferramentas ou identidade de EndeavourOS, Forja ou Artix no produto final. Créditos e avisos legais obrigatórios de terceiros devem ser preservados de forma correta, sem transformar essas distribuições em identidade do produto.

## Remoção completa do EndeavourOS

O usuário autorizou remover as dependências de EndeavourOS. Isso inclui framework de geração de ISO, repositórios, keyrings, mirrorlists, chaves, pacotes exclusivos, skeletons, scripts, hooks, serviços, configurações, launchers, wallpapers e referências operacionais.

- Não basta trocar textos ou renomear diretórios.
- Não clonar nem usar `endeavouros-team/EndeavourOS-ISO`, PKGBUILDs, Calamares ou qualquer framework de EndeavourOS.
- Não introduzir outra distribuição como substituta estrutural.
- Reconstruir a geração da imagem com o perfil oficial do **Archiso**, mantido pelo próprio projeto VENOM.
- Usar apenas repositórios e keyrings oficiais do Arch para a base do sistema.
- Referências históricas em documentação só podem permanecer quando forem estritamente necessárias para explicar uma migração; não devem ser dependências, componentes ou identidade do sistema.

## Instalador VENOM

O instalador deve ser próprio e 100% gráfico. **Calamares foi rejeitado explicitamente e não pode continuar como instalador nem como dependência.**

Direção técnica aprovada para estudo e implementação: interface nativa em **C com GTK4**, integrada ao MATE, com backend separado. Reavalie tecnicamente apenas se houver incompatibilidade demonstrável, documentando evidências antes de propor outra tecnologia. Não adote Python como solução sem nova autorização.

Requisitos funcionais:
- seleção de idioma e teclado;
- detecção e identificação clara dos discos;
- instalação automática e particionamento personalizado;
- revisão e confirmação explícita antes de qualquer operação destrutiva;
- instalação offline usando o conteúdo e os pacotes disponíveis na própria ISO;
- instalação do sistema no destino, criação do usuário e configuração de senha;
- configuração de MATE, LightDM, rede e GRUB;
- progresso real, logs acessíveis e mensagens de erro compreensíveis;
- tratamento de falhas e possibilidade de abortar com segurança;
- nenhuma etapa deve exigir terminal, shell ou conhecimento técnico do usuário.

Use ferramentas oficiais do Arch, como `pacstrap`, `arch-chroot`, `genfstab`, ferramentas de particionamento e GRUB, somente através de um backend validado. Não apresente uma interface visual que apenas encadeia comandos frágeis como se fosse um instalador pronto.

## Estratégia de implementação

1. Auditar o estado real do repositório e registrar o HEAD inicial.
2. Inventariar dependências EndeavourOS e Calamares em código, perfis, pacotes, workflows, documentação e artefatos.
3. Construir o perfil Archiso próprio da VENOM e substituir o pipeline dependente do EndeavourOS.
4. Atualizar Dockerfile, scripts, workflows e validadores para a nova arquitetura Archiso.
5. Remover Calamares, seus patches, wrappers, regras polkit, configurações e pacotes depois que os substitutos independentes estiverem implementados.
6. Desenvolver o instalador gráfico em componentes testáveis, com separação entre interface, lógica de instalação e operações privilegiadas.
7. Criar testes unitários, testes de integração sem escrita destrutiva em discos reais e verificações estáticas.
8. Atualizar documentação e manter um registro de continuidade preciso.
9. Não gerar ISO até que o usuário autorize expressamente essa etapa.

Não faça substituições por regex em scripts upstream, não injete hooks frágeis em frameworks de outras distribuições e não crie variantes online/offline duplicadas sem necessidade arquitetural comprovada.

## Pacotes e componentes externos

- Priorize pacotes dos repositórios oficiais do Arch.
- Para aplicativos sem pacote oficial, avalie fontes e receitas AUR com revisão humana do conteúdo, origem verificável e revisão/commit fixado.
- Não baixe nem execute binários desconhecidos.
- Preserve os aplicativos escolhidos para o projeto quando tecnicamente viáveis: Firefox, Ferdium, Shelly e IPTVnator; Bibata pode ser usado como tema de cursor.
- Não misture o atualizador VENON com Pacman.

## Atualizações do sistema e VENON

- Pacman é o único responsável por atualizações normais do sistema e aplicativos: `sudo pacman -Syu`.
- VENON é independente do Pacman e não deve executar automaticamente.
- Comandos definidos:
  - `venon-upgrade`: apenas consulta e lista atualizações VENON disponíveis, sem instalar.
  - `venon-update`: baixa e instala atualizações VENON somente após confirmação explícita.
- Não declarar esses comandos operacionais até que backend, metadados assinados, distribuição e instalação tenham sido implementados e testados.

## Segurança e testes

- Não afirmar que o sistema é blindado ou altamente seguro sem auditoria e testes específicos.
- Nunca executar operações de particionamento em discos reais durante desenvolvimento.
- Testes do instalador devem usar mocks, imagens de disco descartáveis ou máquinas virtuais isoladas.
- Não usar testes que apaguem dados do host.
- Não iniciar build de ISO, mesmo em CI, até autorização explícita do usuário.
- Testes estáticos, análise de código, compilação de componentes e testes unitários são permitidos.
- Distinguir compilação de componentes da geração da ISO completa.

## Relatórios e continuidade

Mantenha documentação de continuidade atualizada no repositório. Registre:
- branch e commit-base;
- arquivos alterados;
- decisões técnicas e justificativas;
- testes realmente executados e seus resultados;
- itens concluídos, pendentes e bloqueados;
- confirmação explícita de que nenhuma ISO foi gerada.

Trabalhe de forma autônoma dentro destas regras, sem interromper o usuário por decisões rotineiras de implementação. Pare e peça autorização apenas para decisões fora do escopo, operações destrutivas, mudanças de branch/repositório, publicação de releases ou geração de ISO.
