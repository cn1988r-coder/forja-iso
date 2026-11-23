# Preparação para os testes da VENOM OS XFCE

## Objetivo e limite desta preparação

Este documento consolida o estado documental da edição XFCE e organiza os pré-requisitos para a futura execução do protocolo de 16 etapas.

**Isto não é um relatório de testes.** Nenhum teste, validação técnica, compilação, construção de pacote ou geração de ISO foi executado. A máquina física de preparação também não foi instalada nem configurada. A execução permanece bloqueada até autorização expressa do usuário.

## Identificação do projeto

- Projeto: VENOM OS
- Base: Manjaro Linux
- Edição: XFCE
- Repositório autorizado: `cn1988r-coder/forja-iso`
- Branch: `main`
- Perfil base: `manjaro/base`
- Perfil da edição: `manjaro/xfce`

## Configuração atualmente registrada

### Base Manjaro

- Perfil base sem ambiente gráfico e sem gerenciador de login.
- GRUB definido para boot UEFI.
- NetworkManager habilitado.
- O manifesto `manjaro/xfce/Packages-Root` é idêntico ao manifesto `manjaro/base/Packages-Root`.
- O XFCE é acrescentado separadamente pela camada `manjaro/xfce`.

### Sessão XFCE

- Sessão XFCE com xfce4-session, xfce4-panel, xfwm4, xfdesktop e componentes centrais.
- LightDM com lightdm-gtk-greeter.
- Xorg.
- Thunar como gerenciador de arquivos.
- Rede via NetworkManager e applet de painel.
- Bluetooth via BlueZ e Blueman.
- Áudio via PipeWire, pipewire-pulse e WirePlumber.
- Utilitários de painel: notificações, Clipman, controle de volume, energia, captura de tela, gerenciador de tarefas e protetor de tela.

### Aparência

- Tema GTK e decoração de janelas: Materia Dark.
- Ícones: Papirus Dark.
- Pastas: cor azul aplicada pelo serviço `venom-papirus-blue.service` na primeira inicialização.
- Cursor: Bibata Modern Classic, tamanho 24.
- Fonte: Noto Sans 10.
- LightDM recebe Materia Dark, Papirus Dark e Bibata Modern Classic.
- Whisker Menu configurado com ícone próprio `venom-os`, um V azul, e título VENOM OS.

### Painel

- Um painel horizontal inferior.
- Largura de 100% e altura de 40 px.
- Uma única linha, sem ocultação automática e bloqueado.
- Ordem registrada: Whisker Menu, Docklike, separador expansível, notificações, área de notificação, volume, energia, Clipman, relógio e mostrar área de trabalho.
- Docklike com pré-visualizações, sem aplicativos fixados e com indicadores de atividade.
- Relógio em HH:MM, sem segundos, com data no tooltip.
- Ícones da área de notificação configurados para 22 px e simbólicos.

### Aplicativos

Declarados em `Packages-Desktop`:
- Firefox.
- Pamac GTK.
- Thunar, Mousepad, Xarchiver e utilitários XFCE.
- Ferramentas de rede, Bluetooth, áudio e administração do desktop.

Firefox e Pamac permanecem na seleção de pacotes conforme solicitado.

### Instalador

- `calamares` está declarado em `Packages-Live`.
- `mhwd_used="true"` está configurado no perfil XFCE.
- A intenção é usar exclusivamente o pacote Calamares dos repositórios oficiais do Manjaro.
- A inicialização automática do instalador gráfico ainda não está conectada/comprovada documentalmente.

### Ferdium

- `ferdium-bin` está listado separadamente em `Packages-AUR`.
- A integração do pacote AUR no fluxo de composição da edição ainda está pendente.
- Não usar Flatpak, conforme decisão do projeto.

## Preparação documental para o protocolo

O protocolo oficial continua sendo `TESTES/PROTOCOLO-16-ETAPAS.md`. As 16 etapas permanecem sequenciais e obrigatórias.

Antes de iniciar qualquer teste futuramente, será necessário:

1. Obter autorização expressa para a fase específica.
2. Definir e registrar a máquina de preparação e suas especificações.
3. Preparar o ambiente compatível com Manjaro Tools, usando documentação e pacotes oficiais do Manjaro.
4. Revisar a disponibilidade e compatibilidade dos pacotes nos repositórios Manjaro escolhidos.
5. Resolver a integração do Ferdium AUR, caso ele continue sendo requisito para a edição final.
6. Definir e documentar o fluxo de inicialização do Calamares no ambiente Live.
7. Definir critérios objetivos e evidências para cada caso de teste.
8. Registrar o commit exato e as versões dos repositórios que serão usados em qualquer futura execução.

A ordem acima é uma lista de preparação documental e de pré-requisitos. Não autoriza instalar ferramentas, executar comandos, iniciar chroots, construir pacotes ou ISO, testar ou validar.

## Quadro de estado

| Área | Estado documental |
|---|---|
| Base Manjaro separada do desktop | Configurada nos arquivos |
| Perfil XFCE | Registrado |
| Manifestos de pacotes XFCE | Registrados |
| Materia Dark, Papirus e Bibata | Configurados nos arquivos |
| Pastas azuis | Serviço de primeira inicialização registrado |
| V azul no Whisker Menu | Ícone e configuração registrados |
| Painel XFCE | Configuração registrada |
| Firefox e Pamac | Declarados em Packages-Desktop |
| Calamares oficial Manjaro | Declarado em Packages-Live |
| Inicialização automática do Calamares | Pendente de integração/comprovação |
| Ferdium AUR | Registrado, integração pendente |
| Máquina física de preparação | Não configurada |
| Protocolo de 16 etapas | Documentado |
| Testes e validações técnicas | Não executados e não autorizados |
| Compilação e construção de ISO | Não executadas e proibidas sem autorização |
| GitHub Actions/workflows | Não executados |

## Declaração de estado

A edição XFCE está organizada documentalmente no repositório, com perfil, manifestos, personalização e estrutura inicial do instalador registrados. Isso não comprova que os pacotes resolvem, que a sessão inicia, que o instalador abre ou que a ISO funciona.

Nenhuma ISO foi gerada. Nenhum teste ou validação foi executado. Nenhum workflow foi disparado. A VENOM OS ainda não está aprovada como versão estável.
