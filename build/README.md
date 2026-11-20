# Construção da VENOM OS

A construção usa Arch Linux oficial e o pacote oficial `archiso`. Não são configurados repositórios, chaves ou mirrors de distribuições derivadas.

## Requisitos

- Docker ou Podman para o método isolado, ou host Arch Linux.
- x86_64.
- Pelo menos 40 GiB livres.
- Internet e 8 GiB de RAM recomendados.

## Método isolado

```bash
bash scripts/build-container.sh
```

O Dockerfile usa a imagem `archlinux:latest`, atualiza o sistema pelo Pacman oficial e instala `archiso`. O script prepara o perfil VENOM e chama `mkarchiso`.

## Método direto em Arch Linux

Instale os pacotes de construção necessários pelos repositórios oficiais e execute:

```bash
bash scripts/build-venom-iso.sh
```

A ISO será criada em `work/out/`.

## Limite atual

O perfil e o mecanismo de construção estão migrando para Archiso. A integração independente do Calamares e a instalação da imagem VENOM ainda não foram concluídas. Não existe ISO aprovada para instalação até que build real, boot e instalação sejam validados.
