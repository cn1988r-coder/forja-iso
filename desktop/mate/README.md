# Forja OS MATE

Camada de ambiente gráfico da edição MATE da Forja OS. Ela fica separada das fundações técnicas `bases/archlinux/` e `bases/endeavouros/`.

## Princípio

Usar o MATE upstream dos repositórios oficiais do Arch/EndeavourOS como base funcional e aplicar a identidade Forja OS por cima. Não importar uma edição MATE de outra distribuição, não substituir componentes centrais sem necessidade e não copiar configurações de desktop de terceiros.

## Escopo inicial

- Sessão MATE com Marco, mate-panel, Caja e ferramentas essenciais.
- Atril configurado como aplicativo padrão para abrir arquivos PDF.
- LibreOffice Still com pacote de idioma português do Brasil, configurado como padrão para documentos, planilhas e apresentações nos formatos comuns.
- LightDM como gerenciador de login.
- NetworkManager com applet de rede.
- Blueman para Bluetooth.
- PipeWire/WirePlumber para áudio.
- Applets MATE essenciais, incluindo relógio/calendário.
- Calculadora GNOME (`gnome-calculator`) como aplicativo independente, sem instalar o ambiente GNOME.
- Módulo experimental Forja Luz Noturno: interface GTK3 própria e backend XRandR direto, sem instalar GNOME Shell ou Mutter.
- Fastfetch como ferramenta padrão de informações do sistema, com brasão ASCII próprio da Forja OS e paleta azul/cinza.
- Tema Materia-dark e ícones Papirus-Dark como ponto de partida visual.
- Configuração GTK para tema escuro, fonte legível e animações GTK desligadas.
- Configurações de baixo consumo: compositor do Marco desligado e efeitos de fundo desnecessários desativados.
- **Captura de tela:** usar somente `xfce4-screenshooter`, como ferramenta isolada. O pacote `mate-utils` foi deixado de fora porque inclui o `mate-screenshot` nativo. Não instalar o desktop XFCE, painel, sessão, gerenciador de arquivos ou demais aplicativos XFCE.
- **Wallpaper padrão:** fundo cinza uniforme com a chama original da Forja OS em preto sólido, sem texto ou cores adicionais.

## Arquivos

- `packages.x86_64`: seleção explícita de pacotes, sem instalar indiscriminadamente o grupo `mate-extra`. Inclui Fastfetch, `gnome-calculator` como aplicativo independente, somente `xfce4-screenshooter` como exceção pontual e `dconf` para os padrões de desktop do sistema.
- `wallpapers/forja-mate-wallpaper.svg`: wallpaper vetorial 3840×2160 com a silhueta da chama original em preto sólido sobre cinza.
- `apply-defaults.sh`: copia os arquivos de `skel/.config` para o perfil do usuário atual sem sobrescrever configurações pessoais existentes e aplica os padrões MATE seguros. O script ainda precisa ser integrado ao fluxo de preparação de sessão/instalação.
- `skel/.config/gtk-3.0/settings.ini`: aparência GTK padrão para novos usuários quando o construtor copiar o esqueleto para `/etc/skel`.
- `skel/.config/mimeapps.list`: associações padrão de arquivos, com PDFs no Atril e documentos/planilhas/apresentações no LibreOffice.
- `skel/.config/fastfetch/`: configuração padrão do Fastfetch e brasão ASCII da Forja OS.
- `services.enabled`: serviços que o perfil de imagem deverá habilitar.
- `scripts/validate-packages.sh`: verifica nomes de pacotes com o pacman.
- `forja-luz-noturna/`: protótipo da interface e backend de temperatura de cor; a entrada de autostart está em `skel/.config/autostart/`.

## Wallpaper padrão na imagem EndeavourOS

O perfil `bases/endeavouros/airootfs/` inclui o SVG em `/usr/share/backgrounds/forja/forja-mate-wallpaper.svg`, um perfil dconf de sistema e a configuração `org.mate.desktop.background`. O hook Pacman `etc/pacman.d/hooks/90-forja-dconf.hook` executa `dconf update` após a instalação do pacote dconf durante a preparação do root filesystem da ISO, para que o MATE use esse wallpaper como padrão sem exigir configuração manual do usuário. O arquivo de wallpaper também fica em `desktop/mate/wallpapers/` como fonte editável do projeto.

**Limite de validação:** os arquivos foram registrados no perfil, mas ainda não houve build da ISO nem teste visual de uma sessão MATE. A presença do padrão no sistema instalado após uma instalação completa também depende de como o instalador transfere os padrões do ambiente live para o sistema de destino; isso ainda precisa ser testado e integrado.

## Forja Luz Noturno (experimental)

O GNOME Night Light não pode ser simplesmente transplantado para o MATE: seu caminho de aplicação de cores está integrado ao Mutter, enquanto a sessão Forja usa Marco. Para não instalar Mutter nem o desktop GNOME, foi criado um protótipo próprio GTK3 que controla a rampa de gama via XRandR. Ele oferece controle manual, temperatura ajustável, faixa horária local e ícone de bandeja. Os pacotes `python-gobject` e `xorg-xrandr` foram acrescentados como dependências.

**Estado:** código inicial registrado, ainda sem teste de execução. O backend depende do suporte do driver gráfico a alterações de gamma por XRandR. O protótipo não é o código original do GNOME e não deve ser anunciado como funcional até passar por teste real. A integração do instalador/construtor para copiar o executável para `/usr/bin/forja-luz-noturno` também precisa ser concluída; a entrada de autostart já está preparada em `skel`.

## Dependências e limpeza

As bibliotecas exigidas pelos pacotes escolhidos devem permanecer. Não remover dependências runtime para tentar reduzir a lista: o pacman resolve dependências transitivas durante a instalação. A limpeza deve retirar aplicações opcionais sem uso, não bibliotecas necessárias.

A suíte LibreOffice Still foi escolhida em vez do OnlyOffice para priorizar a integração nativa com Linux e a linha de manutenção estável. Ela acrescenta um volume considerável à instalação; não é um componente leve em termos de espaço em disco. O Atril já faz parte da seleção e atende à leitura de PDFs sem depender do LibreOffice.

A lista evita instalar o grupo completo `mate-extra`, mas mantém os componentes funcionais necessários para sessão, calendário, energia, rede, Bluetooth, áudio e dispositivos removíveis. A Calculadora GNOME é incluída somente como aplicativo independente; isso não instala a sessão nem o desktop GNOME. O utilitário XFCE de captura de tela é a única aplicação XFCE selecionada e não equivale a instalar o ambiente XFCE. `mate-utils` não é instalado para que o `mate-screenshot` não venha junto.

## Validação

Execute `bash desktop/mate/scripts/validate-packages.sh` em um ambiente Arch/EndeavourOS atualizado, com as bases de pacotes sincronizadas. Isso verifica a existência dos nomes nos repositórios configurados; não substitui instalação, resolução integral de dependências, testes de sessão ou build de ISO.

## Estado

Esta é uma camada inicial de definição. O wallpaper padrão está configurado no root filesystem do perfil EndeavourOS e seu banco dconf é compilado pelo hook de personalização. Ainda não houve build da ISO nem teste de uma sessão MATE real. Não declarar o desktop completo ou funcional até concluir os testes.
