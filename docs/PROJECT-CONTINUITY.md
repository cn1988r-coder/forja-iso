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

## Última compilação conhecida

- Build #43: [GitHub Actions](https://github.com/cn1988r-coder/forja-iso/actions/runs/44677226774).
- Run ID: `44677226774`; job ID: `136091830633`.
- Commit: `0357b885d0496ad21691b09af3871764a5b6dcc1`.
- Branch: `fix/forja-calamares-stability`.
- Estado: `failure`, encerrada em 2026-11-20 04:53:34 UTC.
- Erro registrado: `NameError: name 're' is not defined` no bloco Python que personaliza `run_before_squashfs.sh`, durante a configuração do LightDM.
- A execução não chegou ao `mkarchiso`. Não há ISO nem hash produzido pela build #43.
- A validação estática paralela #1142 havia passado, mas isso não substitui a compilação nem testes reais.

## Correções solicitadas, ainda não gravadas/confirmadas

O usuário autorizou aproveitar a falha da build #43 para:
1. corrigir a importação ausente de `re` no bloco Python;
2. adicionar `linux-lts` e `linux-lts-headers` ao ambiente Live/ISO e ao manifesto do instalador online;
3. manter kernel normal e LTS instalados;
4. configurar o kernel LTS como padrão no GRUB, mantendo o kernel normal como alternativa;
5. registrar as alterações e o estado no GitHub para continuidade.

**Estado real neste momento:** nenhuma dessas alterações foi confirmada no repositório. A tentativa anterior de preparar um commit foi interrompida por uma verificação de texto que não encontrou o trecho esperado. O HEAD da branch continua em `0357b885d0496ad21691b09af3871764a5b6dcc1`. Não afirmar que a correção, os pacotes LTS ou o GRUB padrão LTS já estão implementados.

## Arquivos a revisar na próxima intervenção

- `scripts/build-venom-iso.sh`: bloco Python de LightDM; corrigir importação de `re`; revisar regex do patch Calamares e remover código morto somente após confirmar o conteúdo exato.
- `build/packages.mate`: manifesto mesclado ao perfil Live/ISO. Verificar inclusão de `linux-lts` e `linux-lts-headers`.
- `build/packages.arch`: manifesto do instalador online. Verificar inclusão de `linux-lts` e `linux-lts-headers`.
- `scripts/patch-calamares.py`: confirmar que o manifesto online instala ambos os kernels e headers.
- Configuração de GRUB/initramfs: verificar como o perfil gera entradas para múltiplos kernels; não presumir que um texto `GRUB_DEFAULT` corresponda ao nome real da entrada. Confirmar `/boot/grub/grub.cfg` gerado e testar boot em VM antes de declarar LTS como padrão funcional.

## Decisões arquiteturais permanentes

- Produto chama-se **VENOM OS**. Nome da ISO começa com `VENOM-OS-`.
- VENON é o mecanismo/repositório próprio, não o nome do sistema.
- Desktop: MATE + LightDM. Não adicionar KDE/Plasma ou XFCE.
- Instalador Calamares deve ser totalmente gráfico, sem exigir terminal do usuário.
- Instalação offline copia o sistema completo da própria ISO via `unpackfs`; preservar desktop, apps, temas e personalizações.
- Pacman é o único gerenciador de atualizações normal do sistema e aplicativos, via `sudo pacman -Syu`.
- Os kernels `linux` e `linux-lts`, quando instalados, serão atualizados pelo Pacman no fluxo normal. É necessário reiniciar para carregar o kernel novo.
- VENON é independente do Pacman, não roda automaticamente e não participa do fluxo normal de atualização. `venon-upgrade` apenas consulta/lista atualizações; `venon-update` instala somente após confirmação explícita.
- Base desejada a longo prazo: Arch Linux oficial puro. O estado atual ainda contém dependências do framework/repositórios EndeavourOS. Não iniciar migração sem autorização explícita.

## Segurança

A VENOM OS ainda não pode ser descrita como distribuição de alta segurança ou "blindada". A auditoria anterior foi parcial e identificou pontos pendentes, incluindo firewall, AppArmor/SELinux, Secure Boot, criptografia no instalador, hardening do kernel, isolamento de aplicativos, serviços mínimos e revisão de `LocalFileSigLevel = Optional`. Planejar uma etapa própria de segurança após estabilizar a compilação e os kernels; não misturar mudanças sem planejamento.

## Prestação de contas obrigatória

Em cada atualização, separar claramente:
- **Feito:** mudanças efetivamente gravadas e verificadas.
- **Pendente:** trabalho ainda não realizado.
- **Bloqueado:** impedimentos concretos.
- **Não testado:** itens que existem no código, mas ainda não foram validados em execução/VM.

Nunca apresentar intenção como implementação, nem implementação como teste aprovado.
