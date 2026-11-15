# Base CachyOS do Forja OS

Esta pasta marca a base oficial escolhida para a próxima geração do Forja OS.

## Origem e ferramentas

- Repositório de construção: https://github.com/CachyOS/CachyOS-Live-ISO
- Construtor: `buildiso.sh`, que prepara o perfil e executa `mkarchiso`.
- Distribuição/repositórios: CachyOS sobre Arch Linux.
- Instalador a adaptar: https://github.com/CachyOS/cachyos-calamares

O construtor oficial atualmente prepara o perfil `desktop` com Plasma Login. O Forja não deve usar esse perfil sem adaptação. A migração precisa substituir a lista de pacotes Plasma, remover o serviço de login Plasma e configurar LightDM para as sessões XFCE e MATE.

## Ambientes que entram na ISO

O manifesto `packages.x86_64` reúne os componentes básicos dos dois desktops e ferramentas de hardware/rede. A personalização visual existente permanece nos módulos `desktops/xfce` e `desktops/mate`, mas os scripts atuais ainda contêm etapas específicas de Ubuntu/Manjaro e precisam ser portados para Arch/CachyOS antes de serem chamados pelo construtor.

Requisitos de integração:
1. Construir a sessão XFCE Forja e a sessão MATE Forja na imagem Live.
2. Configurar LightDM com ambas as sessões disponíveis.
3. Fazer o Calamares instalar o sistema completo e preservar as duas sessões e as personalizações no disco.
4. Remover a inicialização e os pacotes exclusivos do Plasma do perfil Forja.
5. Validar dependências, construção da ISO, boot Live e instalação em máquina virtual.

## Situação

Esta é a definição inicial da base e dos pacotes. Ainda não é um perfil CachyOS completo e executável, nem uma ISO compilada. Não usar o perfil oficial Plasma como substituto do Forja.
