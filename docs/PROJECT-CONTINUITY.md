# VENOM OS - Registro permanente de continuidade

Última atualização: 2026-11-20

Este documento é a referência operacional para retomar o desenvolvimento sem depender de o usuário recontar o histórico. Deve ser consultado no início de cada sessão de trabalho e atualizado após mudanças relevantes, builds, decisões e testes.

## Repositório e regras

- Repositório oficial: `cn1988r-coder/forja-iso`. O nome `forja-iso` é legado técnico; não renomear sem autorização.
- Branch de trabalho autorizada no momento: `fix/forja-calamares-stability`.
- Nunca alterar `main`.
- Não criar branches sem autorização explícita.
- Antes de editar: conferir HEAD da branch, workflows ativos e este documento.
- Nunca fazer push enquanto uma compilação estiver ativa. A workflow de ISO usa `concurrency.cancel-in-progress: true`, então um novo push pode cancelar uma execução anterior.
- Não declarar uma ISO pronta apenas porque a workflow passou. Exigir artefato, SHA-256 e testes de boot/instalação em VM.

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
