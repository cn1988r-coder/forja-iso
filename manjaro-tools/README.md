# Estrutura de preparação Manjaro Tools

Este diretório documenta e organiza a preparação futura do ambiente de trabalho da VENOM OS. Ele **não executa ferramentas**, não instala pacotes e não inicia qualquer processo de construção.

## 1. Ferramentas oficiais de referência

O conjunto de ferramentas do Manjaro é dividido em:

- `manjaro-tools-base`: componentes básicos e ferramentas de chroot.
- `manjaro-tools-pkg`: auxiliares de pacotes, incluindo ferramentas de trabalho com pacotes.
- `manjaro-tools-iso`: ferramentas relacionadas aos perfis e à preparação de imagens, incluindo `buildiso`.

A documentação do Manjaro também apresenta o pacote `manjaro-tools-iso-git` como ponto de instalação no guia de criação de ISO. A seleção e a instalação efetivas dos pacotes no computador de preparação ficam para uma etapa futura, autorizada separadamente.

Referências oficiais:
- https://wiki.manjaro.org/index.php?title=Manjaro-tools
- https://wiki.manjaro.org/index.php?title=Build_Manjaro_ISOs_with_buildiso
- https://code.manjaro.org/tools/manjaro-tools

## 2. Organização existente do projeto

A estrutura atual do repositório segue a separação de perfis do Manjaro:

```text
manjaro/
├── base/
│   ├── profile.conf
│   └── Packages-Root
└── xfce/
    ├── profile.conf
    ├── Packages-Root
    ├── Packages-Desktop
    ├── desktop-overlay/
    └── PAINEL.md
```

- `manjaro/base` representa a base Manjaro sem ambiente gráfico.
- `manjaro/xfce` representa a edição XFCE construída em camada sobre a base.
- `Packages-Root` da edição XFCE permanece uma cópia do manifesto da base.
- `Packages-Desktop` mantém os pacotes específicos do ambiente XFCE.
- `desktop-overlay` guarda as configurações aplicadas ao perfil do usuário.

A base não deve receber pacotes de desktop nem personalizações visuais do XFCE.

## 3. Separação entre máquina de preparação e sistema final

As ferramentas de desenvolvimento/build pertencem ao computador de preparação. Elas **não** devem ser adicionadas aos manifestos `Packages-Root` ou `Packages-Desktop` da VENOM OS.

A futura configuração local do Manjaro Tools deverá ficar no perfil de usuário do computador de preparação, conforme a documentação oficial:

- Configuração do usuário: `~/.config/manjaro-tools/manjaro-tools.conf`.
- Configuração de perfis: `iso-profiles.conf`, apontando para a localização real do checkout de perfis utilizado.
- Configuração global em `/etc/manjaro-tools`: preservar os padrões do pacote; não modificar sem necessidade documentada.

Nenhum caminho absoluto da máquina foi presumido neste repositório. A configuração local só deverá ser preenchida quando o caminho real do checkout e a versão das ferramentas estiverem definidos.

## 4. Perfis e compatibilidade

O formato dos perfis deve permanecer alinhado ao repositório oficial `iso-profiles` do Manjaro. Os arquivos de referência são:

- `profile.conf`
- `Packages-Root`
- `Packages-Desktop`
- `Packages-Mhwd`, quando necessário ao perfil
- `Packages-Live`, quando houver pacotes exclusivos da sessão live
- `root-overlay/`, `desktop-overlay/` e `live-overlay/`, conforme a função de cada arquivo

Não criar listas ou overlays fictícios apenas para preencher a estrutura. Arquivos adicionais serão incluídos somente quando houver necessidade definida para a VENOM OS.

Referência oficial: https://code.manjaro.org/profiles-and-settings/iso-profiles

## 5. Calamares

A VENOM OS deverá utilizar exclusivamente o pacote e os recursos do Calamares disponibilizados pelos repositórios oficiais do Manjaro, na versão compatível com a base utilizada.

- Não baixar código-fonte do Calamares upstream.
- Não compilar Calamares.
- Não substituir o pacote do Manjaro por pacote externo.
- Não criar uma distribuição paralela do instalador.
- Configurações específicas deverão respeitar a versão e a organização adotadas pelo Manjaro.

A inclusão e o ajuste do instalador no perfil serão tratados em etapa própria, sem alterar agora os manifestos existentes.

## 6. Limites desta etapa

Este diretório é documentação e preparação estrutural. Nesta etapa:

- Nenhum pacote foi instalado.
- Nenhum repositório externo foi clonado.
- Nenhum chroot foi criado.
- Nenhuma ferramenta de build foi executada.
- Nenhum perfil foi compilado.
- Nenhuma ISO foi gerada.
- Nenhum teste ou validação foi executado.
- Nenhum workflow ou GitHub Actions foi iniciado.

**A proibição de compilação, construção de ISO, testes e validações permanece absoluta.** A estrutura apenas registra como o ambiente futuro deverá ser organizado, sem iniciar essas operações.
