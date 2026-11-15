# Forja OS

Distribuição própria baseada em **Manjaro**, com uma única edição gráfica: **XFCE**.

## Edição única: XFCE

- XFCE enxuto, com painel inferior e Docklike.
- Whisker Menu personalizado com identidade visual Forja.
- Adwaita Dark, decoração Materia Dark, Papirus Dark com pastas cinza e cursor Bibata.
- LightDM com sessão XFCE como padrão.
- Forja Store integrada ao sistema Live e à instalação final.
- Indicador de atualizações no painel XFCE.
- Rede, Bluetooth, áudio PipeWire, Firefox e Calamares.
- Instalação em **Btrfs por padrão** pelo Calamares, com compressão transparente Zstandard (`zstd:1`); ext4 e f2fs continuam selecionáveis.

## Base e compilação

- **Base do sistema:** Manjaro.
- **Perfil:** `manjaro/forja-xfce`, derivado do perfil oficial Manjaro XFCE.
- **Construtor:** `build-cloud.sh` chama `build-manjaro.sh` em um contêiner Manjaro.
- **Dockerfile de validação:** `desktops/xfce/Dockerfile` verifica sintaxe, arquivos SVG/XML, entradas de desktop e integração da Forja Store. Ele não compila a ISO.
- **Validação de perfil:** executada com `FORJA_PREFLIGHT_ONLY=1`, sem chamar `buildiso`.

## Forja Store

A Forja Store é a interface visual personalizada do **Pamac Manager GTK4/libadwaita**. O backend continua sendo o Pamac/libpamac original, com repositórios Manjaro, AUR e suporte Flatpak. A interface recebe identidade visual própria em tons escuros e neutros, cartões de aplicativos, navegação e detalhes de instalação. O indicador de atualizações permanece integrado ao painel XFCE.

A compilação usa uma revisão upstream fixa do Pamac e preserva o código-fonte correspondente no sistema. A compilação da interface será validada no ambiente Manjaro antes de qualquer geração de ISO. Ainda será necessário testar a loja em uma sessão XFCE real, incluindo pesquisa, detalhes, instalação, remoção, AUR, Flatpak e atualizações.

## Estado da entrega

O projeto está em fase de revisão e validação do código XFCE. Nenhuma ISO final deve ser anunciada como pronta até que a compilação, o checksum, a inicialização Live e a instalação pelo Calamares sejam efetivamente testados.

A ISO final deverá ser entregue como um único arquivo `.iso`, completo e sem divisão em partes.
