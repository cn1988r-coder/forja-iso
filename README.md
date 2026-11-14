# Forja de ISO

Compilador de ISOs x86_64 para **Arch Linux** e **Manjaro**, executado em GitHub Actions.

## Opções

- **Distribuição:** Arch Linux ou Manjaro.
- **Arch Linux:** MATE, XFCE ou GNOME.
- **Manjaro:** exclusivamente MATE.
- **Kernel:** LTS ou latest.

## Estado atual da compilação

O repositório contém atualmente o workflow **Validate Forja sources**, que executa verificações e pré-validações sem gerar uma ISO. Ainda não existe um workflow **Build Forja ISO** para iniciar a compilação em nuvem e publicar o artefato. Essa automação precisa ser criada e validada antes de ser possível iniciar uma compilação pela aba Actions.

## Estrutura

- Os scripts na raiz são a entrada oficial do workflow.
- `eu-project-iso-main/ci/shelly` contém o PKGBUILD e os arquivos auxiliares usados para compilar Shelly.
- A compilação usa imagens de contêiner da distribuição escolhida.

## Validação

A conclusão do workflow e a geração do checksum não substituem o teste de inicialização. Antes de distribuir uma ISO, teste BIOS/UEFI, sessão gráfica, rede e instalador em uma máquina virtual.
