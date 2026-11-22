# Construção da ISO e instalação offline

A VENOM OS é construída usando Archiso. O GitHub hospeda apenas o código-fonte e executa a construção. Não existe repositório de pacotes VENOM para atualizações do sistema instalado.

## 1. Pacotes AUR necessários à ISO

O processo de construção compila os pacotes AUR necessários e reúne seus arquivos de pacote para a instalação offline. Antes de usar qualquer PKGBUILD, revise seu conteúdo e os arquivos auxiliares.

Pacotes AUR usados atualmente:
- `libpamac-aur`
- `pamac-aur`
- `ferdium-bin`

As dependências oficiais de compilação e execução devem vir dos repositórios oficiais do Arch Linux. O workflow instala as dependências gráficas oficiais de Pamac, compila `libpamac-aur`, instala esse pacote no ambiente descartável de construção para que o Pacman resolva a dependência de `pamac-aur`, e então constrói os demais pacotes.

O pacote AUR antigo `archlinux-appstream-data-pamac` não deve ser usado.

## 2. Conjunto temporário para instalação offline

O script `scripts/prepare-offline-repo.sh` baixa dos repositórios oficiais Arch Linux os pacotes e dependências necessários às edições XFCE e MATE e inclui os pacotes AUR compilados.

O resultado em `build/offline-repo/` é um conjunto temporário de pacotes e índice local, incorporado à ISO exclusivamente para a instalação sem internet. Seu identificador é `iso-offline`. Ele não é uma fonte de atualização da VENOM OS e não será configurado no sistema instalado.

Valide o conjunto com:

```bash
bash scripts/validate-offline-repo.sh
```

## 3. Sistema instalado e atualizações

Durante a instalação, o backend usa o conjunto offline embarcado na mídia. Ao terminar, ele instala a configuração oficial do Pacman no sistema de destino.

Depois do primeiro boot:
- Pamac é a interface gráfica de gerenciamento;
- os pacotes oficiais vêm dos repositórios oficiais do Arch Linux;
- os pacotes comunitários são obtidos pelo AUR através do suporte AUR do Pamac.

Nenhum repositório ou atualizador próprio da VENOM OS deve permanecer no sistema instalado.

## 4. Construção da ISO

Em ambiente Arch Linux com as ferramentas necessárias:

```bash
sudo pacman -S --needed archiso meson ninja gcc pkgconf
sudo VENOM_ISO_BUILD_AUTHORIZED=YES bash scripts/build-venom-iso.sh
```

O processo valida o perfil, o conjunto offline e o instalador, compila a imagem com Archiso e grava a ISO e seu SHA-256 em `out/`.
