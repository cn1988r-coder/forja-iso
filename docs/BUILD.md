# Construção da VENOM OS

O perfil ativo está em `manjaro/venom-mate`. Use os perfis oficiais Manjaro ISO Profiles e `buildiso` de manjaro-tools compatível com mt-0.15.

A edição única é MATE tradicional, com painel superior e inferior. O painel superior usa Brisk Menu e o painel inferior apresenta as janelas agrupadas. O símbolo do Brisk é fornecido pelo tema de ícones VENOM, que herda os ícones Papirus-Dark do Manjaro.

Todos os pacotes, incluindo Calamares, Pamac, Brisk Menu e kernel, precisam ser obtidos dos repositórios oficiais Manjaro Stable. Não usar AUR, repositórios Arch, builds externos ou fontes upstream para substituir pacotes do Manjaro.

O kernel selecionado para a imagem é **linux618 (Linux 6.18 LTS)** por meio da opção `-k linux618` do buildiso. Não substituir por `linux`, `linux-meta` ou outro kernel padrão.

## Validação e compilação

- `scripts/prepare-manjaro-profile.sh`: sincroniza os overlays VENOM para a sessão live e o sistema instalado.
- `scripts/validate-manjaro-profile.sh`: valida estrutura, Brisk Menu, painéis e seleção de kernel LTS.
- `scripts/test-manjaro-profile-links.sh`: confere os symlinks e a lista Calamares contra o repositório oficial Manjaro.
- `scripts/validate-manjaro-build.sh`: em ambiente Manjaro, executa `buildiso -x` com `linux618` para resolver pacotes sem gerar ISO. Essa etapa deve confirmar também que `brisk-menu` existe no Stable oficial.
- `scripts/build-manjaro-iso.sh`: só permite a geração completa com `VENOM_ISO_APPROVED=YES`.

Ordem obrigatória: validação estrutural, resolução real de pacotes no Stable, inspeção da configuração Calamares gerada, testes gráficos e instalação em VM UEFI/BIOS. Só depois de tudo aprovado e com autorização expressa pode ser gerada a ISO.

A validação estática não substitui resolução de pacotes, boot ou instalação.
