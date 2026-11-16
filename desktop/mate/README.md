# Forja OS MATE

Camada de ambiente gráfico da edição MATE da Forja OS. Ela fica separada da fundação oficial ativa `bases/archlinux/`. A antiga fundação `bases/endeavouros/` está preservada apenas como referência inativa.

## Princípio

Usar o MATE upstream dos repositórios oficiais do Arch Linux como base funcional e aplicar a identidade Forja OS por cima. Não importar uma edição MATE de outra distribuição, não substituir componentes centrais sem necessidade e não copiar configurações de desktop de terceiros.

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

## IPTVnator integrado

O IPTVnator é um aplicativo padrão planejado para a sessão MATE. O instalador `install-iptvnator.sh` baixa o pacote pacman oficial x86_64 da release 0.25.0, confere o SHA-256 publicado e instala o pacote dentro do root filesystem informado usando `arch-chroot`. O pacote oficial fornece a entrada de aplicativo para o menu MATE. O script deve ser chamado pelo processo de construção da imagem depois que o root filesystem estiver preparado, por exemplo: `sudo desktop/mate/install-iptvnator.sh /caminho/para/airootfs`. A versão e o hash ficam fixados intencionalmente para builds reproduzíveis e devem ser atualizados juntos após verificar uma nova release oficial.

**Limite atual:** o instalador está no repositório, mas ainda não foi conectado a um fluxo de build de ISO, pois o projeto ainda não tem um pipeline de construção completo para essa base. Portanto, não declarar o IPTVnator instalado na ISO até essa integração e um build de teste serem concluídos. A dock própria também ainda não existe; a integração de ícone nela fica pendente da implementação da dock.

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

## Wallpaper padrão no perfil Arch Linux

O perfil Arch ativo deverá receber estes arquivos em `bases/archlinux/airootfs/` inclui o SVG em `/usr/share/backgrounds/forja/forja-mate-wallpaper.svg`, um perfil dconf de sistema e a configuração `org.mate.desktop.background`. O hook Pacman `etc/pacman.d/hooks/90-forja-dconf.hook` executa `dconf update` após a instalação do pacote dconf durante a preparação do root filesystem da ISO, para que o MATE use esse wallpaper como padrão sem exigir configuração manual do usuário. O arquivo de wallpaper também fica em `desktop/mate/wallpapers/` como fonte editável do projeto.

**Limite de validação:** os arquivos foram registrados no perfil, mas ainda não houve build da ISO nem teste visual de uma sessão MATE. A presença do padrão no sistema instalado após uma instalação completa também depende de como o instalador transfere os padrões do ambiente live para o sistema de destino; isso ainda precisa ser testado e integrado.

## Forja Luz Noturno (experimental)

O GNOME Night Light não pode ser simplesmente transplantado para o MATE: seu caminho de aplicação de cores está integrado ao Mutter, enquanto a sessão Forja usa Marco. Para não instalar Mutter nem o desktop GNOME, foi criado um protótipo próprio GTK3 que controla a rampa de gama via XRandR. Ele oferece controle manual, temperatura ajustável, faixa horária local e ícone de bandeja. Os pacotes `python-gobject` e `xorg-xrandr` foram acrescentados como dependências.

**Estado:** código inicial registrado, ainda sem teste de execução. O backend depende do suporte do driver gráfico a alterações de gamma por XRandR. O protótipo não é o código original do GNOME e não deve ser anunciado como funcional até passar por teste real. A integração do instalador/construtor para copiar o executável para `/usr/bin/forja-luz-noturno` também precisa ser concluída; a entrada de autostart já está preparada em `skel`.

## Dependências e limpeza

As bibliotecas exigidas pelos pacotes escolhidos devem permanecer. Não remover dependências runtime para tentar reduzir a lista: o pacman resolve dependências transitivas durante a instalação. A limpeza deve retirar aplicações opcionais sem uso, não bibliotecas necessárias.

A suíte LibreOffice Still foi escolhida em vez do OnlyOffice para priorizar a integração nativa com Linux e a linha de manutenção estável. Ela acrescenta um volume considerável à instalação; não é um componente leve em termos de espaço em disco. O Atril já faz parte da seleção e atende à leitura de PDFs sem depender do LibreOffice.

A lista evita instalar o grupo completo `mate-extra`, mas mantém os componentes funcionais necessários para sessão, calendário, energia, rede, Bluetooth, áudio e dispositivos removíveis. A Calculadora GNOME é incluída somente como aplicativo independente; isso não instala a sessão nem o desktop GNOME. O utilitário XFCE de captura de tela é a única aplicação XFCE selecionada e não equivale a instalar o ambiente XFCE. `mate-utils` não é instalado para que o `mate-screenshot` não venha junto.

## Validação

Execute `bash desktop/mate/scripts/validate-packages.sh` em um ambiente Arch Linux atualizado, com as bases de pacotes sincronizadas. Isso verifica a existência dos nomes nos repositórios configurados; não substitui instalação, resolução integral de dependências, testes de sessão ou build de ISO.

## Estado

