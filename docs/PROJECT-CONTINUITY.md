# Continuidade técnica: VENOM OS XFCE

Atualizado em 22/11/2026. Decisão mais recente do usuário: instalador gráfico próprio, simples, em GTK4; a decisão anterior de usar Calamares está **SUBSTITUÍDA**.

## Arquitetura
- Branch de trabalho atual: `feature/venom-os-2.0-xfce`.
- Base: Arch Linux oficial e repositórios oficiais.
- Desktop: XFCE real + LightDM; sem MATE ou Window Maker.
- Idioma pt_BR.UTF-8; teclado br-abnt2.
- Mídia Archiso oficial.
- Instalador atual: aplicativo próprio GTK4 (`venom-installer`) com backend Bash (`/usr/lib/venom/venom-install`), usando pacstrap, manifesto de pacotes, overlay VENOM e GRUB. A decisão anterior de Calamares foi substituída pelo pedido explícito do usuário em 22/11/2026.
- Instalação exclusivamente online via pacstrap/Pacman. Sem unpackfs, rsync ou cópia da raiz live.
- Atualizações normais pelo Pacman; VENON separado e manual.

## Migração executada
- Reconstruída a estrutura operacional sobre Archiso e overlay XFCE. Os arquivos antigos de Calamares permanecem apenas como histórico no repositório e não são incluídos nem usados no fluxo atual.
- Manifest live XFCE separado do manifesto de pacotes do sistema instalado.
- Pacotes do sistema instalado incluem XFCE, Thunar, LightDM, Xorg, rede, Bluetooth, áudio, GRUB e dependências básicas, sem ferramentas de criação da ISO.
- LightDM configurado para a sessão `xfce`; sem autologin no sistema instalado.
- Overlay de instalação inclui configurações XFCE/GTK, tema XFWM4, wallpaper, ícones e configuração de LightDM.
- Backend próprio instala pacotes com pacstrap e aplica somente o overlay explícito, antes de criar o usuário. Não copia a raiz live.
- O backend configura locale pt_BR, teclado ABNT2, usuário, fstab, NetworkManager, Bluetooth, LightDM, initramfs e GRUB para BIOS/UEFI.
- Removidos workflows e diretórios operacionais Manjaro, perfis antigos, Pamac, MHWD e credenciais padrão.
- Workflow Archiso e validador específico `scripts/validate-xfce-profile.sh`.

## Histórico de migração
- Run #76, ID `44843598356`, falhou por pacote `adwaita-gtk-theme` não encontrado.
- Perfil antigo continha `mhwd`, autologin e senha padrão `venom`.
- Nenhuma ISO desse estado é considerada instalável.

## Validação estática atual
- Run `44857750371`, commit `66210f76e6d2e50981d414081123782fc519467d`: sucesso.
- Instalação das ferramentas, validação do perfil e disponibilidade dos pacotes oficiais, sintaxe dos scripts e conclusão do job passaram.
- A validação estática anterior `44857473296` também passou.
- Essa validação não compila a ISO nem testa boot ou instalação real.

## Validação de mídia: builds ISO XFCE

- Run #45, ID `44859735918`, falhou na verificação do atalho Calamares, embora Calamares 3.3.14, validação estática e geração da ISO tenham concluído. Correção da expressão de validação do `Exec` já incorporada ao workflow.
- Run #46, ID `44861586446`, commit `9514ba889b3ca1b5db30ef1b81e5fb51e383af57`: compilação Calamares, validação Arch, geração da ISO (2,1 GiB) e verificação do payload passaram. O teste BIOS executou 240 segundos, mas falhou porque não encontrou mensagens systemd esperadas no console serial. O teste UEFI e o upload da ISO foram ignorados. SHA-256 da ISO temporária: `9f351d480b86964b34e98d27d5c5e15bed1a0a30a276457635e24e6c0ac950eb`. O runner descartou a ISO ao encerrar o job; não há artefato de instalação disponível dessa execução.
- Diagnóstico: o teste anterior dependia de mensagens systemd no serial, enquanto o script live redirecionava sua saída para arquivo. Isso não permitia distinguir ausência de log de falha real na inicialização gráfica.
- Correção aplicada após #46: o script `build/airootfs/root/venom-live-setup` agora emite marcadores explícitos `VENOM_LIVE_SETUP_STARTED`, `VENOM_LIVE_READY` ou `VENOM_LIVE_LIGHTDM_FAILED` no console serial e no log. O marcador READY só é emitido quando LightDM está ativo.
- Workflow atualizado: testes BIOS e UEFI independentes, ambos executados mesmo se o outro falhar; cada um exige timeout esperado e marcador `VENOM_LIVE_READY`. Registros seriais são apresentados no log e publicados em artefato diagnóstico mesmo quando os testes falham. A ISO de instalação só é publicada se BIOS e UEFI passarem.
- Essa verificação confirma que o script live alcançou LightDM ativo; não substitui o teste visual manual da sessão XFCE nem a validação de instalação real no hardware.
- Próximo passo: executar a build XFCE autorizada, acompanhar ambos os testes e disponibilizar a ISO somente se o gate final passar. Se falhar, usar os registros BIOS/UEFI para identificar a etapa real do problema.
- Após o usuário baixar, instalar e testar a XFCE, revisar o resultado com ele. Só depois iniciar o desenvolvimento visual aprofundado do Window Maker, preservando a identidade VENOM e a personalidade OpenStep. A edição MATE permanece na sequência planejada.

