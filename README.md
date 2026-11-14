# Forja de ISO

Compilador de ISO x86_64 para **Manjaro MATE**, com preparação e compilação em nuvem.

## Opções disponíveis

- **Distribuição:** exclusivamente Manjaro.
- **Ambiente gráfico:** exclusivamente MATE.
- **Kernel:** LTS ou latest.
- **Manjaro MATE:** Shelly, Firefox, LightDM com Slick Greeter, Bluetooth, Materia Dark e cursor Bibata.

## Compilação Manjaro MATE

O workflow **Build Manjaro MATE ISO** fica na seção `Actions` e é iniciado manualmente. Ele permite selecionar o kernel LTS ou latest, prepara o ambiente de compilação, gera a ISO e verifica o checksum SHA-256.

A ISO completa é publicada como um artefato temporário do próprio GitHub Actions, sem divisão em partes e sem envio para Google Drive ou MEGA. O artefato é configurado para expirar após **1 dia (24 horas)**. O link de download aparece no resumo da execução do workflow.

O GitHub pode enviar automaticamente uma notificação por e-mail quando a execução terminar. Para recebê-la, a conta precisa estar inscrita nas notificações do repositório e com **Actions → Email** ativado nas configurações de notificações do GitHub. O e-mail de notificação leva à execução; o link direto para a ISO fica no resumo dessa execução. O download exige login no GitHub e permissão de leitura do repositório.

## Estrutura

- `build-cloud.sh`: entrada comum para a compilação em contêiner.
- `build-manjaro.sh`: perfil e compilação Manjaro MATE.
- `build-shelly.sh`: compilação de Shelly e Bibata para o repositório local usado durante a geração da ISO.
- `eu-project-iso-main/ci/shelly/`: fontes e arquivos de configuração usados na compilação do pacote Shelly.
- `.github/workflows/validate.yml`: validação estática e pré-validação Manjaro MATE sem gerar ISO.
- `.github/workflows/build-manjaro-mate.yml`: compilação manual da ISO Manjaro MATE em nuvem e publicação temporária do artefato no GitHub Actions.

## Verificação final

Mesmo com a ISO gerada e checksum válido, ainda é necessário testar a inicialização em BIOS/UEFI, sessão MATE, LightDM, Firefox, Shelly, rede, Bluetooth e instalador Calamares em máquina virtual antes de considerar a imagem pronta para distribuição.
