# Gerenciamento de pacotes e atualizações

A VENOM OS não possui repositório próprio de pacotes nem mecanismo próprio de atualização. O projeto VENOM é usado somente para construir a ISO.

## Sistema instalado

- **Pamac** é a interface gráfica para gerenciar programas e atualizações.
- **Repositórios oficiais do Arch Linux** fornecem os pacotes oficiais.
- **AUR** é acessado pelo suporte AUR do Pamac; os pacotes comunitários são construídos a partir de PKGBUILDs.

A configuração do Pacman no sistema instalado deve manter somente os repositórios oficiais do Arch Linux. Não adicionar repositório, URL, chave, serviço ou timer da VENOM.

## Pacotes offline na ISO

Para permitir a instalação sem internet, o processo de construção pode reunir pacotes oficiais e pacotes AUR já construídos em um conjunto local temporário dentro da mídia. O instalador usa esse conjunto apenas durante a instalação.

Esse conjunto temporário não é um repositório VENOM de atualização e não deve ser registrado no /etc/pacman.conf do sistema instalado. Ao finalizar a instalação, a configuração oficial do Arch Linux é aplicada e o Pamac fica com o AUR habilitado.

## Regra

Atualizações futuras: Pamac + repositórios oficiais Arch Linux + AUR. Nada de atualizador ou repositório próprio da VENOM OS.
