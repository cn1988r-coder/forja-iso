# Forja OS — fundações

Este repositório mantém duas fundações independentes para o desenvolvimento futuro da Forja OS:

- `bases/archlinux/`: fundação baseada no Arch Linux oficial.
- `bases/endeavouros/`: fundação baseada no EndeavourOS e em seus componentes próprios.

Estas pastas são pontos de partida técnicos, não distribuições prontas nem ISOs finalizadas. Não incluem ambiente gráfico, gerenciador de login, temas, dock, loja de aplicativos ou personalização visual da Forja OS.

O desenvolvimento de cada base deve permanecer independente. A interface e os componentes próprios da Forja OS serão construídos posteriormente, em camadas separadas.

## Estratégia de ambiente gráfico

A decisão atual para a edição gráfica é usar **MATE personalizado**, sobre a fundação EndeavourOS/Arch. O projeto **BigDesktop** do BigLinux fica registrado para acompanhamento e avaliação futura, sem incorporação de código neste momento.

Consulte [DESKTOP-STRATEGY.md](DESKTOP-STRATEGY.md) para a decisão, a direção visual e os critérios de validação.

Consulte o README de cada base antes de utilizá-la. Os arquivos atuais são uma fundação inicial e ainda precisam de validação e complementação antes de qualquer build de ISO.
