# Forja de ISO

Compilador de ISO x86_64 para **Manjaro MATE**, com preparação e compilação em nuvem.

## Opções disponíveis

- **Distribuição:** exclusivamente Manjaro.
- **Ambiente gráfico:** exclusivamente MATE.
- **Kernel:** LTS ou latest.
- **Manjaro MATE:** Shelly, Firefox, LightDM com Slick Greeter, Bluetooth, Materia Dark e cursor Bibata.

## Compilação Manjaro MATE

O workflow **Build Manjaro MATE ISO** executa a compilação em nuvem, verifica o checksum SHA-256 e publica a ISO completa como artefato temporário do GitHub Actions.

Há duas formas de iniciar a compilação:

1. **Pela aba Actions:** execute manualmente o workflow e selecione o kernel LTS ou latest.
2. **Por integração com a página da Forja:** envie um evento `repository_dispatch` do tipo `forja-build`, com `client_payload.kernel` definido como `lts` ou `latest`. Esse evento usa exatamente o mesmo workflow e os mesmos scripts da compilação manual.

Exemplo do corpo do evento para a integração:

```json
{
  "event_type": "forja-build",
  "client_payload": {
    "kernel": "lts"
  }
}
```

A ISO completa fica disponível no artefato da execução por **24 horas**. O resumo do workflow apresenta o link de download. O download do artefato exige acesso ao repositório no GitHub.

## Estrutura

- `build-cloud.sh`: entrada comum para a compilação em contêiner.
- `build-manjaro.sh`: perfil e compilação Manjaro MATE.
- `build-shelly.sh`: compilação de Shelly e Bibata para o repositório local usado durante a geração da ISO.
- `.github/workflows/validate.yml`: validação estática e pré-validação Manjaro MATE sem gerar ISO.
- `.github/workflows/build-manjaro-mate.yml`: compilação em nuvem, acionável manualmente ou pela integração da página, com publicação temporária do artefato no GitHub Actions.

## Verificação final

Mesmo com a ISO gerada e checksum válido, ainda é necessário testar a inicialização em BIOS/UEFI, sessão MATE, LightDM, Firefox, Shelly, rede, Bluetooth e instalador Calamares em máquina virtual antes de considerar a imagem pronta para distribuição.
