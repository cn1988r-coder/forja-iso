# Auditoria de continuidade em 2026-11-20 08:40 BRT

## Estado verificado nesta execução

- Repositório: cn1988r-coder/forja-iso.
- Branch de trabalho autorizada: optimize/venom-iso-size.
- HEAD lido no início desta execução: 0f4c8258846bfdd65c611ebd1914186ce52052eb.
- AGENTS.md foi lido integralmente. Suas regras de base Arch oficial, MATE + LightDM, instalador gráfico próprio, rejeição do Calamares e proibição de build ISO foram mantidas.
- A tentativa anterior de registrar o estado em docs/PROJECT-CONTINUITY.md foi gravada: este documento já continha o bloco datado de 08:33 BRT e os resultados das builds #40, #50 e validação #1163.
- Atenção: o restante deste arquivo ainda contém registros históricos que indicam fix/forja-calamares-stability como branch ativa e instruções antigas para testar Calamares. Essas instruções estão superadas por AGENTS.md e pelo bloco de estado mais recente; não devem orientar novas alterações.

## Auditoria do pipeline atual

Arquivos lidos diretamente na branch:

- Dockerfile: parte de archlinux:latest, mas substitui a configuração de Pacman por uma versão do EndeavourOS, baixa a mirrorlist e importa chaves EndeavourOS, instala endeavouros-keyring e endeavouros-mirrorlist. Portanto, a base ainda não é Arch puro.
- scripts/build-venom-iso.sh: clona endeavouros-team/EndeavourOS-ISO no commit fixado 90376d8f52ab19e19073eed33d6f36c46ec7c409, usa PKGBUILDs EndeavourOS, paths EndeavourOS-ISO, skeleton endeavouros-skel-liveuser, executa transformações Python e mantém instalação/configuração Calamares.
- scripts/build-container.sh: ainda descreve/constrói ambiente Arch + repositórios EndeavourOS e executa o script legado.
- .github/workflows/build-iso.yml: usa o Dockerfile legado, espera saída em work/EndeavourOS-ISO/out e mantém gatilhos de push em branches antigas. Nenhum workflow de ISO foi disparado nesta execução.
- scripts/validate-build.sh: exige patch-calamares.py, branding/configuração/polkit/wrapper Calamares e referências específicas EndeavourOS. Está incompatível com as decisões atuais.
- scripts/validate-scope.sh: exige que README documente dependência upstream EndeavourOS e preservação do Calamares; ao final chama o validador legado. Também está incompatível com as decisões atuais.
- build/: ainda contém calamares/, listas packages.arch e packages.mate, e airootfs/; não existe ainda um perfil Archiso próprio em build/archiso.
- Dockerfile e scripts não foram alterados nesta execução.

## Referência oficial Archiso consultada

A estrutura oficial atualmente publicada em archlinux/archiso/configs/releng contém airootfs/, efiboot/, grub/, syslinux/, packages.x86_64, pacman.conf e profiledef.sh. O profiledef.sh oficial define imagem SquashFS XZ e modos de boot BIOS/UEFI. Esta é a referência estrutural correta para construir o perfil VENOM, sem importar scripts ou identidade de outra distribuição:
https://github.com/archlinux/archiso/tree/master/configs/releng

## Resultado desta execução

- Feito: conferidos HEAD, instruções do agente, documento de continuidade, pipeline, validadores, container e estrutura atual de build; identificadas as dependências EndeavourOS/Calamares que ainda bloqueiam a migração.
- Pendente: criar o perfil independente em build/archiso; migrar container, scripts e workflows; substituir validadores legados; desenvolver o instalador gráfico próprio.
- Bloqueios: não há evidência nesta execução de um ambiente remoto de compilação/VM acessível para testar boot ou instalação. A migração pode avançar com revisão estática e testes de componentes.
- Não testado: nenhuma compilação de componentes, build ISO, boot Live ou instalação foi executada nesta execução.
- Segurança: nenhuma ISO foi iniciada ou gerada; nenhuma branch além de optimize/venom-iso-size foi alterada.

Próxima tarefa: desenhar e adicionar o perfil VENOM em build/archiso usando somente a estrutura oficial Archiso, após inventário dos arquivos e hooks realmente necessários. Não iniciar build ISO.

---
# Estado confirmado em 2026-11-20 08:33 BRT

## Retomada do projeto VENOM OS

