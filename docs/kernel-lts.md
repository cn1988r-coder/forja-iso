# Política de kernel da Forja OS

## Regra atual

A base ativa da Forja OS é o **Arch Linux direto**. O pacote `linux` presente em `bases/archlinux/packages.x86_64` é obtido dos repositórios oficiais do Arch. A escolha de kernel poderá ser revista em decisão explícita do projeto, mas o repositório Forja não distribuirá kernel nem headers.

## Atualizações

- Instalações existentes recebem atualizações de kernel pelos repositórios oficiais Arch com o Pacman.
- Novas ISOs resolvem a versão disponível nos repositórios oficiais durante o build.
- Não copiar kernel, headers ou firmware para o repositório binário Forja.

## Validação

Uma mudança de kernel só será considerada validada após build da ISO e testes de boot live, instalação, detecção de hardware, módulos e suspensão/retomada quando suportada.

Esta política substitui as referências antigas a edições XFCE/EndeavourOS que não fazem parte da base ativa atual.