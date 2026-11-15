# Forja OS

Projeto de construção das bases **Ubuntu LTS** e **Manjaro**, com módulos de desktop separados.

## Bases mantidas

- **Ubuntu LTS:** base independente, construída por `build-ubuntu.sh`. Atualmente gera o sistema-base sem ambiente gráfico.
- **Manjaro:** compilação da ISO MATE por `build-manjaro.sh`, com workflow próprio em nuvem.
- **Arch Linux:** removido do escopo. Não há perfil ou opção de compilação Arch.

## Manjaro MATE

O workflow **Build Manjaro MATE ISO** executa a compilação em nuvem, gera a imagem SquashFS com compressão XZ, verifica o checksum SHA-256 e publica a ISO como um único arquivo.

A compilação só deve ser considerada concluída após verificar o arquivo ISO, seu checksum e o download. O teste de inicialização em BIOS/UEFI e UEFI, sessão MATE, LightDM, rede, Bluetooth e instalador ainda precisa ser realizado em máquina virtual antes da distribuição.

## Estrutura

- `build-cloud.sh`: entrada da compilação Manjaro MATE em contêiner.
- `build-manjaro.sh`: perfil e compilação Manjaro MATE.
- `build-ubuntu.sh`: geração da base Ubuntu LTS.
- `.github/workflows/build-manjaro-mate.yml`: compilação Manjaro, verificação e publicação.
- `.github/workflows/validate.yml`: validação estática e pré-validação Manjaro MATE.
- `desktops/`: módulos e manifestos de pacotes XFCE/MATE para as bases suportadas.
- `forja-pamac-pacman/`: Forja Software para Manjaro.
- `forja-pamac-ubuntu/`: Forja Software para Ubuntu.

As bases Ubuntu e Manjaro permanecem separadas. Ferramentas e pacotes de uma base não devem ser misturados com a outra.