- Repositório: `cn1988r-coder/forja-iso`.
- Branch autorizada para desenvolvimento: `optimize/venom-iso-size`.
- HEAD confirmado: `2fa22b5fe75af9ff111de11226dd71ca4b99845f`.
- Instruções de agentes: `AGENTS.md`, commit `2fa22b5fe75af9ff111de11226dd71ca4b99845f`.
- Não havia workflow ativo na consulta ao GitHub Actions feita às 08:33 BRT.
- **Build #40**: run `44673298576`, commit `176355ffb49dcc59f5030842479222db93223049`, terminou com falha. A etapa de preparação do ambiente passou; a etapa `mkarchiso` falhou porque o script reportou que `/usr/bin/calamares` estava ausente. Nenhuma ISO, hash ou artefato foi produzido nessa execução.
- **Build #50**: run `44696672641`, commit `88143611d80214fd5b945c9346b352ce8e14f47d`, terminou com sucesso e produziu `VENOM-OS-MATE-2026.11.20.iso`. SHA-256 da ISO: `941793b70fa33a786ab233e8393254a8cc6ed6969be42fef4a24b60d40959964`. Artefato ZIP ID `14612642525`, tamanho `4.975.020.638` bytes. **Preservar esse artefato e hash como registro histórico; não tratar a ISO como aprovada**, pois o usuário constatou que o Calamares fecha sozinho e a arquitetura ainda depende do EndeavourOS.
- **Validação #1163**: run `44727964982`, no HEAD atual, terminou com falha deliberada em `scripts/validate-scope.sh`: o instalador gráfico próprio ainda não foi implementado e validado. A validação de sintaxe/build foi ignorada após essa falha.
- A execução #1163 também confirma que o validador de escopo ainda procura blocos Python embutidos e código/identidade Calamares. Isso está em conflito com as decisões atuais: Calamares foi rejeitado e Python não foi aprovado como tecnologia do instalador.
- A inspeção direta do HEAD atual confirma que a migração para Arch Linux puro **ainda não foi feita**: `scripts/build-venom-iso.sh`, `Dockerfile`, `scripts/build-container.sh` e `.github/workflows/build-iso.yml` ainda clonam/consomem EndeavourOS, seus repositórios e paths. O perfil Archiso próprio ainda não foi criado.
- A documentação mais antiga abaixo contém instruções históricas superadas. Este bloco e `AGENTS.md` prevalecem: instalador próprio 100% gráfico, Calamares rejeitado, base Arch oficial, MATE + LightDM, sem geração de ISO sem autorização explícita.
- Nenhuma ISO foi iniciada ou gerada nesta retomada.

## Próxima sequência técnica

1. Inventariar o conteúdo do perfil EOS usado atualmente e mapear somente o necessário para um perfil Archiso oficial independente.
2. Criar o perfil VENOM em `build/archiso` a partir da estrutura oficial `archiso/configs/releng`, sem clonar ou executar scripts de outras distribuições.
3. Reescrever o container e os scripts/workflows para usar exclusivamente Arch Linux e `mkarchiso` sobre o perfil VENOM.
4. Remover referências de build e pacotes Calamares, wrappers, patches, regras polkit e validadores legados; preservar apenas créditos/licenças exigidos.
5. Implementar e testar o instalador gráfico nativo aprovado em componentes isolados antes de qualquer build ISO.
6. Atualizar os validadores para refletir as decisões reais, sem exigir Python ou Calamares.
7. Atualizar este registro após cada etapa, sem disparar build ISO.

---

# VENOM OS - Registro permanente de continuidade

## Correção dos indicadores do painel MATE em 2026-11-20

