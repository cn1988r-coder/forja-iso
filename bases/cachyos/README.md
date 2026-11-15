# Base CachyOS do Forja OS

Esta pasta define somente a **base técnica CachyOS** do Forja OS. Ela não importa nem instala um ambiente gráfico do CachyOS.

## O que entra nesta base

- Infraestrutura CachyOS sobre Arch Linux: repositório, chaveiro, espelhos, hooks e configurações essenciais.
- Sistema-base, kernel, firmware e microcódigos de CPU.
- Inicialização UEFI/BIOS, initramfs e ferramentas de instalação/particionamento.
- Rede por NetworkManager.
- Ferramentas comuns de sistema e armazenamento.

O manifesto `packages.x86_64` contém apenas componentes compartilhados da base. Não contém XFCE, MATE, KDE Plasma, GNOME, gerenciador de janelas, painel, greeter ou aplicativos específicos de desktop.

## O que não deve ser herdado do ISO CachyOS

O perfil oficial `desktop` do CachyOS Live ISO inclui uma seleção própria de desktop e ferramentas de usuário. O Forja OS não deve copiar esse manifesto completo nem usar o perfil `desktop` sem uma adaptação que substitua sua seleção de pacotes e configurações.

Em particular, não importar:
- XFCE ou qualquer outro desktop do CachyOS;
- Plasma Login ou configurações de sessão do Plasma;
- temas, painéis, docks, papéis de parede ou personalizações visuais do CachyOS;
- aplicativos de usuário escolhidos pelo perfil desktop original.

## Integração planejada

1. Usar o construtor oficial CachyOS Live ISO/Archiso como referência para gerar a mídia Live.
2. Criar um perfil próprio do Forja OS, baseado neste manifesto e na infraestrutura necessária do Archiso.
3. Adicionar os desktops Forja em perfis separados, com pacotes, configurações e identidade visual próprios.
4. Configurar o instalador Calamares separadamente, para instalar o sistema completo no disco.
5. Validar dependências, geração da ISO, boot Live e instalação em máquina virtual antes de declarar a base funcional.

## Estado

Esta é uma definição de pacotes da base CachyOS, não um perfil Archiso completo e não uma ISO compilada. O pipeline ativo Manjaro MATE não é alterado por estes arquivos.

## Referências oficiais

- CachyOS Live ISO: https://github.com/CachyOS/CachyOS-Live-ISO
- CachyOS Calamares: https://github.com/CachyOS/cachyos-calamares