Esta é uma camada inicial de definição. O wallpaper padrão está configurado no root filesystem do perfil EndeavourOS e seu banco dconf é compilado pelo hook de personalização. Ainda não houve build da ISO nem teste de uma sessão MATE real. Não declarar o desktop completo ou funcional até concluir os testes.


## Indicador de atualizações MATE

O módulo `forja-update-indicator/` fornece um indicador GTK3 para a área de notificação do painel MATE. Ele usa o utilitário `checkupdates` do pacote oficial `pacman-contrib`, faz a primeira consulta após o início da sessão e repete a verificação a cada 30 minutos. O ícone de estado normal é um escudo cinza simples; quando há atualizações, o mesmo escudo recebe um pequeno ponto laranja, inspirado no indicador do Linux Mint. Não há marca de verificação grande no centro.

O clique no ícone chama `forja-store --updates`. O menu também permite solicitar uma nova verificação. O instalador `install-forja-update-indicator.sh` copia o programa, os ícones e a entrada de autostart para um root filesystem Arch Linux já preparado. O pacote `pacman-contrib` foi incluído em `packages.x86_64`.

**Limites atuais e validação:** o indicador foi adicionado à branch `foundation/dual-base`, mas a Forja Store ainda não existe nessa branch. Por isso, a chamada `forja-store --updates` está definida como contrato de integração, não como integração concluída; enquanto a loja não estiver instalada, o indicador informa essa condição em vez de falhar silenciosamente. O instalador ainda precisa ser conectado ao processo de construção da imagem. A compatibilidade visual/funcional de `Gtk.StatusIcon` depende do applet de área de notificação do MATE e precisa ser testada numa sessão MATE real. A validação estática do Python e do shell no GitHub Actions não substitui esse teste, nem um build da ISO.


## Forja Store nativa (Arch Linux)

A aplicação própria da Forja OS fica em `forja-store/`. Ela não depende do Pamac nem do Shelly.

**Funções implementadas no código inicial:**
- Pesquisa de pacotes nos repositórios oficiais com `pacman -Ss`.
- Instalação e remoção de pacotes oficiais por um auxiliar restrito, solicitado via Polkit.
- Atualização completa do sistema com `pacman -Syu`; a loja não executa atualização parcial.
- Consulta de atualizações oficiais com `checkupdates`.
- Pesquisa no AUR pela API oficial e compilação no terminal como usuário comum, com revisão manual do PKGBUILD antes de confirmar.
- Detecção de atualizações para pacotes estrangeiros encontrados em `pacman -Qm`, comparando versões com `vercmp`; cada atualização AUR exige revisão e confirmação próprias.
- Consulta e atualização de Flatpaks já instalados, separando escopo de sistema e usuário.

**Limitações conhecidas desta primeira implementação:**
- A loja ainda não oferece instalação/remoção de Flatpaks nem gerenciamento de remotes Flathub.
- A compilação AUR exige que o usuário tenha `base-devel`, `git`, `less` e `sudo`; o PKGBUILD nunca é executado como root. O conteúdo do AUR não é auditado automaticamente nem considerado confiável.
- Pacotes instalados manualmente que não existem mais no AUR não podem ter atualização comparada pela API.
- A interface, Polkit, transações reais, AUR e Flatpak ainda precisam de testes em uma VM Arch Linux. A checagem estática do GitHub Actions não prova que as operações funcionam no desktop.
- O perfil Archiso em desenvolvimento chama `install-forja-store.sh` durante a preparação do root filesystem live. Não há, nesta branch, um pipeline completo que garanta a presença da loja no sistema instalado.

O pacote Arch pode ser preparado a partir de `forja-store/PKGBUILD` com `makepkg` em ambiente Arch Linux. Para a imagem, o processo de build deverá instalar o pacote ou executar o instalador contra o root filesystem de destino. Não instalar Pamac ou Shelly como dependência da Forja Store.


## Forja Monitor

O `forja-monitor/` contém um monitor próprio, leve e integrado ao MATE. A interface GTK3 é original da Forja OS: painel lateral, cartões compactos e gráficos Cairo discretos. A chama é preta e a identificação FORJA OS é cinza.

A implementação evita dependências pesadas: não usa o código do GNOME System Monitor, GNOME Shell, libadwaita, GTK4, Electron, WebKit ou psutil. Lê métricas simples diretamente de `/proc` e `/sys`, sem daemon residente. Só coleta dados enquanto a janela está aberta, a cada dois segundos, e mantém até 48 amostras por gráfico. A página de informações faz consultas pontuais quando aberta.

O script `bases/archlinux/build-profile.sh` chama `install-forja-monitor.sh` durante a preparação do root filesystem live. O pacote não acrescenta dependências à seleção MATE além de GTK3/PyGObject que já estão disponíveis na camada.

**Limites:** código inicial registrado, ainda precisa passar por validação no GitHub Actions e teste real em sessão MATE. O instalador agora é chamado pelo perfil Archiso em desenvolvimento. A data de instalação só aparece quando o instalador real gravar `/var/lib/forja-os/install-info.json`; até lá, o aplicativo informa que ela está indisponível.
