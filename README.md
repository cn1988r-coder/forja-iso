# VENOM OS

Distribuição baseada no **Manjaro Linux**, com uma única edição: **MATE + LightDM**.

- Idioma: Português do Brasil (pt_BR.UTF-8).
- Teclado: Brasil ABNT2.
- Kernel padrão: **Linux 6.18 LTS do Manjaro**.
- Tema VENOM: preto/grafite, azul elétrico e prata.
- MATE tradicional com painel superior e inferior.
- Brisk Menu no painel superior, com o símbolo V fornecido pelo tema de ícones VENOM.
- Painel inferior com lista de janelas agrupadas.

## Base e instalador

A construção usa os perfis oficiais Manjaro ISO Profiles e o utilitário `buildiso`. O perfil está em `manjaro/venom-mate`.

O instalador é o **Calamares fornecido pelos repositórios oficiais do Manjaro**. Pamac, MATE, Brisk Menu, kernel, drivers e demais pacotes também devem ser resolvidos exclusivamente nos repositórios oficiais Manjaro. Não usar AUR, pacotes externos ou versões upstream baixadas separadamente.

## Estado

A configuração do perfil e os testes de integração estrutural não substituem a resolução real dos pacotes, a inspeção do Calamares gerado nem os testes de boot e instalação. Nenhuma ISO deve ser gerada antes dessas etapas e da autorização expressa.
