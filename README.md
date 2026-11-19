# Forja OS

## Definições do projeto

- **Base:** EndeavourOS Linux.
- **Instalador:** manter o Calamares do EndeavourOS, incluindo fork, módulos e configurações necessários.
- **Ambiente gráfico:** MATE como único ambiente gráfico.
- **Aparência:** Materia Dark, ícones Papirus e cursor Bibata.
- **Área de trabalho:** fundo preto puro (#000000), sem wallpaper de terceiros ou do EndeavourOS.
- **Aplicativos:** Firefox, Ferdium, Shelly e IPTVnator.

## Regras

- Trabalhar somente neste repositório.
- Não incluir outro ambiente gráfico nem aplicativos fora da lista definida.
- Preservar os componentes funcionais do EndeavourOS, especialmente Calamares.
- Não declarar compilação ou validação concluída sem evidência reproduzível.

## Estrutura implementada

- `Dockerfile`: ambiente de build Arch Linux com repositórios EndeavourOS.
- `build/packages.mate`: seleção inicial de pacotes MATE, LightDM e aparência.
- `build/airootfs/`: configurações dconf, LightDM e GTK para a sessão Forja, greeter escuro com Materia/Papirus/Bibata e launcher próprio do instalador offline Calamares. O cleaner do instalador remove o launcher e o autologin live do sistema instalado.
- `scripts/build-container.sh`: executa o build isolado via Docker/Podman.
- `scripts/build-forja-iso.sh`: adapta o framework fixado, remove o Welcome KDE/XFCE e utilitários KDE, prepara o Calamares offline, constrói os pacotes locais (incluindo IPTVnator) e chama o mkarchiso.
- `scripts/validate-build.sh`: validação estática de arquivos, revisões e sintaxe Bash.
- `docs/ENDEAVOUROS-AUDIT.md`: auditoria do framework upstream.

## Revisões upstream fixadas

- EndeavourOS-ISO: `90376d8f52ab19e19073eed33d6f36c46ec7c409`.
- PKGBUILDS EndeavourOS: `474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd`.
- Shelly-ALPM: `6840658b19d72205c38bd320c1cef6ff3076bc7c`.

## Como compilar

No Manjaro ou em outra distribuição com Docker/Podman instalado, execute na raiz:

```bash
bash scripts/build-container.sh
```

Requisitos: x86_64, internet, pelo menos 40 GiB livres no disco e 8 GiB de RAM recomendados. O container executa o build em Arch Linux com os repositórios EndeavourOS configurados.

Também é possível compilar diretamente em EndeavourOS/Arch com os repositórios EndeavourOS:

```bash
bash scripts/build-forja-iso.sh
```

A ISO deve aparecer em `work/EndeavourOS-ISO/out/`.

Ferdium, Shelly, IPTVnator e Bibata são construídos a partir de receitas externas. AUR é conteúdo comunitário, não binários oficiais. As revisões do framework e do Shelly são fixadas, mas as receitas AUR de Ferdium e Bibata são obtidas do HEAD no momento do build.

## Estado real

**A estrutura inicial de compilação foi adicionada e a validação estática do GitHub Actions passou. Ainda não foi executada uma compilação real e nenhuma ISO foi gerada ou testada.**

A validação automatizada verifica arquivos, escopo e sintaxe. Não comprova makepkg, mkarchiso, boot UEFI/BIOS, sessão MATE ou instalação completa pelo Calamares em máquina virtual.