- A ISO #50 foi testada pelo usuário e mostrou o relógio/calendário, mas não os indicadores de rede, Bluetooth e volume na área de notificação do painel superior.
- A causa da ausência de rede e volume na ISO #50 é confirmada: o manifesto daquela compilação não incluía `network-manager-applet` nem `mate-media`. Bluetooth ainda exige BlueZ e o applet Blueman.
- Na branch `optimize/venom-iso-size`, o manifesto já inclui `network-manager-applet`, `mate-media`, `blueman`, `bluez`, `bluez-utils` e PipeWire/WirePlumber. Isso, isoladamente, não prova que os ícones apareçam.
- Correção adicional preparada no hook pós-instalação dos pacotes: substituir os três arquivos XDG de autostart por entradas explícitas para MATE (`nm-applet`, `blueman-applet` e `mate-volume-control-status-icon`), verificar os arquivos e executáveis e manter a área de notificação no layout padrão do painel.
- O hook também remove o banco dconf de usuário herdado de `liveuser`, se existir, para impedir que configurações anteriores da sessão Live se sobreponham ao banco de sistema VENOM que define `default-layout='default'`.
- Os nomes dos arquivos XDG foram conferidos nas listas oficiais dos pacotes Arch Linux: `network-manager-applet`, `mate-media` e `blueman`. Referências: <https://archlinux.org/packages/extra/x86_64/network-manager-applet/files/>, <https://archlinux.org/packages/extra/x86_64/mate-media/files/> e <https://archlinux.org/packages/extra/x86_64/blueman/files/>.
- Referência adicional: o manual do MATE descreve a Notification Area como applet do painel, e o issue #1493 do mate-panel registra casos em que a área de notificação não fica visível mesmo configurada. Isso reforça que presença de pacotes não equivale a integração visual funcional.
- **Feito no código:** entradas de autostart MATE explícitas, remoção do banco dconf herdado e verificações correspondentes adicionadas ao script/validador.
- **Pendente:** executar a validação estática e revisar o resultado. Depois, somente com autorização do usuário, compilar e verificar os três ícones em uma sessão Live MATE real.
- **Não testado:** nenhuma nova ISO foi compilada; nenhuma sessão Live foi iniciada após essas mudanças. A ISO #50 permanece inalterada. Não iniciar build sem autorização explícita.

Última atualização: 2026-11-20

## Otimização do tamanho da ISO em 2026-11-20

- Foi criada a branch isolada `optimize/venom-iso-size`, partindo do estado da build #50, para preparar a redução do tamanho sem alterar `main` nem a branch principal de estabilidade.
- Diagnóstico confirmado nos logs da build #50: SquashFS de 3.731,72 MiB, filesystem descompactado de 10.526,9 MiB e ISO final de aproximadamente 4,7 GiB.
- Alterações preparadas em `scripts/build-venom-iso.sh`: remoção de pacotes pesados não essenciais ao perfil MATE Live; remoção das dependências Qt WebEngine/Doxygen do Calamares (módulo webview já desativado); stripping de símbolos; exclusão do pacote shelly-git-debug; remoção dos arquivos de pacotes duplicados dentro da ISO; preservação apenas do cursor Bibata Modern Classic; compressão SquashFS XZ com filtro x86.
- Os dois kernels e seus cabeçalhos continuam preservados: `linux`, `linux-headers`, `linux-lts` e `linux-lts-headers`. MATE, LightDM, Firefox, Ferdium, Shelly, IPTVnator, Materia Dark e Papirus também permanecem no escopo.
- Documentação técnica: `docs/ISO-SIZE-OPTIMIZATION.md`.
- Consultar o HEAD atual de `optimize/venom-iso-size` no GitHub antes de retomar; a branch contém as alterações descritas em `docs/ISO-SIZE-OPTIMIZATION.md`.
- Nenhuma build foi iniciada nesta branch; a consulta ao Actions retornou zero execuções para ela. O workflow de ISO não inclui essa branch na lista de gatilhos de push.
- Na retomada de 2026-11-20, a revisão estática encontrou uma inconsistência: `scripts/validate-build.sh` ainda exigia Zstandard nível 19, enquanto o script de build já configurava SquashFS XZ. A verificação foi corrigida para exigir XZ com filtro x86, dicionário de 100% e bloco de 1 MiB; a mensagem de erro também foi alinhada. Commits: `1aadffe1c2c7d3b772c166e7cebc98329d7b4f54` e `429bdbfef663156c2154cba833e0216ce563ae5c`. A validação estática ainda não foi executada.
- **Não declarar redução de tamanho alcançada ainda.** As alterações não foram compiladas nem testadas. A meta de 2,5–3 GB é estimativa; medir somente após uma build futura. XZ pode aumentar o tempo de build e de inicialização Live.
- Próximo passo, quando o usuário autorizar retomar a compilação: validar sintaxe e contratos estáticos, executar a build nesta branch isolada, comparar o tamanho real e testar boot MATE e os dois modos do Calamares em VM. Não mesclar na branch de estabilidade nem em `main` sem validação e autorização.


## Repositório e regras

- Repositório oficial: `cn1988r-coder/forja-iso`. O nome `forja-iso` é legado técnico; não renomear sem autorização.
- Branch de trabalho autorizada no momento: `fix/forja-calamares-stability`.
- Nunca alterar `main`.
- Não criar branches sem autorização explícita.
- Antes de editar: conferir HEAD da branch, workflows ativos e este documento.
- Nunca fazer push enquanto uma compilação estiver ativa. A workflow de ISO usa `concurrency.cancel-in-progress: true`, então um novo push pode cancelar uma execução anterior.
- Não declarar uma ISO pronta apenas porque a workflow passou. Exigir artefato, SHA-256 e testes de boot/instalação em VM.

