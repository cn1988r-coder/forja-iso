# Estratégia de ambiente gráfico da Forja OS

## Decisão atual

A edição gráfica da Forja OS adotará **MATE upstream**, instalado a partir dos pacotes oficiais Arch/EndeavourOS, com personalização própria da Forja OS. Não será uma sessão MATE copiada de outra distribuição.

## Camada MATE

A definição inicial está em [desktop/mate/](desktop/mate/):

- `packages.x86_64`: seleção explícita de pacotes MATE e integrações necessárias, sem instalar indiscriminadamente `mate-extra`.
- `gtk-3.0-settings.ini`: tema escuro e ícones Papirus.
- `apply-defaults.sh`: aplica apenas chaves GSettings existentes, ignorando com aviso esquemas ou chaves opcionais ausentes.
- `scripts/validate-packages.sh`: consulta os nomes de pacote nos repositórios configurados usando pacman.

A lista preserva as bibliotecas runtime exigidas pelos componentes escolhidos. Não se deve remover uma biblioteca necessária apenas para reduzir o tamanho da lista: dependências transitivas são resolvidas pelo pacman. A limpeza deve remover aplicativos opcionais sem função, não dependências obrigatórias.

## Direção visual da edição MATE

- Tema escuro consistente, inicialmente Materia-dark.
- Paleta principal em preto, grafite e cinza-chumbo, com azul discreto apenas como destaque.
- Ícones Papirus-Dark como ponto de partida.
- Interface organizada, limpa e compacta, com blocos retangulares.
- Prioridade para desempenho e abertura rápida.
- Sem animações, transparências, blur, sombras pesadas, transições ou compositor desnecessário.
- Painéis, menus, notificações, calendário, rede, Bluetooth e controles devem seguir o mesmo padrão visual.
- Evitar componentes decorativos ou applets redundantes.

O objetivo é criar uma edição MATE reconhecível como Forja OS, não apenas aplicar um tema sobre o MATE padrão.

## BigDesktop: projeto preservado para avaliação futura

O **BigDesktop**, desenvolvido pela equipe do BigLinux, fica registrado como projeto de referência para acompanhamento e possível avaliação futura. Ele **não** é o ambiente gráfico adotado nesta etapa e não deve ser confundido com MATE.

Referências:
- BigDesktop: https://github.com/biglinux/bigdesktop
- BigGTKKit: https://github.com/biglinux/big-gtk-kit
- BigSearch: https://github.com/biglinux/bigsearch

A adoção futura do BigDesktop dependerá da disponibilidade do código-fonte necessário, maturidade, licença, compatibilidade com Arch/EndeavourOS e testes reais de estabilidade e consumo de recursos. Registrar o projeto aqui não significa copiar ou incorporar código dele.

## Separação de camadas

- `bases/archlinux/` e `bases/endeavouros/` continuam sendo fundações técnicas independentes, sem ambiente gráfico.
- `desktop/mate/` é a camada de desktop da edição MATE, separada das fundações.
- O registro do BigDesktop é documentação de acompanhamento, não parte de nenhuma das duas fundações.

## Pendências de validação

1. Executar o validador de pacotes em um ambiente Arch/EndeavourOS atualizado.
2. Resolver qualquer pacote ausente ou renomeado, sem remover dependências necessárias.
3. Fazer instalação limpa do conjunto e verificar resolução de dependências.
4. Validar sessão, LightDM, rede, áudio, Bluetooth, notificações, calendário e gerenciamento de energia.
5. Confirmar visualmente todos os componentes com o tema aplicado.
6. Medir RAM/CPU e testar compatibilidade com Intel HD 5500.
7. Fazer build e testes de ISO antes de declarar a edição pronta.

**Estado atual:** camada inicial documentada e arquivos adicionados ao repositório. O validador ainda não foi executado em Arch/EndeavourOS, nenhuma instalação ou build foi realizada e a edição não está validada como funcional.
