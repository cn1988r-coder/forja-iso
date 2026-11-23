# GitHub Actions: ambiente de preparação Manjaro

## Objetivo

Este documento descreve a preparação do ambiente de execução da VENOM OS no GitHub Actions. O workflow de preparação instala as ferramentas de trabalho do Manjaro e organiza os diretórios para uso futuro.

## Limitação da infraestrutura

O GitHub Actions não oferece um runner hospedado com Manjaro Linux como sistema operacional nativo. Para executar as ferramentas oficiais em um ambiente Manjaro real, o workflow foi direcionado a um runner próprio (self-hosted), instalado com Manjaro Linux e registrado no repositório com as etiquetas:

- `self-hosted`
- `Linux`
- `X64`
- `manjaro`

O runner precisa estar disponível e ter o serviço do GitHub Actions configurado. O usuário de serviço deve ter permissão administrativa não interativa para executar a instalação via `sudo pacman`. Essa máquina/runner ainda precisa ser provisionada e registrada; criar o workflow no repositório não cria automaticamente o host.

## Workflow criado

Arquivo: `.github/workflows/venom-preparacao-manjaro.yml`

O workflow só pode ser iniciado manualmente por `workflow_dispatch`. Quando executado em um runner Manjaro devidamente registrado, ele:

1. Obtém o repositório VENOM OS.
2. Atualiza o sistema e instala `git` e `manjaro-tools-iso-git`, conforme o guia oficial do Manjaro.
3. Cria os diretórios de workspace para fonte, cache, chroots, logs e saída.
4. Registra o caminho local do checkout do projeto no workspace.

## Bloqueio de construção

Este workflow não contém etapas de compilação ou construção. Não executar nem adicionar aqui:

- `buildiso`
- `buildpkg`
- `buildtree`
- `check-yaml`
- criação de chroot
- geração de ISO
- testes ou validações técnicas
- publicação ou upload de artefatos

A preparação e a futura construção permanecem separadas. Qualquer workflow futuro de compilação/validação deverá ser criado somente após autorização explícita.

## Estado

- Workflow de preparação: criado no repositório.
- Execução do workflow: não iniciada.
- Runner Manjaro self-hosted: ainda precisa ser provisionado e registrado.
- Instalação das ferramentas: não executada.
- Compilação, ISO, testes e validações: bloqueados e não executados.

## Referência oficial

O guia do Manjaro para criação de imagens recomenda um sistema Manjaro atualizado e a instalação de `manjaro-tools-iso-git` e `git` antes do uso das ferramentas. O workflow segue apenas a parte de preparação, sem executar a construção.

- https://wiki.manjaro.org/index.php?title=Build_Manjaro_ISOs_with_buildiso
- https://code.manjaro.org/tools/manjaro-tools
