# Máquina de preparação da VENOM OS

## Objetivo

Organizar a futura máquina de preparação usando o fluxo e as ferramentas oficiais do Manjaro. Esta máquina será separada do sistema final VENOM OS: ferramentas de desenvolvimento, caches, chroots, logs e checkout de perfis não serão incorporados à imagem final.

## Ferramentas oficiais

A documentação atual do Manjaro identifica `manjaro-tools-iso-git` como pacote necessário no procedimento de criação de ISO. O conjunto `manjaro-tools` é dividido funcionalmente em:

- `manjaro-tools-base`: componentes básicos e ferramentas de chroot.
- `manjaro-tools-pkg`: auxiliares de pacotes e ferramentas de preparação de pacotes.
- `manjaro-tools-iso`: ferramentas de perfis e imagens, incluindo `buildiso`.

O pacote indicado no guia oficial para preparar o fluxo de ISO é `manjaro-tools-iso-git`, acompanhado de `git`. A composição exata e as dependências devem ser obtidas dos metadados do repositório Manjaro no momento em que a instalação for autorizada. Não criar pacotes substitutos nem instalar ferramentas de outras distribuições.

## Layout planejado no computador de preparação

Os caminhos abaixo são uma proposta de organização, não diretórios já criados no computador:

```text
/home/USUARIO/
├── .config/
│   └── manjaro-tools/
│       ├── manjaro-tools.conf
│       └── iso-profiles.conf
├── iso-profiles/                 # checkout oficial do Manjaro
└── venom-workspace/
    ├── source/                   # checkout do repositório forja-iso
    ├── cache/                    # cache de pacotes e arquivos
    ├── chroots/                  # ambientes isolados do Manjaro Tools
    ├── logs/                     # registros das futuras operações
    └── output/                   # destino futuro dos artefatos
```

O layout é apenas um plano. Os diretórios reais e os caminhos absolutos serão definidos no computador de preparação antes de qualquer instalação ou execução.

## Configuração do Manjaro Tools

O Manjaro documenta a configuração do usuário em:

- `~/.config/manjaro-tools/manjaro-tools.conf`
- `~/.config/manjaro-tools/iso-profiles.conf`

O arquivo global fornecido pelo pacote fica em `/etc/manjaro-tools/manjaro-tools.conf`. A recomendação documentada é preservar o arquivo global e manter os ajustes do usuário na configuração local.

Modelos sem caminhos inventados estão em `config/`:
- `manjaro-tools.conf.example`
- `iso-profiles.conf.example`

## Relação com o projeto

- Repositório do projeto: `cn1988r-coder/forja-iso`.
- Perfil base: `manjaro/base`.
- Perfil desktop: `manjaro/xfce`.
- A base Manjaro permanece independente e sem desktop.
- O XFCE permanece como camada de desktop da edição.
- A estrutura dos perfis deverá acompanhar o formato compatível com a versão de Manjaro Tools utilizada.

O checkout oficial `iso-profiles` é uma referência externa de perfis Manjaro. Não será copiado por inteiro para dentro do repositório VENOM; o perfil VENOM continuará sendo mantido no repositório autorizado do projeto.

## Calamares

A edição deverá usar somente o pacote Calamares disponibilizado pelos repositórios oficiais do Manjaro e compatível com a base selecionada. Não usar upstream, AUR, builds próprios ou pacotes externos para substituir o Calamares do Manjaro.

## Recursos da máquina

A máquina de preparação precisa reservar espaço separado para:
- checkout dos perfis e do projeto;
- cache de pacotes;
- chroots de trabalho;
- logs;
- saída futura.

Não fixar capacidade mínima de disco ou memória neste documento sem conhecer o computador que será usado e a dimensão do perfil. A recomendação de espaço será definida antes da instalação das ferramentas.

## Estado desta etapa

Somente a estrutura documental e os modelos de configuração foram preparados no GitHub. Não houve instalação ou configuração no computador físico.

**Operações expressamente não realizadas:**
- nenhuma instalação de pacote;
- nenhum clone ou atualização de repositório no computador;
- nenhum chroot;
- nenhuma execução de `buildiso`, `buildpkg`, `buildtree` ou `check-yaml`;
- nenhuma compilação ou geração de ISO;
- nenhum teste ou validação;
- nenhum workflow ou GitHub Actions.

A máquina de preparação ainda não está operacional. O que está montado aqui é seu plano de diretórios e seus modelos de configuração, pronto para ser aplicado em uma etapa futura, mediante autorização específica.
