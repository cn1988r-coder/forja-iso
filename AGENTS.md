# AGENTS.md

## Identidade do produto

- Nome: VENOM OS.
- Base técnica única: Arch Linux oficial e seus repositórios oficiais.
- Desktop único: MATE.
- Gerenciador de sessão: LightDM.
- Idioma único: Português do Brasil, `pt_BR.UTF-8`.
- Teclado padrão: Brasil ABNT2, `br-abnt2` no console e `br` + variante `abnt2` no X11.
- Não criar edições, sessões ou seletores de idioma/layout adicionais neste produto.

## Repositório e branch

- Repositório: `cn1988r-coder/forja-iso`.
- Branch de trabalho autorizada: `optimize/venom-iso-size`.
- Confirmar HEAD e workflows ativos antes de editar.
- Não alterar `main`, outras branches ou o repositório sem autorização.
- Fazer commits pequenos, claros e verificáveis.
- Não apagar branches, artefatos históricos ou arquivos fora do escopo.

## Instalador próprio

- Interface nativa em C + GTK4.
- Separar interface, descoberta de dispositivos, plano de instalação e backend privilegiado.
- O protótipo atual enumera discos em modo de leitura e contém um planejador declarativo em memória para layouts automáticos UEFI/BIOS e personalizados. O planejador valida caminhos, capacidade, alinhamento, funções e exigência de confirmação, mas não executa operações de disco. A interface ainda não apresenta a revisão do plano nem chama um backend. O botão de instalação deve permanecer desabilitado até que o fluxo completo seja implementado e testado.
- O instalador final deverá oferecer instalação automática e personalizada, particionamento revisável, confirmação explícita antes de qualquer escrita, criação de usuário, configuração de locale/teclado, MATE, LightDM, serviços, initramfs, GRUB, progresso, logs, erros compreensíveis e reinicialização.
- A instalação deverá funcionar offline usando um repositório local de pacotes oficiais e assinados, incluído na própria mídia. Não depender da rede durante a instalação e não copiar a raiz live como substituto da instalação por pacotes.
- Operações destrutivas nunca podem ser executadas sem revisão e confirmação explícita.
- Não usar instaladores externos, código Python para o instalador, wrappers frágeis ou permissões amplas de sudo.

## Painel MATE: requisitos obrigatórios

- Rede: pacote oficial `network-manager-applet`, processo `nm-applet` iniciado pelo autostart fornecido pelo pacote e Notification Area presente no layout do painel. Habilitar `NetworkManager.service`.
- Bluetooth: `bluez`, `bluez-utils` e `blueman`; o autostart oficial inicia `blueman-applet`, exibido pela Notification Area. Habilitar `bluetooth.service`.
- Volume/áudio: applet `GvcAppletFactory::GvcApplet` fornecido por `mate-media`, com `pipewire-audio`, `pipewire-pulse` e `wireplumber`. Não iniciar um segundo ícone de volume na bandeja.
- Manter as mesmas configurações do painel no sistema live e no overlay do sistema instalado.
- Validar estaticamente pacotes, arquivos de autostart, applets, serviços e ausência de duplicatas.
- Nunca declarar os três indicadores visualmente validados sem sessão gráfica real e teste após reinicialização. Se não houver VM/sessão gráfica, registrar a validação como pendente.

## Atualizações

- Pacman administra atualizações normais: `sudo pacman -Syu`.
- VENON é independente e manual: `venon-upgrade` apenas consulta/lista; `venon-update` instala somente após confirmação.
- Não criar timers, atualização automática ou integração do VENON com Pacman.

## Builds e validação

- Não gerar, publicar, solicitar nem disparar ISO sem autorização expressa posterior do usuário.
- A workflow de ISO permanece bloqueada. O script exige uma autorização explícita antes de qualquer compilação.
- Compilar e testar componentes C/GTK4, executar testes unitários, validações estáticas e ShellCheck é permitido.
- Não executar particionamento em discos reais. Testes futuros do backend devem usar mocks, imagens descartáveis e VMs isoladas.
- Nunca afirmar que o instalador, a ISO, o boot ou os indicadores gráficos funcionam sem executar e registrar o teste correspondente.

## Registro de continuidade

Atualizar `docs/PROJECT-CONTINUITY.md` com branch, HEAD-base, commits, arquivos alterados, testes realmente executados, falhas, bloqueios, próximos passos e confirmação explícita de que nenhuma ISO foi gerada.
