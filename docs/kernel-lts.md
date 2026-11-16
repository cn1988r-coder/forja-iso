# Política de kernel LTS da Forja OS

## Regra do projeto

As edições da Forja OS devem usar o pacote **`linux-lts`** dos repositórios oficiais Arch Linux/EndeavourOS como kernel padrão. Não fixar uma versão numérica do kernel no perfil: o pacote `linux-lts` acompanha a linha LTS mantida e empacotada pelo Arch.

## Perfil XFCE

O perfil `profiles/forja-xfce/packages.x86_64` inclui:
- `linux-lts`: kernel LTS.
- `linux-lts-headers`: headers correspondentes, necessários para módulos externos e ferramentas que os utilizem.
- `linux-firmware`: firmware de dispositivos.

Os pacotes `linux` e `linux-headers` não devem ser incluídos junto deles como kernel padrão da edição.

## Como as atualizações acontecem

- **Instalações já realizadas:** recebem as novas versões empacotadas do kernel LTS por `sudo pacman -Syu`, a partir dos repositórios oficiais configurados.
- **Novas ISOs:** cada compilação resolve a versão atual disponível de `linux-lts` e `linux-lts-headers` nos repositórios oficiais no momento do build.
- Não manter cópia do código-fonte do kernel no repositório Forja Updates e não criar repositório pacman próprio para o kernel.
- O repositório Forja Updates fica reservado a componentes exclusivos da Forja OS; atualizações do kernel pertencem ao fluxo oficial do Arch/EndeavourOS.

## Validação obrigatória

Uma mudança de kernel só é considerada validada depois de compilar a ISO e testar inicialização Live, detecção de hardware, módulos essenciais e suspensão/retomada quando suportada. A troca de pacote no perfil, por si só, não comprova esses testes.

## Escopo

Esta política é a regra geral do projeto. A alteração de pacote aplicada nesta etapa cobre o perfil XFCE EndeavourOS existente. Outras edições devem adotar a mesma política quando seus perfis forem implementados ou atualizados.
