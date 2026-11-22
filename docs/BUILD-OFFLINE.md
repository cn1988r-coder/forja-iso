# Preparação da instalação offline da VENOM OS

A mídia contém um repositório local com os pacotes e dependências das duas edições. Durante a instalação, o instalador usa exclusivamente esse repositório dentro da ISO. Depois do primeiro boot, o sistema instalado volta a usar os repositórios oficiais do Arch Linux.

## 1. Preparar os pacotes AUR

Em um ambiente Arch Linux conectado à internet, instale as ferramentas de compilação:

```bash
sudo pacman -S --needed base-devel git
```

Compile os três pacotes AUR na ordem abaixo. Execute `makepkg` como usuário comum, nunca como root. O `-si` instala o pacote compilado e as dependências oficiais necessárias para compilar o próximo.

```bash
cd /tmp
git clone https://aur.archlinux.org/libpamac-aur.git
cd libpamac-aur
makepkg -si
```

```bash
cd /tmp
git clone https://aur.archlinux.org/pamac-aur.git
cd pamac-aur
makepkg -si
```

```bash
cd /tmp
git clone https://aur.archlinux.org/ferdium-bin.git
cd ferdium-bin
makepkg -si
```

Copie os três arquivos `.pkg.tar.zst` gerados para `build/aur-packages/` no repositório VENOM OS. Os nomes internos precisam ser `libpamac-aur`, `pamac-aur` e `ferdium-bin`.

## 2. Montar e verificar o repositório offline

Na raiz do repositório VENOM OS, execute:

```bash
sudo bash scripts/prepare-offline-repo.sh
bash scripts/validate-offline-repo.sh
```

O preparador baixa do Arch Linux oficial todos os pacotes e dependências que faltam para a união das edições XFCE e MATE, inclui os pacotes AUR compilados e testa a resolução usando somente o repositório local. O resultado fica em `build/offline-repo/`.

Não apague nem edite manualmente os arquivos desse diretório. Se precisar reconstruí-lo, mova o diretório existente para outro local antes de executar novamente o preparador.

## 3. Compilar a ISO

Em um ambiente Arch Linux com `archiso`, `meson`, `ninja`, `gcc` e `pkg-config` instalados:

```bash
sudo pacman -S --needed archiso meson ninja gcc pkgconf
sudo VENOM_ISO_BUILD_AUTHORIZED=YES bash scripts/build-venom-iso.sh
```

A compilação executa os validadores, compila o instalador TUI e incorpora o repositório offline completo à mídia. A ISO e seu SHA-256 são gravados em `out/`.

## Conteúdo esperado

- Uma ISO com seleção entre VENOM OS XFCE e VENOM OS MATE.
- Firefox, Pamac e Ferdium nas duas edições.
- Instalação sem conexão com a internet.
- Após a instalação, NetworkManager e os repositórios oficiais Arch ficam disponíveis para atualizações online.
- O instalador continua sem desktop Live e preserva os arquivos de personalização existentes.
