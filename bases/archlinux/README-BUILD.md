# Construção da Forja OS Arch Linux MATE

O perfil oficial de boot é obtido do projeto Archiso upstream, fixado no commit
`8e3ead17e1e5cfde503534d23be918b8787d3dd3`. O script `build-profile.sh`
combina esse perfil releng com os pacotes e personalizações Forja.

## Host de build

Use um host Arch Linux x86_64 atualizado, com espaço livre amplo (recomendado
40 GB ou mais), conexão estável e os pacotes `archiso` e `git`. Não faça o
build no Dell Inspiron com SSD de 128 GB.

## Build local

```bash
sudo pacman -Syu
sudo pacman -S --needed archiso git
sudo bases/archlinux/build-profile.sh
```

A ISO será gravada em `out/`. O script baixa o Archiso upstream fixado,
prepara um perfil de trabalho descartável e chama `mkarchiso`.

## Instalação

A sessão live contém o atalho **Instalar Forja OS**, que abre o instalador
oficial Archinstall em terminal. Archinstall é um instalador interativo de
texto, não um instalador gráfico Calamares. O destino, particionamento,
bootloader, usuário e formatação devem ser escolhidos cuidadosamente durante
a instalação.

## Estado

Este é o primeiro fluxo integrado de construção, ainda experimental. O build
automatizado e a instalação em VM precisam passar antes de declarar a ISO
validada. A data de instalação precisa ser ligada ao encerramento real do
instalador Archinstall; até existir esse hook confirmado, o Sobre do Forja OS
deve informar data indisponível.
