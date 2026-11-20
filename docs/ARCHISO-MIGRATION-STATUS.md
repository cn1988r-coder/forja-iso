# Migração direta para Arch Linux

## Concluído no código-fonte

- Container de build baseado em `archlinux:latest`.
- Dockerfile instala ferramentas pelos repositórios oficiais Arch.
- Perfil VENOM próprio em `build/archiso/`.
- Perfil oficial `releng` do pacote Archiso é usado como base técnica de boot e infraestrutura.
- O script de build chama o `mkarchiso` instalado pelo pacote oficial `archiso`.
- Manifestos MATE e base Arch são combinados no perfil x86_64.
- Identidade do sistema Live definida como VENOM OS, com `ID_LIKE=arch`.
- Configuração de Pacman do perfil contém somente `core`, `extra` e `multilib` oficiais.
- Os workflows de build e validação foram deixados apenas sob acionamento manual para impedir execuções automáticas durante a migração.

## Pendente

- Integrar o Calamares upstream independente com configuração própria.
- Implementar a cópia da imagem VENOM no instalador online/offline.
- Integrar Bibata e os demais pacotes externos de forma reproduzível, sem receitas não fixadas.
- Concluir o perfil Live e verificar a sessão MATE/LightDM.
- Compilar a ISO e validar boot e instalação em hardware/VM.

## Limite de comprovação

Nenhum build, teste, workflow ou VM foi executado nesta etapa. O código-fonte está em migração e não representa uma ISO pronta para instalação.
