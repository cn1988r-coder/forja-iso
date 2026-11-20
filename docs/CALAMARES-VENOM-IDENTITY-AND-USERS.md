# Calamares na VENOM OS

## Diretriz

O instalador da VENOM deve usar o projeto Calamares independente, sem fork, módulos, branding ou caminhos específicos de outra distribuição.

A origem da instalação será sempre a imagem completa da própria VENOM OS incluída na ISO. O modo offline copia essa imagem sem depender da rede. O modo online copia a mesma imagem e, depois, atualiza o sistema instalado usando exclusivamente os repositórios oficiais Arch Linux.

## Estado atual

A construção da ISO foi migrada para o Archiso oficial, mas a integração independente do Calamares ainda não foi concluída.

Ainda faltam:
- fixar e integrar uma versão upstream atual do Calamares;
- preparar o branding VENOM no formato suportado pelo upstream;
- criar configurações próprias de módulos e sequências;
- implementar e revisar os fluxos online e offline com origem na imagem VENOM;
- remover o instalador Live temporário do sistema instalado;
- validar particionamento, usuário, GRUB, LightDM e primeiro boot.

Nenhum instalador deve ser apresentado como funcional até essas etapas serem concluídas e testadas numa ISO real.