## Retomada em 2026-11-20 após a compilação #48

- Build #48: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44690575457), run ID `44690575457`, job ID `136135115857`, commit `736242cdce6de7ea574c25b1a8824dc25a70a655`; encerrada com falha durante `mkarchiso`. Nenhuma ISO, SHA-256 ou artefato foi produzido.
- O log confirma que o pacote Calamares foi instalado e `/usr/bin/calamares` estava executável. A falha da verificação ocorreu porque `/usr/bin/venom-calamares` estava com modo `0644`, sem permissão de execução, embora o script externo já ajustasse o modo antes do hook. A instalação do pacote local no hook restaurou/perdeu o modo do wrapper.
- Correção aplicada após a instalação local do pacote Calamares: o hook agora executa `chmod 0755 /usr/bin/venom-calamares` antes de validar os dois executáveis. Commit: `52eb21af58082ccd8384de5394e021caf5a1581c`.
- Validação #1150: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44690583329), run ID `44690583329`, job ID `136135142329`, commit `1331eaf32b2b33b25099e1ec18229b553cc14b8c`; falhou em `scripts/validate-build.sh`. A extração dos heredocs Python funcionava, mas o validador aplicava `ast.parse` ao arquivo Bash inteiro, incluindo a instrução `chmod 0755`, causando SyntaxError.
- Correção aplicada: o AST agora analisa somente o bloco Python LightDM já extraído, onde está declarada a regex de instalação do Calamares. Commit: `43b58c90fd548b6d951a87e947ef6f19a2359f62`.
- As duas correções foram gravadas na branch autorizada. Ainda não foram validadas por uma nova execução de CI/build; não presumir sucesso. Verificar workflows disparados pelos commits e aguardar conclusão antes de novas alterações.
- A branch continua `fix/forja-calamares-stability`; `main` não foi alterada. Nenhuma ISO aprovada.

## Retomada em 2026-11-20 após a compilação #47

- Build #47: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44687736973), run ID `44687736973`, job ID `136125966837`, commit `cb3ae60d7061d7815f664bc66acc2773e1494835`; encerrada com falha.
- A compilação do ambiente Arch/EndeavourOS e a preparação dos pacotes foram concluídas. A etapa `mkarchiso` não chegou a iniciar. Nenhuma ISO, SHA-256 ou artefato foi produzido.
- Causa confirmada no log: a checagem externa executada logo após `prepare.sh` exigia `airootfs/usr/bin/calamares`. Porém, no commit fixado, o `prepare.sh` upstream apenas prepara a árvore `airootfs`, comenta o pacote remoto Calamares e compila o esqueleto do usuário; o pacote Calamares local é instalado mais tarde pelo hook `run_before_squashfs.sh`. Portanto, a checagem estava no estágio errado. A própria rotina injetada no hook já verifica o pacote instalado e o executável depois de `pacman -U`.
- Correção aplicada nesta retomada: a checagem externa passa a validar somente a presença e a permissão do wrapper VENOM, enquanto a validação do binário Calamares permanece dentro do hook, após a instalação do pacote local.
- Validação estática #1147: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44687736924), job ID `136125966668`; falhou no próprio validador Python ao extrair e recompilar a expressão regular a partir do código-fonte. A checagem foi reescrita para obter a string literal por meio da AST do Python, evitando a extração frágil por regex.
- Após estas correções, ainda é necessário executar a validação estática e uma nova compilação. Nenhum resultado novo foi presumido.
- A branch permanece `fix/forja-calamares-stability`; `main` não foi alterada. A PR #20 continua aberta e não foi modificada.

## Últimas compilações conhecidas

