# GitHub Actions: ambiente de preparação Ubuntu

## Objetivo

A preparação inicial da VENOM OS foi direcionada para um runner Ubuntu hospedado pelo próprio GitHub Actions, sem depender de uma máquina Manjaro externa ou de um runner self-hosted.

Workflow: `.github/workflows/venom-preparacao-manjaro.yml`

## O que o workflow está configurado para fazer

Quando for autorizado e iniciado manualmente, o workflow:

1. Utiliza o runner hospedado `ubuntu-24.04`.
2. Obtém o código do repositório VENOM OS.
3. Instala somente utilitários básicos disponíveis nos repositórios Ubuntu: Git, curl, wget, xz-utils, squashfs-tools, dosfstools e mtools.
4. Cria diretórios de organização para fonte, cache, chroots, logs e saída. Criar o diretório chamado `chroots` não cria nem inicia um chroot.
5. Registra o caminho do checkout do projeto no workspace.

## Limite importante do Ubuntu

O runner Ubuntu não é uma instalação Manjaro. Esta preparação não instala `manjaro-tools`, não configura uma base Manjaro e não torna o ambiente pronto para construir uma ISO Manjaro.

O runner hospedado pelo GitHub é temporário: o ambiente e os arquivos locais do job são descartados ao final da execução. Portanto, os diretórios criados não constituem armazenamento persistente entre execuções.

A Action oficial `manjaro-iso-action` não foi adicionada nem chamada. Ela contém etapas que compilam componentes e executam `buildiso`, operações que permanecem bloqueadas nesta etapa.

## Bloqueios mantidos

Este workflow não deve receber nem executar:

- `buildiso`
- `buildpkg`
- `buildtree`
- `check-yaml`
- criação ou inicialização de chroots
- compilação de ferramentas ou pacotes
- geração de ISO
- testes ou validações técnicas
- publicação ou upload de artefatos

Essas atividades continuam bloqueadas e exigem autorização explícita separada.

## Estado

- Configuração do workflow para runner Ubuntu hospedado pelo GitHub: registrada no repositório.
- Workflow executado: não.
- Ferramentas básicas instaladas no runner: não, pois nenhuma execução foi iniciada.
- Ambiente Manjaro de construção: não configurado por este workflow.
- Compilação, ISO, testes e validações: bloqueados e não executados.
