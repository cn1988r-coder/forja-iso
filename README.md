# Forja OS

A Forja OS é uma distribuição em desenvolvimento, derivada diretamente do **Arch Linux**. A base ativa escolhida para a edição principal é `bases/archlinux/`; o sistema utilizará os repositórios e espelhos oficiais do Arch Linux.

## Responsabilidade dos repositórios

- **Arch Linux:** sistema-base, kernel, firmware, drivers, bibliotecas e pacotes oficiais.
- **EndeavourOS:** não faz parte da base ativa escolhida. A antiga fundação permanece preservada em `bases/endeavouros/` somente como referência técnica, sem orientar builds ou decisões da edição principal.
- **Forja OS:** repositório binário adicional e separado, planejado exclusivamente para aplicativos, ferramentas e componentes próprios. Não substituirá pacotes oficiais nem atualizará o sistema-base.

O Pacman continuará sendo o gerenciador de pacotes. As atualizações normais do sistema serão feitas pelos repositórios oficiais do Arch Linux. O repositório Forja será consultado separadamente para atualizar somente pacotes próprios da Forja.

## Ambiente gráfico

A edição gráfica escolhida é **MATE upstream personalizado**, instalado a partir dos repositórios oficiais do Arch Linux, com identidade e aplicações próprias da Forja OS. Consulte `DESKTOP-STRATEGY.md` e `desktop/mate/README.md`.

## Estado de desenvolvimento

A fundação Arch e a camada MATE ainda são estruturas iniciais. O perfil precisa ser completado, integrado a um fluxo real de construção Archiso, validado e compilado em ambiente Arch antes de qualquer ISO ser considerada instalável. Nenhum build bem-sucedido ou instalação funcional é declarado neste momento.