- Build #45: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44681763814), run ID `44681763814`, job ID `136106583379`, commit `6e78f7153f834fa041f8a31415f2d71d06f37621`; falhou em 2026-11-20 05:51:09 UTC durante o hook `run_before_squashfs.sh`, dentro da etapa `mkarchiso`. O pacote Calamares e `/usr/bin/calamares` estavam presentes e executáveis. A causa real foi `/usr/bin/venom-calamares` com modo `0644` (log: `-rw-r--r--`), enquanto o hook exige ambos os executáveis com bit de execução. Nenhuma ISO, SHA-256 ou artefato foi produzido.
- Validação estática #1145: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44681763890); falhou porque o marcador do bloco LightDM omitia a aspa final do delimitador `<<'PY'`. O fixture da regex também representava a quebra de linha incorretamente. Ambos foram corrigidos nesta revisão.
- Build #44: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44678493077).
- Run ID: \`44678493077\`; job ID: \`136095951256\`.
- Commit: \`201d494b2c706bfde24071053e053488935f532b\`.
- Branch: \`fix/forja-calamares-stability\`.
- Estado: \`failure\`, encerrada em 2026-11-20 05:29:25 UTC.
- Preparação do ambiente Arch/EndeavourOS concluída. A etapa \`mkarchiso\` não foi iniciada.
- Erro real: o patch do script upstream concatenou o comando \`pacman -U\` com os caracteres literais \`\\n\`, em vez de inserir uma quebra de linha. O Bash reportou \`syntax error near unexpected token 'then'\` ao interpretar o \`if\` seguinte.
- Nenhuma ISO, hash ou artefato foi produzido.
- Validação estática #1144: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44678493107), job ID \`136095951123\`, também falhou. O parser em \`scripts/validate-build.sh\` procurava o marcador do bloco LightDM com um separador literal incorreto e terminou em \`IndexError: list index out of range\`. A validação não chegou às verificações seguintes.
- Build #43: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44677226774), run ID \`44677226774\`, job ID \`136091830633\`, commit \`0357b885d0496ad21691b09af3871764a5b6dcc1\`; falhou antes do \`mkarchiso\` por \`NameError: name 're' is not defined\`. Nenhuma ISO ou hash foi produzido.


## Correções registradas no commit 201d494, aguardando nova validação

O usuário autorizou corrigir a falha #43 e instalar os dois kernels, com LTS como padrão:
1. O bloco Python do LightDM agora importa `re`.
2. A regex do comando upstream `pacman -U --noconfirm --needed -- "/root/packages/"*".pkg.tar.zst"` foi corrigida para reconhecer o asterisco e a extensão literal. A variável `install_command` não utilizada foi removida.
3. `linux`, `linux-headers`, `linux-lts` e `linux-lts-headers` são exigidos nos manifestos Live e online.
4. A configuração gerada do GRUB define `VENOM OS, with Linux linux-lts` como entrada padrão e mantém o kernel normal instalado como alternativa.
5. A validação estática foi ampliada para testar a importação, a regex, os quatro pacotes nos dois manifestos e o padrão LTS do GRUB.

**Estado:** alterações incluídas neste commit. A validação estática e a compilação ISO disparadas pelo push ainda precisam terminar. Mesmo com build bem-sucedida, a entrada real do GRUB deve ser conferida no `grub.cfg` gerado e os dois kernels precisam ser testados em VM antes de declarar o LTS como padrão funcional.

## Arquivos a revisar na próxima intervenção

- `scripts/build-venom-iso.sh`: importação `re` e regex corrigidas neste commit; confirmar que o build ultrapassa a etapa de LightDM.
- `build/packages.mate` e `build/packages.arch`: quatro pacotes de kernel exigidos em ambos os manifestos.
- `scripts/patch-calamares.py`: valida os kernels e gera `GRUB_DEFAULT="VENOM OS, with Linux linux-lts"`.
- Configuração de GRUB/initramfs: confirmar a entrada exata em `/boot/grub/grub.cfg` gerado e testar boot dos dois kernels em VM antes de declarar LTS como padrão funcional.

## Decisões arquiteturais permanentes

- Produto chama-se **VENOM OS**. Nome da ISO começa com `VENOM-OS-`.
- VENON é o mecanismo/repositório próprio, não o nome do sistema.
- Desktop: MATE + LightDM. Não adicionar KDE/Plasma ou XFCE.
- Instalador Calamares deve ser totalmente gráfico, sem exigir terminal do usuário.
- Instalação offline copia o sistema completo da própria ISO via `unpackfs`; preservar desktop, apps, temas e personalizações.
- Pacman é o único gerenciador de atualizações normal do sistema e aplicativos, via `sudo pacman -Syu`.
- Os kernels `linux` e `linux-lts`, quando instalados, serão atualizados pelo Pacman no fluxo normal. É necessário reiniciar para carregar o kernel novo.
- VENON é independente do Pacman, não roda automaticamente e não participa do fluxo normal de atualização. `venon-upgrade` apenas consulta/lista atualizações; `venon-update` instala somente após confirmação explícita.
- Base desejada a longo prazo: Arch Linux oficial puro. O estado atual ainda contém dependências do framework/repositórios EndeavourOS. A migração para Arch puro já foi autorizada pelo usuário; iniciar somente após a build #45 estar encerrada e registrada, então revisar dependências e ferramentas uma a uma.

## Segurança

A VENOM OS ainda não pode ser descrita como distribuição de alta segurança ou "blindada". A auditoria anterior foi parcial e identificou pontos pendentes, incluindo firewall, AppArmor/SELinux, Secure Boot, criptografia no instalador, hardening do kernel, isolamento de aplicativos, serviços mínimos e revisão de `LocalFileSigLevel = Optional`. Planejar uma etapa própria de segurança após estabilizar a compilação e os kernels; não misturar mudanças sem planejamento.

## Prestação de contas obrigatória

Em cada atualização, separar claramente:
- **Feito:** mudanças efetivamente gravadas e verificadas.
- **Pendente:** trabalho ainda não realizado.
- **Bloqueado:** impedimentos concretos.
- **Não testado:** itens que existem no código, mas ainda não foram validados em execução/VM.

Nunca apresentar intenção como implementação, nem implementação como teste aprovado.


## Retomada após a compilação #49 em 2026-11-20

- Build #49: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44694305782), run ID `44694305782`, job ID `136147274184`, commit `52eb21af58082ccd8384de5394e021caf5a1581c`; encerrada com falha durante a etapa `mkarchiso`.
- Progresso confirmado antes da falha: ambiente Arch/EndeavourOS construído; pacotes instalados; initramfs gerado; boot BIOS com SYSLINUX e UEFI com systemd-boot configurados; começou a criação do SquashFS.
- Causa exata no log: o hook gerado continha `chmod 0755 /usr/bin/venom-calamares\\nif [[ ... ]]; then`. A sequência `\\n` foi escrita literalmente, sem quebra de linha, causando `/bin/bash: syntax error near unexpected token 'then'`. A etapa `mkarchiso` terminou com exit code 1. As etapas de verificação SHA-256 e publicação foram ignoradas. Nenhuma ISO ou artefato foi produzido.
- Os avisos de firmware ausente para módulos opcionais (mlxsw_spectrum, nfp, qla*, bfa, aic94xx, wd719x, xhci_pci_renesas etc.) e os timeouts/HTTP 403 de alguns mirrors foram avisos durante o processo; não são a causa fatal registrada. A causa fatal foi a quebra de linha literal no hook.
- Correção aplicada na branch autorizada: em `scripts/build-venom-iso.sh`, a string Python que injeta o comando chmod agora contém a sequência de escape correta para produzir uma quebra de linha real no script shell, em vez de inserir os caracteres literais `\\n`. Commit: `88143611d80214fd5b945c9346b352ce8e14f47d`.
- Nenhuma build estava ativa no momento da correção. A correção ainda precisa passar pela validação estática e por uma nova compilação real. Não declarar a falha resolvida até que o novo hook seja executado e a build avance.
- Validação #1152 e #1153: ambas concluídas com sucesso, nos commits `43b58c90fd548b6d951a87e947ef6f19a2359f62` e `ef665c984cacbacdc075fc891c4d1066283053cf`, respectivamente. Elas validam o código nos respectivos commits, mas não validam a correção posterior `8814361`.
- Branch de trabalho permanece `fix/forja-calamares-stability`; `main` não foi alterada. A PR #20 não foi modificada. Próximo passo: acompanhar a validação e a build disparadas pelo commit `8814361`, sem novas alterações enquanto qualquer build estiver ativa.


## Correção dos indicadores do painel MATE: causa e controles

- A ISO #50 foi compilada no commit `88143611d80214fd5b945c9346b352ce8e14f47d`. A lista `build/packages.mate` desse commit continha `blueman`, mas **não** continha `network-manager-applet`, `mate-media`, `bluez` nem `bluez-utils`. A ausência de `network-manager-applet` e `mate-media` explica diretamente por que os indicadores de rede e volume não estavam incluídos nessa imagem. Para Bluetooth, `blueman` estava presente, mas BlueZ não era declarado explicitamente e o fluxo não verificava o autostart real nem o estado da sessão. Portanto, a causa específica do ícone Bluetooth ausente na ISO #50 ainda não está isolada.
- Na branch `optimize/venom-iso-size`, os pacotes `network-manager-applet`, `mate-media`, `blueman`, `bluez`, `bluez-utils` e o conjunto de áudio PipeWire/WirePlumber já constam do manifesto. Isso é uma correção de manifesto, ainda não uma validação da ISO.
- A validação anterior era insuficiente: verificava apenas os nomes dos pacotes e a habilitação de serviços. Não verificava os arquivos reais de autostart instalados nem a presença da área de notificação no layout MATE.
- A correção agora acrescenta ao hook de preparação da imagem verificações dos três arquivos XDG autostart, dos executáveis correspondentes e da área de notificação em `/usr/share/mate-panel/layouts/default.layout`. O perfil dconf também define explicitamente `default-layout='default'` para novos perfis Live.
- O validador estático exige que essas verificações permaneçam no script. Isso não prova que os ícones renderizam numa sessão gráfica, mas impede que uma futura compilação prossiga silenciosamente se faltar o autostart ou a área de notificação.
- **Estado:** alterações gravadas nesta branch; nenhuma nova ISO foi compilada; nenhuma VM foi testada com essas alterações. A próxima validação autorizada deve executar o validador estático e, somente com autorização separada, compilar e testar o painel numa VM. Não declarar os ícones corrigidos até a confirmação visual em sessão MATE real.


## Correção do daemon BlueZ em máquinas virtuais (2026-11-20)

- A captura enviada pelo usuário mostra o Blueman informando: "Connection to BlueZ failed" e "BlueZ daemon is not running".
- O manifesto já contém `bluez` e `blueman`, e o script já tentava habilitar `bluetooth.service`. Portanto, adicionar pacotes ou repetir apenas `systemctl enable` não resolvia a causa provável.
- A documentação ArchWiki explica que o serviço BlueZ possui a condição `ConditionPathIsDirectory=/sys/class/bluetooth`; em VMs sem adaptador Bluetooth exposto, essa condição pode fazer o systemd ignorar o serviço.
- **Correção no código:** adicionado drop-in `/etc/systemd/system/bluetooth.service.d/venom.conf` que limpa essa condição, permitindo que o daemon D-Bus BlueZ inicie mesmo sem controlador detectado. Se a VM não disponibilizar um adaptador, o Blueman ainda não poderá descobrir/disponibilizar dispositivos, mas não deverá falhar simplesmente porque o daemon foi ignorado.
- O script de preparação agora desmascara e habilita o serviço, confirma a presença de `bluetoothd` e do unit file, e exige que o serviço esteja habilitado. O validador estático verifica esses requisitos.
- **Pendente:** executar o validador estático e, após autorização explícita, compilar e testar a sessão Live. O teste de Bluetooth funcional exige adaptador real ou USB passthrough na VM.
- **Não feito:** nenhuma ISO nova foi compilada; ISO #50 preservada.



## Ajuste da ordem de validação dos applets MATE (2026-11-20)

- Na revisão da alteração anterior, foi identificado um erro de ordem: `check_session_applet` era chamado antes de os lançadores personalizados da VENOM serem escritos. Isso fazia a preparação depender da existência prévia de arquivos upstream específicos, embora o próprio script substituísse esses arquivos logo depois.
- Correção aplicada em `scripts/build-venom-iso.sh`: os três lançadores personalizados são gravados primeiro; em seguida, o script verifica a existência de cada arquivo, o executável correspondente e a linha `Exec`.
- Commit: `38d452ad06e68d324a73ec82277744f22f830e0c`.
- **Pendente:** executar o validador estático; confirmar em sessão Live MATE que os três indicadores aparecem e respondem. Nenhuma ISO nova foi compilada.
- **Importante:** a branch ainda contém a integração antiga do Calamares. Isso não está aprovado como instalador final e conflita com a decisão de desenvolver um instalador gráfico próprio em Python. Não apresentar Calamares como solução concluída.


## Correção estrutural do painel MATE: applets e separador (2026-11-20)

- O usuário esclareceu que a conectividade de rede funciona; o defeito é a ausência dos indicadores visuais no painel superior, além da ausência de separador.
- A revisão identificou que o código anterior apenas exigia a presença da área de notificação no layout padrão do pacote e criava lançadores XDG para rede/Bluetooth. Não definia um layout completo próprio com o separador e o applet nativo de volume do MATE.
- O script agora grava `/usr/share/mate-panel/layouts/default.layout` dentro do hook, depois da instalação dos pacotes, com menu, separador, área de notificação (rede/Bluetooth), applet nativo de volume `GvcAppletFactory::GvcApplet`, relógio e painel inferior com lista de janelas/áreas de trabalho.
- Os lançadores explícitos `nm-applet` e `blueman-applet` permanecem na sessão MATE. O antigo lançador de volume em bandeja foi removido para evitar duplicação: o volume passa a ser o applet nativo definido no layout.
- `scripts/validate-build.sh` agora exige no código a presença do separador, da área de notificação e do applet nativo de volume.
- Commits desta correção: `c085ccf5f30c0e7978fabf1de4d97d4844610d31`, `51f357e90145aa1036f50fe150e662eede2e655f` e `faf5a6cd9bf8cf69ac42381c4a45120dabaf2d7c`.
- **Ainda não validado:** sintaxe/execução do hook, validador estático, renderização do painel em sessão Live e presença real dos ícones. Nenhuma nova ISO foi compilada. Não afirmar que o defeito está resolvido até validar o painel graficamente em VM.


## Auditoria corretiva após os defeitos observados na ISO #50

- Revisão em 2026-11-20 do HEAD da branch `optimize/venom-iso-size`: foram encontrados problemas concretos que as verificações anteriores não detectavam.
- **Wallpaper:** o script gerava intencionalmente um PNG liso `#101010`. Foi adicionada a arte vetorial monocromática `build/airootfs/usr/share/backgrounds/venom/venom-wallpaper.svg`; o build agora a rasteriza para PNG, verifica o arquivo e exige resolução de 1920×1080 antes de copiá-lo para a imagem Live. A imagem não foi visualmente validada em uma sessão MATE.
- **Validador:** o final de `scripts/validate-build.sh` continha um bloco de verificações duplicado. A segunda cópia foi removida. As verificações do wallpaper agora exigem a arte SVG, a conversão e a checagem de resolução, e reprovam o gerador antigo de fundo liso.
- **Bloqueio de segurança da próxima ISO:** o validador agora interrompe explicitamente qualquer aprovação enquanto `build/airootfs/usr/bin/venom-installer` não existir como executável e enquanto o fluxo Calamares permanecer no script de build. Isso é intencional: o Calamares fechou durante o teste Live e a decisão arquitetural é substituí-lo por instalador próprio em Python, 100% gráfico. Não se deve gerar outra ISO com o instalador conhecido como defeituoso.
- **Painel MATE:** o layout explícito, o autostart de rede/Bluetooth e o applet nativo de volume continuam configurados, mas ainda não foram validados graficamente. A validação textual não comprova que os applets são carregados e exibidos.
- **Estado real:** foram gravadas correções no código; não foi iniciada compilação. Não há prova de boot, renderização do wallpaper, exibição dos indicadores, funcionamento do Bluetooth ou instalação completa após essas alterações.
- **Próximos bloqueios:** implementar o instalador próprio; revisar e testar o painel MATE com sessão gráfica; validar o BlueZ com e sem controlador Bluetooth; confirmar o wallpaper no desktop; executar o validador em CI; só então solicitar autorização separada para uma nova ISO.


