# Plano de testes virtuais e critérios de aprovação Stable

## Finalidade

Definir antecipadamente como será demonstrado, com evidências reproduzíveis, que a VENOM OS XFCE inicia, apresenta a sessão gráfica, instala e inicia novamente a partir do disco virtual.

Este documento é um plano. **Não executa testes, não valida configurações, não constrói pacotes e não gera ISO.** Todas as operações técnicas permanecem bloqueadas até autorização expressa específica.

## 1. Ambiente virtual futuro

A preparação pelo GitHub Actions organiza dois ambientes distintos:

- Runner Ubuntu hospedado: hospeda Docker e QEMU/OVMF.
- Contêiner Manjaro: recebe Manjaro Tools e o checkout dos perfis oficiais.

Para a futura execução de boot, QEMU deverá operar em emulação por software (TCG), sem presumir disponibilidade de KVM ou virtualização aninhada no runner hospedado. O contêiner de preparação não será confundido com a máquina virtual que inicializa a distribuição.

A imagem ISO necessária aos testes terá de existir previamente como artefato autorizado. O workflow de preparação não a cria.

## 2. Matriz obrigatória de inicialização

| ID | Cenário futuro | Evidência exigida |
|---|---|---|
| BOOT-01 | Inicialização da mídia em BIOS/Legacy | Log de boot e captura da tela final |
| BOOT-02 | Inicialização da mídia em UEFI com OVMF | Log de boot e captura da tela final |
| LIVE-01 | Entrada no ambiente Live | Evidência de sessão Live utilizável |
| DM-01 | LightDM disponível no ambiente Live/instalado, conforme arquitetura definida | Captura da tela de login |
| XFCE-01 | Entrada na sessão XFCE | Captura do desktop carregado |
| XFCE-02 | Painel, Whisker, Docklike e área de notificação | Capturas da interface e registro de sessão |
| VIS-01 | Materia Dark, Papirus Azul e Bibata | Capturas que mostrem tema, pastas e cursor |
| HW-01 | Detecção de dispositivos virtuais e vídeo | Registro de dispositivos e driver utilizado |
| NET-01 | Rede virtual | Evidência de interface e conectividade |
| INST-01 | Abertura do Calamares no Live | Captura do instalador aberto |
| INST-02 | Instalação completa em disco virtual | Log da instalação e identificação do disco virtual |
| DISK-01 | Reinicialização pelo disco instalado em BIOS | Log e captura após o boot |
| DISK-02 | Reinicialização pelo disco instalado em UEFI | Log e captura após o boot |
| FIRST-01 | Primeiro login no sistema instalado | Captura da sessão XFCE |
| FIRST-02 | Serviços e personalização no primeiro boot | Registros de serviços e captura do desktop |
| REPEAT-01 | Reinicializações repetidas do sistema instalado | Logs separados por ciclo, sem falha crítica |

A matriz será adaptada somente se houver justificativa técnica documentada. Não se deve remover um cenário obrigatório apenas porque ele falhou.

## 3. Critérios para considerar que o sistema iniciou

Um boot só será considerado bem-sucedido quando houver evidência de que:

1. O firmware virtual reconheceu a mídia ou o disco virtual.
2. O carregador de boot foi iniciado.
3. O kernel carregou sem erro fatal.
4. O sistema alcançou o alvo gráfico esperado.
5. LightDM apresentou a tela de login quando aplicável.
6. Foi possível entrar na sessão XFCE.
7. O desktop permaneceu utilizável, sem travamento ou reinício inesperado.
8. Os registros correspondem ao commit e ao artefato efetivamente testados.

Uma mensagem de sucesso de workflow, a existência de arquivos de configuração ou a instalação de pacotes não substituem essas evidências.

## 4. Critérios para instalação e primeiro boot

A instalação somente será aprovada quando:

- Calamares abrir no ambiente Live;
- o instalador concluir sem erro crítico;
- o disco virtual instalado for inicializável;
- o firmware BIOS e/ou UEFI usado no cenário conseguir iniciar o disco;
- LightDM e XFCE iniciarem após a instalação;
- o usuário conseguir entrar na sessão;
- os serviços essenciais iniciarem;
- o sistema completar reinicializações repetidas sem falha crítica.

A aprovação em um modo de firmware não comprova o outro. BIOS e UEFI terão resultados separados.

## 5. Evidências obrigatórias por execução

Cada execução autorizada deverá registrar:

- commit completo do repositório;
- identificação e SHA-256 do artefato ISO;
- versão da imagem do contêiner e ferramentas utilizadas;
- versão do QEMU e firmware OVMF;
- parâmetros da máquina virtual, memória, CPU, disco e firmware;
- cenário e resultado individual;
- logs completos de boot e instalação;
- capturas de tela do Live, login, XFCE e primeiro boot;
- falhas, correções e retestes;
- vínculo entre cada evidência e o cenário correspondente.

Os arquivos deverão ser publicados como artefatos de execução com retenção definida. Não usar logs de outro commit ou outra ISO para aprovar a candidata atual.

## 6. Critérios de bloqueio de Stable

A versão não poderá receber estado Stable se ocorrer qualquer uma destas condições:

- falha em BIOS ou UEFI dentro da matriz declarada;
- kernel não carregar;
- ambiente Live não alcançar a sessão gráfica prevista;
- LightDM não apresentar login;
- XFCE não iniciar ou ficar inutilizável;
- Calamares não abrir ou não concluir a instalação;
- sistema instalado não iniciar pelo disco virtual;
- primeiro login falhar;
- serviço essencial falhar;
- existir falha crítica sem correção e reteste;
- faltar evidência rastreável para qualquer cenário obrigatório.

Resultados inconclusivos também bloqueiam Stable. Não converter ausência de evidência em aprovação.

## 7. Limites e cobertura

Testes virtuais demonstram comportamento em máquinas virtuais com os dispositivos configurados. Eles não garantem compatibilidade universal com todo hardware físico. Antes de uma declaração Stable, a matriz virtual deverá ser complementada por testes em hardware físico representativo, incluindo a máquina-alvo definida para o projeto, quando essa fase for autorizada.

## 8. Estado atual

- Plano e critérios: documentados neste arquivo.
- Ambiente virtual: workflow de preparação configurado, ainda não executado.
- QEMU/OVMF: previstos para instalação no runner, ainda não instalados.
- Contêiner Manjaro e Manjaro Tools: previstos para preparação, ainda não instalados.
- Imagem ISO: não gerada.
- Boot, Live, instalação e primeiro boot: não testados.
- Validações técnicas: não executadas e continuam proibidas.
- Aprovação Stable: bloqueada.

**Este plano não é evidência de funcionamento. É a especificação do que deverá ser demonstrado quando os testes forem autorizados.**
