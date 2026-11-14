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

A entrega é enviada diretamente para a conta **MEGA** configurada nos secrets do repositório. O workflow envia a ISO integral, o checksum SHA-256 e o arquivo `build-info.txt`, organizados em:

`MEGA:/Forja-ISO/Manjaro-MATE/<kernel>/<id-da-execução>/`

Antes de iniciar uma compilação, o workflow verifica se os secrets `MEGA_EMAIL` e `MEGA_PASSWORD` estão configurados. As credenciais não são exibidas nos logs. Configure esses dois secrets em **Settings → Secrets and variables → Actions → New repository secret**. Use o e-mail da conta MEGA e a senha da conta. Não coloque as credenciais diretamente nos arquivos do repositório.

A ISO só é enviada depois que o workflow confirma que existe exatamente uma ISO válida, confere o checksum e valida os metadados. O upload usa rclone e mantém os arquivos privados na conta MEGA; nenhum link público é criado automaticamente.

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
