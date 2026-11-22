# Atualizações do sistema VENOM OS

## Regra definitiva

A VENOM OS é apenas o projeto de construção da imagem ISO. Ela não mantém, hospeda nem administra um repositório próprio de pacotes para o sistema instalado.

Depois da instalação, as atualizações são feitas exclusivamente por:

- **Pamac**, como interface gráfica de gerenciamento;
- **repositórios oficiais do Arch Linux**, para pacotes oficiais;
- **AUR**, pelo suporte AUR do Pamac, para pacotes comunitários que precisam ser construídos.

Não criar serviços, timers, comandos ou mecanismos próprios de atualização da VENOM OS. Não adicionar seção [venom] ou qualquer servidor de pacotes VENOM ao /etc/pacman.conf do sistema instalado.

## Instalação offline

Durante a construção da ISO, os pacotes necessários podem ser reunidos em um conjunto local temporário, incorporado à mídia para permitir a instalação sem internet. Esse conjunto serve somente ao instalador. Ele não é um repositório de atualização, não é configurado no sistema instalado e não permanece como fonte de pacotes após a instalação.

Ao concluir a instalação, o sistema recebe a configuração padrão dos repositórios oficiais do Arch Linux. O Pamac fica com o suporte ao AUR habilitado.

## Verificação obrigatória

- /etc/pacman.conf do sistema instalado contém somente repositórios oficiais Arch Linux.
- Nenhum endereço, chave, serviço ou timer de repositório VENOM é instalado.
- Pamac abre e consegue atualizar pacotes oficiais.
- Suporte AUR do Pamac permite pesquisar e construir pacotes AUR.
- O conjunto offline da ISO é usado apenas durante a instalação e não é registrado como fonte permanente.
