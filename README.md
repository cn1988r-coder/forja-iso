# Forja OS — fundações

Este repositório mantém duas fundações técnicas independentes para o desenvolvimento futuro da Forja OS:

- `bases/archlinux/`: fundação baseada no Arch Linux oficial.
- `bases/endeavouros/`: fundação baseada no EndeavourOS e em seus componentes próprios.

Estas pastas são pontos de partida técnicos, não distribuições prontas nem ISOs finalizadas. Permanecem sem ambiente gráfico e sem personalização visual.

## Ambiente gráfico

A edição gráfica escolhida é **MATE upstream personalizado**, com camada própria em [desktop/mate/](desktop/mate/). O BigDesktop do BigLinux fica registrado para acompanhamento e avaliação futura, sem incorporação de código neste momento.

Consulte [DESKTOP-STRATEGY.md](DESKTOP-STRATEGY.md) para a estratégia e [desktop/mate/README.md](desktop/mate/README.md) para os pacotes, padrões visuais e validação da camada MATE.

As fundações e a camada de desktop continuam separadas. Os arquivos atuais são definições iniciais e ainda precisam de validação e complementação antes de qualquer build de ISO.
