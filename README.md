# Forja de ISO

Compilador de ISOs x86_64 para **Arch Linux** e **Manjaro**, com preparação e compilação em nuvem.

## Opções

- **Distribuição:** Arch Linux ou Manjaro.
- **Arch Linux:** MATE, XFCE ou GNOME.
- **Manjaro:** exclusivamente MATE.
- **Kernel:** LTS ou latest.
- **Manjaro MATE:** Shelly, Firefox, LightDM com Slick Greeter, Bluetooth, Materia Dark e cursor Bibata.

## Compilação Manjaro MATE

O workflow **Build Manjaro MATE ISO** está em `Actions`. Ele é iniciado manualmente, permite selecionar o kernel LTS ou latest, prepara o ambiente de compilação, gera a ISO, verifica o checksum e publica os arquivos como artefato por 7 dias.

A compilação ainda precisa ser executada e concluída com sucesso para confirmar que todos os pacotes e etapas de geração funcionam no ambiente de nuvem. A validação de código não substitui esse teste.

## Estrutura

- `build-cloud.sh`: entrada comum para a compilação em contêiner.
- `build-manjaro.sh`: perfil e compilação Manjaro MATE.
- `build-arch.sh`: perfil e compilação Arch Linux.
- `build-shelly.sh`: compilação e publicação local dos pacotes Shelly e Bibata.
- `.github/workflows/validate.yml`: validação estática e pré-validação sem gerar ISO.
- `.github/workflows/build-manjaro-mate.yml`: compilação manual da ISO Manjaro MATE em nuvem.

## Verificação final

Mesmo com a ISO gerada e checksum válido, ainda é necessário testar a inicialização em BIOS/UEFI, sessão MATE, LightDM, Firefox, Shelly, rede, Bluetooth e instalador Calamares em máquina virtual antes de considerar a imagem pronta para distribuição.
