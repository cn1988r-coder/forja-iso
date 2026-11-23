# GitHub Actions: preparação do ambiente virtual Manjaro

## Objetivo

Preparar, sob demanda, um ambiente temporário no GitHub Actions para o trabalho futuro da VENOM OS XFCE. O runner hospedado pelo GitHub fornece a infraestrutura de execução; um contêiner `manjarolinux/base` fornece o ambiente Manjaro isolado.

Workflow: `.github/workflows/venom-preparacao-manjaro.yml`

O workflow é exclusivamente manual (`workflow_dispatch`). Não é disparado por push, pull request ou agendamento.

## O que a preparação está configurada para fazer

Quando alguém iniciar manualmente este workflow:

1. Usar um runner hospedado `ubuntu-24.04`.
2. Instalar no runner ferramentas de virtualização QEMU/OVMF e utilitários de manipulação de imagens.
3. Baixar a imagem de contêiner `manjarolinux/base:latest`.
4. Dentro do contêiner Manjaro, atualizar os pacotes do ambiente e instalar `git` e `manjaro-tools-iso-git`, conforme o procedimento documentado pelo Manjaro.
5. Criar diretórios temporários separados para fonte, cache, chroots (somente diretório vazio), logs, saída, perfis e configurações.
6. Clonar o repositório oficial de perfis Manjaro em `https://code.manjaro.org/profiles-and-settings/iso-profiles.git`.
7. Copiar os modelos locais de configuração do projeto e ajustar o caminho do checkout de perfis.
8. Registrar o commit da VENOM OS e as informações da preparação.
9. Guardar os arquivos resultantes como artefato do workflow por 14 dias.

Referências do procedimento de ferramentas e perfis:
- https://wiki.manjaro.org/index.php?title=Build_Manjaro_ISOs_with_buildiso
- https://code.manjaro.org/profiles-and-settings/iso-profiles
- https://github.com/manjaro/manjaro-docker

## Limites técnicos importantes

- O contêiner Manjaro é um ambiente de preparação de ferramentas, não uma máquina virtual completa com boot gráfico.
- QEMU e OVMF são instalados no runner para uma futura fase de virtualização. Nenhuma máquina virtual é iniciada nesta preparação.
- Criar o diretório `chroots` não cria nem inicia um chroot.
- O checkout de perfis oficiais é apenas obtenção de referência; não executa análise, validação ou build.
- O runner e o contêiner são descartáveis ao fim do job. O artefato preserva os arquivos de preparação, não uma máquina virtual ligada nem um ambiente Manjaro persistente.
- A imagem `latest` pode mudar ao longo do tempo. O relatório deve ser associado ao commit do projeto e à execução que o gerou.

## Proibições mantidas

Este workflow não pode executar:

- `buildiso`, `buildpkg`, `buildtree` ou `check-yaml`;
- compilação ou construção de pacotes;
- criação ou inicialização de chroots;
- geração de ISO;
- inicialização de QEMU ou de qualquer máquina virtual;
- testes automatizados ou manuais;
- validações técnicas, verificações de dependências ou verificações de integridade;
- publicação ou distribuição de artefatos do sistema.

A instalação de ferramentas e a organização de arquivos são preparação de ambiente, não evidência de que a VENOM OS funciona.

## Estado

- Workflow configurado no repositório: sim.
- Workflow executado nesta alteração: não.
- Ambiente virtual efetivamente preparado: não, depende de execução manual futura do workflow.
- Artefato de preparação produzido: não.
- Compilação, ISO, testes e validações: não executados e continuam proibidos.
