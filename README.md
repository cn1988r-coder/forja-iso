# VENOM OS 1.0

A VENOM OS 1.0 usa **Manjaro Linux** como base, com desktop MATE e LightDM. A imagem é construída com os perfis e ferramentas oficiais do Manjaro.

## Base e desktop
- Distribuição base: Manjaro Linux, repositórios oficiais Manjaro.
- Perfil próprio: `manjaro/venom-mate`, construído pelo `manjaro-tools/buildiso` oficial.
- Desktop: MATE + MATE Extra.
- Gerenciador de login: LightDM.
- Rede/Wi-Fi: NetworkManager e nm-applet na bandeja do sistema.
- Bluetooth: BlueZ e Blueman com ícone de bandeja.
- Áudio: PipeWire, WirePlumber e applet de volume MATE no painel.
- Idioma padrão: Português do Brasil.
- Teclado padrão: Brasil ABNT2.

## Instalador integrado
- O **Calamares oficial do Manjaro** é incluído em `Packages-Live`, portanto faz parte da própria ISO Live.
- O instalador fica disponível no ambiente Live pelo lançador fornecido pelo pacote Manjaro.
- O perfil mantém a configuração de boot GRUB e os componentes Live exigidos pelo fluxo de instalação.
- O GParted também fica disponível na sessão Live.
- O Calamares não é instalado posteriormente nem substituído por um instalador externo.

## Configuração MATE
O script `scripts/manjaro-mate-dark-complete.sh` foi mantido com sua lógica original. A única correção foi retirar `manjaro-mate-settings`, pacote que o Manjaro informa não oferecer atualmente para MATE. O layout `manjaro` usado pelo script é fornecido diretamente no perfil. A cópia instalada em `/usr/local/bin/manjaro-mate-dark-complete.sh` é verificada byte a byte contra o arquivo de origem.

No menu do MATE existe o atalho **Configurar MATE**. Ele abre um terminal e executa o script original, permitindo que os comandos sudo do script solicitem autenticação quando necessário. O script não é executado silenciosamente no primeiro login.

Os padrões atuais do desktop são Materia-dark, Papirus-Dark e Bibata Modern Classic. A estrutura do painel e os indicadores de volume, rede e Bluetooth da ISO de referência #21 são preservados.

## Construção
- Workflow: `.github/workflows/build-manjaro-iso.yml`.
- Ferramenta de construção: ação oficial `manjaro/manjaro-iso-action`, baseada em `manjaro-tools/buildiso`.
- Perfil: `venom-mate`.
- Canal: `stable`.
- Kernel: `linux618`.
- Identificação de versão: `/etc/venom-release`.
- Artefato ISO temporário do GitHub Actions: retenção de 3 dias.

## Referência de estabilidade
A ISO Manjaro MATE #21 testada pelo usuário permanece preservada como referência de funcionamento do MATE, painel e indicadores. Builds posteriores não são consideradas aprovadas pelo simples fato de o workflow terminar com sucesso. A ISO 1.0 só será considerada pronta após validação do workflow, inspeção do artefato e teste de inicialização e instalação.

## Atualizações
O Pacman administra o sistema e os aplicativos: `sudo pacman -Syu`.

O VENON continua sendo um mecanismo separado, manual e independente do Pacman:
- `venon-upgrade`: consulta e lista atualizações disponíveis, sem instalar.
- `venon-update`: instala atualizações VENON somente após confirmação explícita.
