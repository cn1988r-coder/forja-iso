# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Arquitetura ativa
- Sistema: VENOM OS.
- Base definida nesta etapa: Manjaro Linux, repositórios oficiais Manjaro.
- Perfil de ISO: `manjaro/venom-mate`.
- Ferramenta oficial de construção: `manjaro-tools/buildiso`, acionada pela ação `manjaro/manjaro-iso-action`.
- Desktop: MATE + MATE Extra.
- Gerenciador de login: LightDM.
- Idioma: Português do Brasil.
- Teclado: Brasil ABNT2.
- Não incluir Calamares nem EndeavourOS.
- A branch de trabalho permanece `optimize/venom-iso-size`; não alterar `main`.

## Script original do DeepSeek
- Arquivo de origem: `scripts/manjaro-mate-dark-complete.sh`.
- O conteúdo original foi preservado.
- Cópia instalada no perfil: `manjaro/venom-mate/desktop-overlay/usr/local/bin/manjaro-mate-dark-complete.sh`.
- O validador compara as duas cópias byte a byte e verifica a sintaxe Bash.
- O menu do MATE recebe o atalho Configurar MATE, que abre um terminal e executa o script. Assim, o sudo pode solicitar autenticação.
- O script não é iniciado automaticamente em segundo plano.
- Nenhuma alteração foi feita no conteúdo do script original nesta integração.

## Construção Manjaro
- Workflow: `.github/workflows/build-manjaro-iso.yml`.
- Repositório de perfis fornecido à ação: este próprio repositório e a branch autorizada.
- Perfil selecionado: `venom-mate`.
- Canal: `stable`.
- Kernel: `linux618`.
- O workflow executa validação estática antes da construção e publica a ISO como artefato temporário com retenção de três dias.
- A ferramenta oficial Manjaro usa `buildiso` e o formato de perfis `manjaro/<perfil>`, não Archiso.

## Limitação do instalador
- O perfil atual é uma imagem live MATE para validar o desktop e o script.
- Calamares foi excluído conforme a decisão do projeto.
- O instalador próprio C + GTK4 ainda não possui backend funcional de particionamento, formatação, cópia offline, criação de usuário ou instalação do GRUB.
- Portanto, não declarar esta ISO instalável em disco. Não executar operações destrutivas em discos reais.

## Atualizações
- Pacman administra o sistema e os aplicativos: `sudo pacman -Syu`.
- VENON permanece independente do Pacman e acionado manualmente.
- `venon-upgrade` apenas consulta e lista atualizações; nunca instala.
- `venon-update` instala somente após confirmação explícita.

## Histórico
- O perfil Archiso e o Dockerfile baseados em Arch permanecem apenas como material histórico em `build/`; não fazem parte do pipeline de construção ativo.
- A configuração MATE anterior criada pelo assistente não é chamada pelo perfil Manjaro.
- Nenhuma ISO é declarada pronta até o workflow terminar com sucesso e o artefato ser verificado.
