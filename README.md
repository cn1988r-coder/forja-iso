# VENOM OS

Distribuição baseada no **Manjaro Linux**, com uma única edição: **MATE + LightDM**.

- Idioma: Português do Brasil (pt_BR.UTF-8).
- Teclado: Brasil ABNT2.
- Tema escuro VENOM: preto/grafite, azul elétrico e prata.
- Painel inferior próprio com lista de janelas agrupadas.

## Base e instalador

A construção usa os perfis oficiais Manjaro ISO Profiles e o utilitário `buildiso`. O perfil está em `manjaro/venom-mate`.

O instalador é o **Calamares fornecido pelos repositórios oficiais do Manjaro**. Não baixar, compilar ou substituir Calamares por versões upstream ou externas.

## Estado

A migração do perfil antigo Archiso para Manjaro está em andamento. O perfil e a validação estática não comprovam uma ISO funcional. Antes de gerar mídia, é necessário resolver os pacotes em ambiente Manjaro, inspecionar a configuração do Calamares e testar sessão live, instalação e primeiro boot em VM UEFI e BIOS.

**Nenhuma ISO deve ser gerada até essas verificações serem aprovadas e o usuário autorizar a compilação.**
