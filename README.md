# VENOM OS

## Arquitetura

- **Base:** Arch Linux oficial.
- **Construção da ISO:** Archiso oficial, com perfil próprio em `build/archiso/`.
- **Ambiente gráfico:** MATE como único desktop.
- **Gerenciador de sessão:** LightDM.
- **Aparência:** Materia Dark, Papirus, Bibata e Noto Sans, conforme os pacotes disponíveis.
- **Identidade:** VENOM OS, visual monocromático escuro.
- **Atualização normal do sistema:** Pacman dos repositórios oficiais Arch (`sudo pacman -Syu`).
- **Repositório próprio:** VENON, independente do Pacman, acionado manualmente.

## Regras do projeto

- O sistema deve ser construído diretamente sobre Arch Linux.
- Não incorporar distribuições derivadas, seus repositórios, chaves, scripts ou ferramentas.
- O sistema Live e o instalado devem ser VENOM OS, com MATE e LightDM.
- Não alterar a branch `main`.
- Não declarar build, boot ou instalação validados sem evidência reproduzível.

## Construção

Em Manjaro ou outra distribuição com Docker/Podman:

```bash
bash scripts/build-container.sh
```

Em um host Arch Linux com os pacotes de build instalados:

```bash
bash scripts/build-venom-iso.sh
```

O perfil é preparado a partir dos arquivos oficiais instalados pelo pacote `archiso` em `/usr/share/archiso/configs/releng`, e então recebe o perfil e as personalizações próprias da VENOM. A compilação é feita pelo `mkarchiso` oficial. A configuração de Pacman do perfil contém somente os repositórios oficiais Arch.

A ISO é gravada em `work/out/`.

## Estado real e bloqueios

**A migração do mecanismo de construção para Archiso direto está em andamento.** O perfil Archiso próprio, o container Arch e o script de build direto são a nova estrutura de construção.

**A ISO ainda não foi compilada nem testada.** A integração final do Calamares independente, incluindo os fluxos online/offline que instalam a imagem completa da VENOM, ainda precisa ser concluída. Portanto, esta revisão do código não deve ser tratada como ISO pronta para instalação.

Não foram executados build, testes automatizados, VM ou GitHub Actions nesta etapa.
