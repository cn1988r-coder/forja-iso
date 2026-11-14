# Arquivos auxiliares legados

A compilação oficial na nuvem é iniciada pelo workflow `Build Forja ISO`, definido em `.github/workflows/build-iso.yml`, usando os scripts da raiz do repositório.

Este diretório mantém:
- `ci/shelly/`: PKGBUILD e arquivos auxiliares necessários para compilar Shelly.
- `forja_agent.py`: agente local antigo, separado do workflow de compilação na nuvem. Ele ainda valida apenas MATE e não é o motor usado pelo workflow atual.

Os scripts de compilação duplicados em `ci/` são cópias legadas. Para builds na nuvem, use somente os scripts da raiz.
