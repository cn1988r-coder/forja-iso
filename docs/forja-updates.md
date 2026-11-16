# Atualizações próprias da Forja

## Canais independentes

1. **EndeavourOS/Arch Linux:** kernel, bibliotecas e pacotes oficiais continuam sendo atualizados por `pacman -Syu`, usando somente os repositórios oficiais configurados no sistema.
2. **Forja Updates:** componentes exclusivos da Forja OS são consultados separadamente no repositório público `cn1988r-coder/forja-updates`.

O repositório Forja Updates **não é um repositório pacman**. Não adicionar entradas Forja ao `/etc/pacman.conf`. A indisponibilidade do GitHub não pode bloquear as atualizações do sistema-base.

## Manifesto estável

O cliente XFCE consulta:

`https://raw.githubusercontent.com/cn1988r-coder/forja-updates/main/manifests/stable.json`

Esquema inicial:

- `schema_version`: inteiro `1`.
- `channel`: `stable`.
- `artifacts`: lista de arquivos individuais.
- Cada artefato declara `name`, `edition` (`all` ou `xfce`), `url`, `sha256`, `target` e, opcionalmente, `mode`.
- URLs devem apontar para assets de GitHub Releases do repositório Forja Updates.
- O cliente aceita apenas destinos Forja previamente permitidos: `/usr/local/bin/forja-*`, `/usr/local/lib/forja/`, `/usr/share/forja/`, `/usr/share/applications/forja-*` e `/etc/skel/.config/forja/`.

## Segurança do cliente

- Valida esquema, canal, edição, URL do repositório esperado, caminho permitido e SHA-256 antes de instalar.
- Baixa e valida todos os artefatos aplicáveis antes de alterar arquivos.
- Não executa scripts ou comandos fornecidos pelo manifesto.
- Cria backup dos arquivos substituídos, pede confirmação e oferece `sudo forja-update --rollback`.
- Não altera `pacman.conf`, mirrorlists, pacotes oficiais nem componentes fora da lista permitida.
- O atualizador não instala nada quando o manifesto está ausente, inválido ou sem artefatos.

## Estado atual

A integração do cliente no perfil XFCE é uma estrutura inicial. O repositório de atualizações precisa receber manifestos e assets reais, e o fluxo precisa ser testado em uma instalação descartável antes de ser considerado pronto para uso geral. Nenhuma atualização é aplicada enquanto não houver artefatos publicados e o usuário confirmar a operação.
