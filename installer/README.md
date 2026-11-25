# Instalador VENOM OS

## Instalador utilizado

A VENOM OS utiliza o **Calamares** como instalador gráfico. O payload é preparado por
`scripts/stage-installer-payload.sh`, que compila uma versão fixada do Calamares,
instala os módulos oficiais necessários e adiciona os módulos próprios da VENOM:

- `venominstall`: instalação do sistema e aplicação do overlay;
- `venom-btrfs`: integração da configuração BTRFS e recuperação.

A configuração principal fica em `installer/settings.conf`, os módulos em
`installer/modules/` e a identidade visual em `installer/branding/`.

## Limites de validação

A validação do payload antes do Archiso verifica a presença do executável, do
arquivo de configuração, do branding e dos módulos essenciais. Essa etapa não
substitui um teste gráfico do Calamares no ambiente Live completo.

Antes de declarar o instalador pronto, ainda é necessário testar em máquinas
virtuais descartáveis, tanto em BIOS quanto em UEFI:

1. abertura da interface gráfica;
2. carregamento de todos os módulos e da identidade VENOM;
3. particionamento e montagem BTRFS;
4. instalação do sistema e criação do usuário;
5. instalação e inicialização do GRUB;
6. primeiro boot do sistema instalado.

Nenhum teste deve usar discos com dados reais. A ISO só deve ser considerada
aprovada para instalação depois que esses testes forem concluídos.
