# Estratégia de ambiente gráfico da Forja OS

## Decisão atual

O ambiente gráfico adotado para a próxima edição da Forja OS será **MATE**, sobre a fundação EndeavourOS/Arch.

O MATE será usado como estrutura funcional, mas não deverá manter a aparência padrão da distribuição. A Forja OS terá identidade visual própria, construída em uma camada separada da fundação do sistema.

## Direção visual da edição MATE

- Tema escuro consistente em toda a sessão.
- Paleta principal em preto, grafite e cinza-chumbo, com azul discreto apenas como destaque.
- Ícones Papirus em variante cinza/neutra.
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
- A edição MATE será desenvolvida acima da fundação EndeavourOS/Arch, em camada própria.
- O registro do BigDesktop é documentação de acompanhamento, não parte de nenhuma das duas fundações.

## Critérios antes de considerar a edição pronta

1. Instalação reproduzível do MATE e dos componentes escolhidos.
2. Sessão, login, rede, áudio, Bluetooth, notificações e calendário funcionando.
3. Tema e ícones aplicados de forma consistente.
4. Ausência de serviços e efeitos desnecessários.
5. Testes de uso real, consumo de RAM/CPU e compatibilidade com hardware Intel HD 5500.
6. Build e validação de ISO antes de declarar a edição funcional.

Nenhum desses critérios deve ser considerado concluído apenas pela existência deste documento.
