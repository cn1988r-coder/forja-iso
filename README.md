# Forja de ISO

Compilador de ISO x86_64 para **Manjaro MATE**, com preparação e compilação em nuvem.

## Opções disponíveis

- **Distribuição:** exclusivamente Manjaro.
- **Ambiente gráfico:** exclusivamente MATE.
- **Kernel:** LTS ou latest.
- **Manjaro MATE:** Shelly, Firefox, LightDM com Slick Greeter, Bluetooth, Materia Dark e cursor Bibata.

## Compilação Manjaro MATE

O workflow **Build Manjaro MATE ISO** executa a compilação em nuvem, gera a imagem SquashFS com compressão XZ, verifica o checksum SHA-256 e publica a ISO completa como um arquivo de uma GitHub Release.

A página da Forja consulta a fila automaticamente. Quando a ISO termina de compilar e passa na verificação, o workflow cria uma publicação permanente no repositório e grava no pedido o endereço direto do arquivo. O painel passa a exibir **BAIXAR ISO COMPLETA** e mantém o resultado após atualizar a página.

Se a compilação, a validação ou a publicação falhar, o workflow marca a solicitação como **FALHOU**, envia uma mensagem ao painel e fornece um link para os logs da execução.

A release é pública porque este repositório é público. O link de download não depende do prazo de retenção dos artefatos temporários do GitHub Actions.

Há duas formas de iniciar a compilação:

1. **Pela aba Actions:** execute manualmente o workflow e selecione o kernel LTS ou latest.
2. **Pela página da Forja:** envie uma solicitação pelo painel; o worker consulta a fila automaticamente a cada cinco minutos.

## Estrutura

- `build-cloud.sh`: entrada comum para a compilação em contêiner.
- `build-manjaro.sh`: perfil e compilação Manjaro MATE.
- `build-shelly.sh`: compilação de Shelly e Bibata para o repositório local usado durante a geração da ISO.
- `.github/workflows/validate.yml`: validação estática e pré-validação Manjaro MATE sem gerar ISO.
- `.github/workflows/build-manjaro-mate.yml`: compilação em nuvem, verificação de integridade, publicação da release e atualização do painel da Forja.

## Verificação final

Mesmo com a ISO gerada e checksum válido, ainda é necessário testar a inicialização em BIOS/UEFI, sessão MATE, LightDM, Firefox, Shelly, rede, Bluetooth e instalador Calamares em máquina virtual antes de considerar a imagem pronta para distribuição.
