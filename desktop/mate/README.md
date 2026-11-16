# Forja OS MATE

Camada de ambiente gráfico da edição MATE da Forja OS. Ela fica separada das fundações técnicas `bases/archlinux/` e `bases/endeavouros/`.

## Princípio

Usar o MATE upstream dos repositórios oficiais do Arch/EndeavourOS como base funcional e aplicar a identidade Forja OS por cima. Não importar uma edição MATE de outra distribuição, não substituir componentes centrais sem necessidade e não copiar configurações de desktop de terceiros.

## Escopo inicial

- Sessão MATE com Marco, mate-panel, Caja e ferramentas essenciais.
- LightDM como gerenciador de login.
- NetworkManager com applet de rede.
- Blueman para Bluetooth.
- PipeWire/WirePlumber para áudio.
- Tema Materia-dark e ícones Papirus-Dark como ponto de partida visual.
- Configurações de baixo consumo: compositor do Marco desligado e efeitos de fundo desnecessários desativados.

## Pacotes

`packages.x86_64` contém uma seleção explícita, em vez de instalar indiscriminadamente o grupo `mate-extra`. O objetivo é evitar utilitários redundantes e dependências opcionais sem função na edição.

As bibliotecas exigidas pelos pacotes escolhidos devem permanecer: não remover dependências runtime para tentar reduzir a lista. O pacman resolve dependências transitivas durante a instalação. O que deve ser removido são aplicações opcionais sem uso, não bibliotecas necessárias.

## Validação

Execute `scripts/validate-packages.sh` em um ambiente Arch/EndeavourOS atualizado para consultar cada pacote no repositório configurado. Isso verifica a existência dos nomes de pacote, não substitui uma instalação, resolução completa de dependências ou build de ISO.

## Estado

Esta é uma camada inicial de definição. Ainda não foi instalada em uma máquina, não passou por build de ISO e não deve ser descrita como desktop completo ou funcional até os testes.
