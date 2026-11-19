# Forja OS

## Definições do projeto

- **Base:** EndeavourOS Linux.
- **Instalador:** manter o Calamares do EndeavourOS, incluindo fork, módulos e configurações necessários.
- **Ambiente gráfico:** MATE como único ambiente gráfico.
- **Aparência:** Materia Dark, ícones Papirus e cursor Bibata.
- **Área de trabalho:** fundo preto puro (#000000), sem wallpaper de terceiros ou do EndeavourOS.
- **Aplicativos:** Firefox, Ferdium e Shelly.

## Regras

- Trabalhar somente neste repositório.
- Não incluir outro ambiente gráfico nem aplicativos fora da lista definida.
- Preservar os componentes funcionais do EndeavourOS, especialmente Calamares.
- Não declarar compilação ou validação concluída sem evidência reproduzível.

## Estrutura implementada

- `build/packages.mate`: seleção inicial de pacotes MATE, LightDM e aparência.
- `build/airootfs/`: configurações dconf, LightDM e GTK para a sessão Forja.
- `scripts/build-forja-iso.sh`: preparação do framework EndeavourOS, adaptação do perfil, construção de pacotes locais e chamada do mkarchiso.
- `scripts/validate-build.sh`: validação estática dos arquivos, revisões fixadas e sintaxe Bash.
- `docs/ENDEAVOUROS-AUDIT.md`: auditoria do framework upstream.

## Revisões upstream fixadas

- EndeavourOS-ISO: `90376d8f52ab19e19073eed33d6f36c46ec7c409`.
- PKGBUILDS EndeavourOS, incluindo receita Calamares: `474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd`.
- Shelly-ALPM: `6840658b19d72205c38bd320c1cef6ff3076bc7c`.

## Como compilar

Use EndeavourOS ou Arch Linux com os repositórios EndeavourOS habilitados, arquitetura x86_64, rede, sudo, base-devel e espaço livre amplo. Recomendação inicial: pelo menos 40 GiB livres.

Na raiz do repositório:

```bash
bash scripts/build-forja-iso.sh
```

O script prepara o framework fixado, substitui a seleção KDE por MATE, aplica as configurações Forja, constrói o Calamares do fork EndeavourOS, Shelly, Ferdium e Bibata, e executa o mkarchiso. A saída esperada é `work/EndeavourOS-ISO/out/`.

Ferdium, Shelly e Bibata são construídos a partir de receitas externas. AUR é conteúdo comunitário e deve ser tratado como código de terceiros. O build registra as revisões do Shelly e do framework, mas a receita AUR do Ferdium e as receitas AUR usadas no momento do build ainda são obtidas do HEAD atual.

## Estado real

**A estrutura inicial de compilação foi adicionada ao repositório, mas ainda não foi executada em um host Arch/EndeavourOS. Nenhuma ISO foi compilada ou testada.**

A validação do GitHub Actions é estática: verifica arquivos, escopo e sintaxe. Ela não substitui makepkg, mkarchiso, boot UEFI/BIOS, teste do MATE ou instalação completa pelo Calamares em máquina virtual.

O build precisa ser executado em um host Arch/EndeavourOS com os repositórios EndeavourOS habilitados. O runner gratuito padrão do GitHub Actions não é tratado como ambiente de compilação de ISO.
