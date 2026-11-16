# Forja OS MATE

Camada de ambiente gráfico da edição MATE da Forja OS. Ela fica separada das fundações técnicas `bases/archlinux/` e `bases/endeavouros/`.

## Princípio

Usar o MATE upstream dos repositórios oficiais do Arch/EndeavourOS como base funcional e aplicar a identidade Forja OS por cima. Não importar uma edição MATE de outra distribuição, não substituir componentes centrais sem necessidade e não copiar configurações de desktop de terceiros.

## Escopo inicial

- Sessão MATE com Marco, mate-panel, Caja e ferramentas essenciais.
- Atril como visualizador padrão planejado para arquivos PDF.
- LibreOffice Still com pacote de idioma português do Brasil para documentos, planilhas e apresentações.
- LightDM como gerenciador de login.
- NetworkManager com applet de rede.
- Blueman para Bluetooth.
- PipeWire/WirePlumber para áudio.
- Applets MATE essenciais, incluindo relógio/calendário.
- Calculadora GNOME (`gnome-calculator`) como aplicativo independente, sem instalar o ambiente GNOME.
- Módulo experimental Forja Luz Noturna: interface GTK3 própria e backend XRandR direto, sem instalar GNOME Shell ou Mutter.
- Tema Materia-dark e ícones Papirus-Dark como ponto de partida visual.
- Configuração GTK para tema escuro, fonte legível e animações GTK desligadas.
- Configurações de baixo consumo: compositor do Marco desligado e efeitos de fundo desnecessários desativados.
- **Captura de tela:** usar somente `xfce4-screenshooter`, como ferramenta isolada. O pacote `mate-utils` foi deixado de fora porque inclui o `mate-screenshot` nativo. Não instalar o desktop XFCE, painel, sessão, gerenciador de arquivos ou demais aplicativos XFCE.

## Arquivos

- `packages.x86_64`: seleção explícita de pacotes, sem instalar indiscriminadamente o grupo `mate-extra`. Inclui `gnome-calculator` como aplicativo GNOME independente, sem trazer o desktop GNOME; inclui também apenas `xfce4-screenshooter` como exceção pontual para captura de tela e exclui `mate-utils`, que fornece o `mate-screenshot` nativo.
- `skel/.config/gtk-3.0/settings.ini`: aparência GTK padrão para novos usuários quando o construtor copiar o esqueleto para `/etc/skel`.
- `apply-defaults.sh`: aplica configurações MATE seguras ao usuário da sessão, verificando primeiro se cada schema/chave existe.
- `services.enabled`: serviços que o perfil de imagem deverá habilitar.
- `scripts/validate-packages.sh`: verifica nomes de pacotes com o pacman.
- `forja-luz-noturna/`: protótipo da interface e backend de temperatura de cor; a entrada de autostart está em `skel/.config/autostart/`.

## Forja Luz Noturna (experimental)

O GNOME Night Light não pode ser simplesmente transplantado para o MATE: seu caminho de aplicação de cores está integrado ao Mutter, enquanto a sessão Forja usa Marco. Para não instalar Mutter nem o desktop GNOME, foi criado um protótipo próprio GTK3 que controla a rampa de gama via XRandR. Ele oferece controle manual, temperatura ajustável, faixa horária local e ícone de bandeja. Os pacotes `python-gobject` e `xorg-xrandr` foram acrescentados como dependências.

**Estado:** código inicial registrado, ainda sem teste de execução. O backend depende do suporte do driver gráfico a alterações de gamma por XRandR. O protótipo não é o código original do GNOME e não deve ser anunciado como funcional até passar por teste real. A integração do instalador/construtor para copiar o executável para `/usr/bin/forja-luz-noturna` também precisa ser concluída; a entrada de autostart já está preparada em `skel`.

## Dependências e limpeza

As bibliotecas exigidas pelos pacotes escolhidos devem permanecer. Não remover dependências runtime para tentar reduzir a lista: o pacman resolve dependências transitivas durante a instalação. A limpeza deve retirar aplicações opcionais sem uso, não bibliotecas necessárias.

A suíte LibreOffice Still foi escolhida em vez do OnlyOffice para priorizar a integração nativa com Linux e a linha de manutenção estável. Ela acrescenta um volume considerável à instalação; não é um componente leve em termos de espaço em disco. O Atril já faz parte da seleção e atende à leitura de PDFs sem depender do LibreOffice.

A lista evita instalar o grupo completo `mate-extra`, mas mantém os componentes funcionais necessários para sessão, calendário, energia, rede, Bluetooth, áudio e dispositivos removíveis. A Calculadora GNOME é incluída somente como aplicativo independente; isso não instala a sessão nem o desktop GNOME. O utilitário XFCE de captura de tela é a única aplicação XFCE selecionada e não equivale a instalar o ambiente XFCE. `mate-utils` não é instalado para que o `mate-screenshot` não venha junto.

## Validação

Execute `bash desktop/mate/scripts/validate-packages.sh` em um ambiente Arch/EndeavourOS atualizado, com as bases de pacotes sincronizadas. Isso verifica a existência dos nomes nos repositórios configurados; não substitui instalação, resolução integral de dependências, testes de sessão ou build de ISO.

## Estado

Esta é uma camada inicial de definição. Ainda não foi instalada em uma máquina, o validador não foi executado em Arch/EndeavourOS e não houve build de ISO. Não declarar o desktop completo ou funcional até concluir os testes.