### Resultado da validação corretiva em CI

- A workflow de validação foi habilitada para a branch `optimize/venom-iso-size`; a workflow de compilação ISO continua sem gatilho nessa branch.
- A primeira execução revelou uma checagem antiga e incorreta do pacote Shelly: o validador esperava um comando `find` diferente daquele que o build realmente executa. A checagem foi alinhada ao comando real, sem alterar a etapa de empacotamento do Shelly.
- A rasterização do wallpaper foi ajustada para usar `rsvg-convert`, fornecido por `librsvg`, explicitamente instalado no ambiente de compilação. O script também verifica a saída PNG e a resolução exata de 1920×1080.
- Execução de validação #1159, run ID `44724054395`, commit `3bf31a413e4600a59b112d8e7db5b95a2609839a`: as verificações anteriores passaram e o validador interrompeu intencionalmente o processo porque o instalador gráfico próprio ainda não existe.
- Execução #1161, run ID `44724169005`, commit `510612b157ed42be7536e2387f9c13690f1f5062`: os seis blocos Python embutidos foram compilados sem warnings; a verificação do patch Calamares e do fluxo visual passou; a execução terminou no bloqueio intencional do instalador próprio ausente.
- **Não interpretar a falha controlada como erro de sintaxe:** o validador está impedindo que se gere outra ISO com o Calamares defeituoso. Ainda assim, o projeto não está pronto para build.
- Últimos commits conhecidos desta correção: wallpaper SVG `55720ada4080b056a5696995fd5c5df3588ceec6`; rasterização `4dcc26421c019c80c061fcd22bf39a6169267b30`; limpeza de comentários/escapes `623fa236b24178040d111ba5476923831e726e5f`; validador e Shelly `3bf31a413e4600a59b112d8e7db5b95a2609839a`; dependência librsvg e contrato `510612b157ed42be7536e2387f9c13690f1f5062`.
- HEAD anterior ao registro desta nota: `510612b157ed42be7536e2387f9c13690f1f5062`.
