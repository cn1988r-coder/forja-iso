# Forja de ISO

Compilador de ISOs x86_64 para **Arch Linux** e **Manjaro**, executado em GitHub Actions.

## Opções

- **Distribuição:** Arch Linux ou Manjaro.
- **Ambiente gráfico:** MATE, XFCE ou GNOME.
- **Kernel:** LTS ou latest.

## Como iniciar uma compilação

1. Abra a aba **Actions** do repositório.
2. Selecione **Build Forja ISO**.
3. Clique em **Run workflow**.
4. Escolha a distribuição, o ambiente gráfico e o kernel.
5. Após a conclusão, baixe o artefato da execução.

O workflow valida a sintaxe dos scripts antes de iniciar a compilação. A ISO, o checksum SHA-256 e o arquivo de informações da build são publicados como artefato por sete dias.

## Estrutura

- Os scripts na raiz são a entrada oficial do workflow.
- `eu-project-iso-main/ci/shelly` contém o PKGBUILD e os arquivos auxiliares usados para compilar Shelly.
- `eu-project-iso-main/forja_agent.py` é um agente local legado e não participa da compilação em nuvem.
- A compilação usa imagens de contêiner da distribuição escolhida.

## Validação

A conclusão do workflow e a geração do checksum não substituem o teste de inicialização. Antes de distribuir uma ISO, teste BIOS/UEFI, sessão gráfica, rede e instalador em uma máquina virtual.