## Identidade visual e interfaces VENOM OS
Palavra-chave de recuperação solicitada pelo usuário: **INTERFACES**. Quando o usuário disser “chat, interfaces” ou pedir “as interfaces”, recuperar e apresentar este acordo.

Princípio: **uma identidade visual VENOM compartilhada, com três experiências de desktop distintas**. Não padronizar os três ambientes a ponto de parecerem cópias uns dos outros.

- **VENOM XFCE:** experiência moderna e objetiva; painel inferior robusto, menu próprio VENOM e identidade azul metálica.
- **VENOM MATE:** experiência elegante, familiar e organizada; preservar a personalidade e os recursos próprios do MATE, mantendo a identidade VENOM.
- **VENOM Window Maker:** experiência própria do Window Maker, inspirada na filosofia OpenStep; valorizar o Dock, o menu raiz e os elementos característicos do ambiente, sem imitar XFCE ou LXQt.

Elementos comuns às três edições:
- Identidade VENOM OS, com preto e azul metálico como cores principais e a marca/serpente VENOM nos elementos próprios do sistema.
- Aplicativos mantêm seus ícones e marcas originais. Não aplicar máscara ou recoloração que descaracterize Firefox e outros aplicativos.
- Usar base, ferramentas e pacotes do Arch Linux oficial. Não incluir identidade, ferramentas ou dependências operacionais do Manjaro.
- Manter consistência de marca sem apagar a identidade funcional e visual de cada ambiente.

Esta seção registra a direção visual aprovada pelo usuário. As referências são especificações conceituais, não evidência de que todos os elementos já estejam implementados ou testados nas ISOs.


## Correção da falha de boot da compilação #47

- Run #47, ID `44863728291`, commit `c53b5d9f37ac52b1d89353ac8916b11ac48f886f`, terminou com falha nos testes BIOS e UEFI.
- Os logs seriais mostram que o boot parou no serviço `systemd-firstboot.service`, que abriu o assistente interativo "Please enter the new timezone name or number". Por isso o script `/root/venom-live-setup` não chegou a emitir `VENOM_LIVE_READY`.
- Correção aplicada em `build/profiledef.sh`: adicionar `systemd.firstboot=headless` aos parâmetros de kernel comuns a BIOS e UEFI. Esse modo suprime perguntas interativas do systemd-firstboot, preservando a configuração automática que não exige entrada.
- O validador `scripts/validate-xfce-profile.sh` agora exige explicitamente esse parâmetro, para evitar regressão.
- Critério da próxima compilação: validação estática aprovada; aplicativo GTK4 e backend VENOM presentes na ISO; BIOS e UEFI devem alcançar `VENOM_LIVE_READY` e LightDM ativo; gate final deve aprovar ambos antes de publicar o artefato ISO.
- A correção não desativa nem remove os testes. Se algum modo falhar novamente, preservar os logs seriais e investigar a nova causa antes de outra tentativa.

## Preparação para retomada em 22/11/2026
- Prioridade: concluir a edição VENOM XFCE e entregar uma ISO verificável para o usuário testar.
- Correção do validador Calamares já está registrada no workflow, commit b943267bba0fb05a6152346ceca538c94f4b979a.
- O arquivo de trigger foi atualizado no commit 9514ba889b3ca1b5db30ef1b81e5fb51e383af57, mas a consulta posterior não mostrou uma nova execução do Actions. Portanto, a compilação #46 ainda não começou.
- Antes de iniciar: conferir se não há workflow ativo na branch e se o HEAD contém as correções esperadas.
- Iniciar manualmente o workflow VENOM OS XFCE Arch ISO em feature/venom-community-xfce usando Run workflow (workflow_dispatch). Não alterar arquivos enquanto a compilação estiver ativa, devido ao cancelamento automático por concorrência.
- Acompanhar a execução até o fim. Se passar: verificar testes BIOS/UEFI e artefato ISO, tamanho e SHA-256; só então fornecer o link do artefato para download.
- Se falhar: ler o log da etapa com erro, corrigir e registrar o resultado real. Não declarar ISO pronta sem artefato validado.
- Após o usuário baixar, instalar e testar a XFCE, revisar o resultado com ele. Só depois iniciar o desenvolvimento visual aprofundado do Window Maker, preservando a identidade VENOM e a personalidade OpenStep. A edição MATE permanece na sequência planejada.
- Limitação operacional: não existe compilação em segundo plano nesta conversa. A preparação fica registrada no repositório; a execução precisa ser iniciada e acompanhada quando a conversa for retomada.



