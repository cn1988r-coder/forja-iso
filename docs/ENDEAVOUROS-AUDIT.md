# Auditoria técnica da base e do instalador VENOM OS

## Decisão de produto

A VENOM OS é a distribuição final. Arch Linux é a base técnica e fonte dos pacotes oficiais. Calamares é somente o instalador. Nenhum modo de instalação pode instalar EndeavourOS ou entregar um Arch genérico como substituto da VENOM OS.

## Constatações da auditoria

O pipeline legado ainda utilizava o repositório EndeavourOS-ISO como framework de criação da mídia, o PKGBUILD do EndeavourOS para construir o Calamares e repositórios EndeavourOS no container de build. A identidade visual VENOM aplicada sobre esse pipeline não elimina essas dependências. Essa arquitetura precisa ser substituída por um perfil próprio baseado no Archiso oficial.

## Contrato de instalação VENOM

Os dois fluxos do Calamares têm a mesma origem de sistema:

- **Online:** exige conectividade, copia o filesystem completo da VENOM OS contido na ISO por meio de `unpackfs`, remove a conta temporária Live, cria o usuário final, configura o bootloader e atualiza o sistema instalado usando o módulo Pacman e os repositórios oficiais Arch.
- **Offline:** copia o mesmo filesystem completo da VENOM OS contido na ISO, sem depender de conexão ou atualização remota, e configura o usuário final e o bootloader.

O modo online não pode executar `pacstrap` para montar um Arch genérico. O modo offline não pode depender do módulo de pacotes online. Os pacotes próprios incluídos na imagem Live acompanham o filesystem copiado.

## Estado da substituição do framework

**Pendente:** substituir o framework EndeavourOS-ISO por um perfil próprio baseado no Archiso oficial; remover a receita EndeavourOS do Calamares; eliminar repositórios e chaves EndeavourOS do Dockerfile; revisar os serviços e a configuração da sessão Live para que sejam mantidos diretamente pelo perfil VENOM.

A documentação e o pipeline não devem declarar essa substituição concluída até que os arquivos de build e os workflows não dependam mais de fontes de distribuição EndeavourOS.

## Validação

As alterações no fluxo do Calamares são alterações de código e configuração. Elas ainda precisam passar pela validação estática, build da ISO, boot real e instalação completa em hardware ou máquina virtual. Nenhuma dessas etapas é declarada concluída neste registro.
