# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Versão em desenvolvimento
- Identificação: **VENOM OS 1.0**.
- Arquivo de identificação instalado: `/etc/venom-release`.
- Base: Manjaro Linux, repositórios oficiais Manjaro.
- Edição: MATE.
- Esta versão deve ser uma ISO Live instalável, com o Calamares oficial do Manjaro incluído na própria imagem.

## Arquitetura ativa
- Perfil de ISO: `manjaro/venom-mate`.
- Ferramenta oficial de construção: `manjaro-tools/buildiso`, acionada pela ação `manjaro/manjaro-iso-action`.
- Desktop: MATE + MATE Extra.
- Gerenciador de login: LightDM.
- Idioma: Português do Brasil.
- Teclado: Brasil ABNT2.
- Instalador: pacote oficial Manjaro `calamares`, incluído em `Packages-Live`.
- Ferramenta de particionamento Live: GParted.
- Bootloader: GRUB.
- A branch de trabalho permanece `optimize/venom-iso-size`; não alterar `main`.
- Não usar EndeavourOS nem Archiso no pipeline Manjaro.

## Integração do Calamares
- O Calamares é instalado durante a construção da ISO, dentro da sessão Live, e não após a inicialização.
- O pacote é listado em `manjaro/venom-mate/Packages-Live`, seguindo a organização dos perfis oficiais Manjaro.
- A configuração de instalação é gerada pelo fluxo oficial `buildiso` a partir do perfil e de `profile.conf`.
- O pacote Manjaro fornece o lançador do instalador e o wrapper Polkit utilizado para iniciá-lo.
- O GParted acompanha a sessão Live.
- Não substituir o Calamares por instalador próprio, externo ou baixado em tempo de execução.
- A presença do pacote e a validação estática não provam por si só que a instalação real funciona. O artefato deverá ser iniciado em máquina virtual e a instalação testada antes de declarar a VENOM OS 1.0 pronta.

## ISO de referência preservada
- A ISO Manjaro MATE #21 testada pelo usuário está identificada como `VENOM-MATE-21-DEEPSEEK-BASE`.
- Registro completo do workflow, commit, artefato, SHA256 e regras de preservação: [`docs/REFERENCIA-ISO-21-DEEPSEEK.md`](REFERENCIA-ISO-21-DEEPSEEK.md).
- Não confundir a ISO #21 original com builds posteriores que apliquem novos temas ou modificações.
- A ISO #31 foi testada e não apresentou todas as personalizações esperadas; não tratá-la como referência visual aprovada.

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

## Atualizações
- Pacman administra o sistema e os aplicativos: `sudo pacman -Syu`.
- VENON permanece independente do Pacman e acionado manualmente.
- `venon-upgrade` apenas consulta e lista atualizações; nunca instala.
- `venon-update` instala atualizações VENON somente após confirmação explícita.

## Histórico
- O perfil Archiso e o Dockerfile baseados em Arch permanecem apenas como material histórico em `build/`; não fazem parte do pipeline de construção ativo.
- A configuração MATE anterior criada pelo assistente não é chamada pelo perfil Manjaro.
- Nenhuma ISO é declarada pronta até o workflow terminar com sucesso, o artefato ser verificado e a inicialização e instalação serem testadas.
