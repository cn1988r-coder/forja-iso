# Estratégia de ambiente gráfico da Forja OS

## Decisão atual

A edição gráfica da Forja OS adotará **MATE upstream**, instalado a partir dos pacotes oficiais do Arch Linux, com personalização própria da Forja OS. Não será uma sessão MATE copiada de outra distribuição.

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

A adoção futura do BigDesktop dependerá da disponibilidade do código-fonte necessário, maturidade, licença, compatibilidade com Arch Linux e testes reais de estabilidade e consumo de recursos. Registrar o projeto aqui não significa copiar ou incorporar código dele.

## Separação de camadas

- `bases/archlinux/` é a única fundação ativa da Forja OS. `bases/endeavouros/` fica preservada como referência inativa, sem orientar o desenvolvimento.
- `desktop/mate/` é a camada de desktop da edição MATE, separada das fundações.
- O registro do BigDesktop é documentação de acompanhamento, não parte de nenhuma das duas fundações.

## Pendências de validação

1. A validação de nomes de pacotes e resolução de dependências foi executada com sucesso no GitHub Actions em container Arch Linux.
2. Concluir o primeiro build da ISO Archiso e revisar os logs de construção.
3. Inicializar a ISO em VM UEFI e BIOS, quando suportado, e testar LightDM/MATE.
4. Executar uma instalação limpa com o preset Archinstall e confirmar que as personalizações pós-instalação foram aplicadas.
5. Validar rede, áudio, Bluetooth, notificações, calendário, gerenciamento de energia e aplicativos Forja.
6. Confirmar visualmente os componentes e medir RAM/CPU em sessão MATE real.
7. Testar compatibilidade de hardware, incluindo Intel HD 5500, antes de declarar a edição pronta.

**Estado atual:** camada MATE integrada ao perfil Archiso e ao preset Archinstall no branch `feature/forja-arch-mate`. A validação de pacotes/scripts no GitHub Actions passou; o primeiro build da ISO está em execução. Ainda não houve teste visual em VM nem instalação real no disco, portanto a edição não está validada como funcional.