## Diagnóstico e correção da compilação #48

- Run #48, ID `44866814136`, commit `440869f80592ac6bea9f83d9dd325275f91b063c`, compilou a ISO e passou pela verificação do payload Calamares, mas falhou no gate de prontidão Live.
- Os dois smoke tests executaram até o limite de 240 segundos. O encerramento de QEMU por SIGTERM foi provocado pelo `timeout`; o erro decisivo foi a ausência de `VENOM_LIVE_READY`, não o sinal 15 isoladamente.
- O log UEFI confirma que o kernel e o systemd chegaram aos alvos Multi-User e Graphical Interface, mas não contém `VENOM_LIVE_SETUP_STARTED`, `VENOM_LIVE_READY` nem inicialização do LightDM. O registro BIOS ficou vazio. O artefato de diagnóstico foi preservado como `venom-xfce-boot-diagnostics`; nenhuma ISO foi publicada.
- Causa identificada no perfil: o parâmetro `script=/root/venom-live-setup` depende de `/root/.automated_script.sh`, mas o arquivo de despacho não era chamado pelo login Bash do root. O perfil tinha autologin Bash no tty1, porém não tinha `/root/.bash_profile`. O hook upstream do Archiso é normalmente acionado por `.zlogin`, que não atende ao shell Bash usado neste perfil.
- Correção aplicada na branch XFCE: adicionar `build/airootfs/root/.bash_profile` para disparar o hook Archiso no tty1 e emitir `VENOM_AUTOMATED_SCRIPT_DISPATCHED` no serial; ampliar o validador para exigir o arquivo, verificar sua sintaxe e confirmar que ele chama `/root/.automated_script.sh`.
- O parâmetro `systemd.firstboot=headless` permanece obrigatório e não foi removido.
- Próxima validação: reconstruir e executar novamente BIOS e UEFI. Exigir os marcadores de despacho, início do setup e `VENOM_LIVE_READY`, além de LightDM ativo. A ISO só pode ser publicada se ambos os modos passarem. O log BIOS vazio ainda precisa ser reavaliado na nova execução.

## Diagnóstico da compilação #61
- Run #61, ID 44929473954: pré-check, compilação do Calamares (fluxo antigo, posteriormente substituído), staging do branding, validação Archiso, geração da ISO e verificação do payload passaram. Os testes de boot chegaram ao sistema e iniciaram LightDM, mas ambos reprovaram na prontidão XFCE.
- Log PAM do LightDM: requisito user ingroup autologin não atendido para venom; o script criava venom nos grupos wheel/audio/video/storage, sem autologin. A sessão gráfica não iniciou e não houve processos xfce4-session, xfce4-panel ou xfdesktop.
- Correção: criar o grupo autologin se ausente e adicionar venom a ele mesmo se a conta já existir. O validador passa a exigir essas operações. Nova compilação e testes BIOS/UEFI necessários; nenhuma ISO publicada.


## Instalador gráfico próprio (decisão de 22/11/2026)

- **DECISÃO ATUAL:** substituir o Calamares por um instalador gráfico próprio e simples, a pedido explícito do usuário. Não voltar a integrar nem depender do Calamares.
- Interface GTK4: seleção do disco, nome completo, usuário, senha e confirmação de apagamento.
- Backend Bash: valida disco inteiro, recusa mídia Live, exige internet e disco de pelo menos 20 GB, cria partições automaticamente, instala o manifesto com pacstrap, aplica overlay, cria usuário, configura pt_BR/ABNT2, serviços e GRUB para BIOS/UEFI.
- A instalação apaga completamente o disco escolhido depois da confirmação. A interface não oferece particionamento manual.
- **Estado técnico:** código inicial implementado e commitado; ainda não compilado, nem testado em VM ou hardware. Não entregar a ISO como instalável até validar o aplicativo, backend e instalação completa em discos virtuais descartáveis, nos dois modos de boot.
- O workflow foi alterado para compilar e incluir o instalador GTK4. Nenhuma nova compilação foi iniciada nesta etapa.
