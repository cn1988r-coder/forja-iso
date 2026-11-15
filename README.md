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

## Base e compilação

- **Base do sistema:** Manjaro.
- **Perfil:** `manjaro/forja-xfce`, derivado do perfil oficial Manjaro XFCE.
- **Construtor:** `build-cloud.sh` chama `build-manjaro.sh` em um contêiner Manjaro.
- **Dockerfile de validação:** `desktops/xfce/Dockerfile` verifica sintaxe, arquivos SVG/XML, entradas de desktop e integração da Forja Store. Ele não compila a ISO.
- **Validação de perfil:** executada com `FORJA_PREFLIGHT_ONLY=1`, sem chamar `buildiso`.

## Forja Store

A loja própria usa o Pamac CLI/libpamac como backend para os repositórios Manjaro e AUR, além de Flatpak/Flathub e catálogo AppStream. A interface GTK3 herda o tema ativo do sistema e usa apenas um realce branco discreto ao passar o mouse. O conjunto precisa passar pelas verificações automatizadas e por teste funcional em uma sessão Manjaro XFCE real antes de ser considerado pronto.

## Estado da entrega

O projeto está em fase de revisão e validação do código XFCE. Nenhuma ISO final deve ser anunciada como pronta até que a compilação, o checksum, a inicialização Live e a instalação pelo Calamares sejam efetivamente testados.

A ISO final deverá ser entregue como um único arquivo `.iso`, completo e sem divisão em partes.
