# Calamares: identidade Forja e etapa de usuários

## Versão auditada

A receita fixada em `scripts/build-forja-iso.sh` compila o fork do EndeavourOS Calamares
`26.03.2.3`, com `WITH_QT6=ON`. A instalação offline seleciona explicitamente
a etapa `usersq`, tanto na tela quanto na execução da instalação.

## Problemas confirmados na configuração upstream

1. `data/eos/modules/usersq.conf` listava o grupo `wheel` duas vezes: uma entrada
   simples e outra entrada estruturada como grupo de sistema. O patch mantém a
   entrada estruturada, que permite criar o grupo quando ele não existir.
2. O QML da etapa `usersq` usava expressões regulares sem âncora inicial. O
   validador C++ do Calamares valida o nome inteiro. O patch alinha as expressões
   QML ao validador C++, incluindo a regra de hostname com mínimo de dois
   caracteres.
3. O QML Qt6 já tinha campos escuros, mas as cores foram ajustadas à paleta
   Forja e os textos auxiliares receberam contraste mais claro.
4. A receita upstream compilava com `CMAKE_BUILD_TYPE=Debug`. O build da Forja
   passa a usar `Release`.

## Identidade visual adicionada

- Branding próprio em `/etc/calamares/branding/forja`.
- Nome Forja OS, logotipo SVG próprio e paleta grafite, azul e laranja.
- Estilos explícitos para botões normais, hover, pressionados e desativados,
  campos, listas, caixas de seleção e navegação.
- A configuração offline passa a apontar para `branding: forja`.
- Os componentes e módulos do fork upstream permanecem sendo utilizados.

## Sobre o erro “User inválido”

A auditoria encontrou inconsistências reais na configuração de grupos e na
validação QML, mas isso, isoladamente, não prova a causa da mensagem observada
na máquina. O patch corrige essas inconsistências. Para confirmar a origem de
uma falha de carregamento da etapa, ainda é necessário executar o instalador
compilado e analisar o log do Calamares no momento do erro.

## Estado dos testes

O script de adaptação foi executado contra uma árvore sintética com os arquivos e
padrões esperados, e a lógica de inserção no `prepare()` do PKGBUILD foi verificada
isoladamente. Isso testa o patch, não substitui a compilação da receita upstream.

**Implementado no código-fonte da branch:** identidade visual Forja, ajuste de
configuração dos grupos, alinhamento das expressões de validação e build Release.

**Ainda pendente:** executar a validação automatizada na branch, compilar o pacote
Calamares e a ISO, abrir todas as telas em VM, criar um usuário real, validar
senha e hostname, concluir a instalação e reiniciar no sistema instalado.

A etapa de usuários e o instalador não devem ser considerados aprovados até esses
testes de ponta a ponta passarem.


## Fluxo simplificado aprovado para a Forja OS

A interface do Calamares deve apresentar somente três etapas ao usuário:
1. Dados da conta: nome completo, usuário, senha e confirmação, além do hostname no mesmo formulário.
2. Escolha do disco e particionamento.
3. Resumo e confirmação para iniciar a instalação.

Idioma e teclado são herdados da sessão Live e aplicados automaticamente durante a instalação, sem telas adicionais. Não apresentar seleção de desktop, pacotes, Netinstall ou modos específicos do EndeavourOS. O único ambiente instalado é MATE.

A execução continua usando os módulos internos necessários: particionamento, montagem, cópia de `/run/archiso/bootmnt/arch/x86_64/airootfs.sfs`, configuração de usuário, sistema, LightDM e GRUB. Tanto com internet quanto sem internet, a origem instalada é sempre a imagem Forja da ISO. A conexão não pode trocar a origem para EndeavourOS nem iniciar uma instalação de pacotes de outro sistema.

**Estado:** a ordem da interface foi ajustada no patcher para usuário → disco → resumo. Ainda é necessária compilação da ISO e validação em VM para comprovar que o fluxo completo funciona.
