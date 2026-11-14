# Forja de ISO

Compilador de ISOs x86_64 para **Arch Linux** e **Manjaro**, com preparação e compilação em nuvem.

## Opções disponíveis

- **Distribuição:** Arch Linux ou Manjaro.
- **Arch Linux:** MATE, XFCE ou GNOME.
- **Manjaro:** exclusivamente MATE.
- **Kernel:** LTS ou latest.
- **Manjaro MATE:** Shelly, Firefox, LightDM com Slick Greeter, Bluetooth, Materia Dark e cursor Bibata.

## Compilação Manjaro MATE

O workflow **Build Manjaro MATE ISO** fica na seção `Actions` e é iniciado manualmente. Ele permite selecionar o kernel LTS ou latest, prepara o ambiente de compilação, gera a ISO e verifica o checksum SHA-256.

A entrega é publicada em uma **GitHub Release**, não como artefato temporário do Actions. A ISO é dividida em partes menores que o limite individual de 2 GiB do GitHub Releases. Baixe todas as partes `.part-*`, o arquivo `.iso.sha256` e o `build-info.txt`.

Para reconstruir e verificar a ISO no Linux, coloque todos os arquivos na mesma pasta e execute:

```bash
cat NOME.iso.part-* > NOME.iso
sha256sum --check NOME.iso.sha256
```

O checksum precisa terminar com `OK`. Releases não expiram automaticamente. Depois de baixar e conferir os arquivos, exclua manualmente a Release se quiser liberar o espaço de armazenamento.

A validação automática do código e a pré-validação dos ambientes não substituem uma compilação real. A ISO só poderá ser considerada gerada depois que o workflow de build terminar com sucesso.

## Estrutura

- `build-cloud.sh`: entrada comum para a compilação em contêiner.
- `build-manjaro.sh`: perfil e compilação Manjaro MATE.
- `build-arch.sh`: perfil e compilação Arch Linux.
- `build-shelly.sh`: compilação de Shelly e Bibata para o repositório local usado durante a geração da ISO.
- `eu-project-iso-main/ci/shelly/`: fontes e arquivos de configuração usados na compilação do pacote Shelly.
- `.github/workflows/validate.yml`: validação estática e pré-validação sem gerar ISO.
- `.github/workflows/build-manjaro-mate.yml`: compilação manual da ISO Manjaro MATE em nuvem e publicação em GitHub Release.

## Verificação final

Mesmo com a ISO gerada e checksum válido, ainda é necessário testar a inicialização em BIOS/UEFI, sessão MATE, LightDM, Firefox, Shelly, rede, Bluetooth e instalador Calamares em máquina virtual antes de considerar a imagem pronta para distribuição.
