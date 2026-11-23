# Regra obrigatória: protocolo de 16 etapas e bloqueio de ISO

**Estado atual: BLOQUEADO.** Este documento é uma regra do repositório, não uma autorização para executar etapas.

## Regra de bloqueio

Até que as 16 etapas abaixo tenham sido executadas, documentadas e aprovadas, fica proibido:

- compilar pacotes;
- executar ferramentas de construção de ISO;
- gerar ISO, seja experimental, candidata, de teste ou estável;
- iniciar validação de uma ISO;
- publicar artefatos de instalação ou disponibilizar uma imagem para uso;
- declarar o sistema pronto, validado ou estável.

**No estado atual, não executar testes técnicos nem validações.** O trabalho permitido limita-se a manter este protocolo, organizar critérios, documentação e preparar os registros que serão usados futuramente. A preparação documental não conta como aprovação de etapa.

Nenhuma etapa pode ser marcada como aprovada sem execução real e evidência verificável. Etapas não executadas permanecem PENDENTES. Falhas, bloqueios ou resultados inconclusivos impedem a liberação.

## As 16 etapas obrigatórias

A sequência abaixo é fixa. Não pular, combinar ou dispensar etapas sem uma decisão explícita registrada no repositório.

1. **Perfil próprio XFCE:** conferir estrutura, configuração e coerência do perfil da edição XFCE quando essa edição for incorporada ao projeto. A base atual permanece neutra, sem ambiente gráfico.
2. **Pacotes e dependências:** verificar a lista de pacotes, dependências, conflitos e disponibilidade nos repositórios Manjaro escolhidos.
3. **Desenvolvimento e código:** revisar scripts, configurações, automações e código mantido pelo projeto.
4. **Construção de pacotes:** verificar processo, integridade, dependências e rastreabilidade dos pacotes produzidos pelo projeto.
5. **Canal Testing e Stable:** verificar o fluxo de promoção entre canais, sem confundir canal de pacotes Manjaro com estado de aprovação da ISO.
6. **Kernel e drivers:** verificar kernel, módulos, firmware e compatibilidade de hardware suportado.
7. **Integração contínua (CI):** verificar automações, critérios de bloqueio, rastreabilidade e comportamento diante de falhas.
8. **Construção da ISO:** verificar a geração da imagem usando ferramentas oficiais e compatíveis do Manjaro. Esta etapa só poderá ser executada depois de autorização para iniciar a fase de testes.
9. **Integridade e segurança:** verificar checksum, assinatura quando aplicável, integridade do sistema de arquivos e requisitos de segurança.
10. **Boot e hardware:** testar inicialização e reconhecimento de hardware nos modos de firmware e equipamentos definidos para suporte.
11. **Instalação completa:** testar o fluxo de instalação previsto para a edição.
12. **Primeiro boot:** testar o primeiro início do sistema instalado, incluindo serviços e sessão previstos.
13. **Atualização e recuperação:** testar atualização, tratamento de falhas e procedimentos de recuperação.
14. **Estabilidade e regressão:** executar testes de estabilidade e regressão, registrando falhas e reproduções.
15. **Documentação de uso:** conferir instruções de instalação, operação, limitações, suporte e recuperação.
16. **Aprovação e publicação STABLE:** revisão final das evidências e autorização explícita para publicar exatamente o artefato testado.

## Critérios de resultado

Cada verificação, quando a execução for autorizada no futuro, deverá receber um dos seguintes estados:

- **APROVADO:** teste executado e critério atendido, com evidência anexada.
- **REPROVADO:** teste executado e critério não atendido.
- **BLOQUEADO:** dependência ou pré-requisito impediu a execução.
- **INCONCLUSIVO:** evidência insuficiente ou resultado ambíguo.
- **PENDENTE:** ainda não executado.

Somente **APROVADO** satisfaz uma etapa obrigatória. BLOQUEADO, INCONCLUSIVO, PENDENTE ou REPROVADO não autorizam avanço para publicação.

## Registro e evidências

Para cada etapa, o futuro registro deverá conter, no mínimo:

- identificação da etapa e do caso de teste;
- data e responsável pela execução;
- commit exato do código-fonte;
- versão/canal dos repositórios Manjaro utilizados;
- identificação e SHA-256 do artefato, quando houver ISO;
- ambiente, firmware e hardware usados;
- resultado, logs e evidências;
- defeitos encontrados e respectiva resolução.

As evidências de todas as etapas devem corresponder à mesma versão candidata. Não se pode substituir a ISO depois dos testes e reaproveitar os resultados para outro arquivo.

## Estado inicial obrigatório

| Etapa | Estado |
|---|---|
| 1 a 15 | PENDENTE, sem execução autorizada |
| 16 | BLOQUEADO |
| Geração de pacotes/ISO | BLOQUEADA |
| Validação de ISO | NÃO INICIADA |
| Publicação STABLE | BLOQUEADA |

Este estado é deliberado. A existência deste protocolo não significa que qualquer teste tenha sido executado ou que a ISO exista.

## Referências de processo

- BigLinux ISO Profiles: https://github.com/biglinux/iso-profiles
- Documentação do portão openQA do BigLinux: https://github.com/biglinux/iso-profiles/tree/main/openqa
- Modelo de branches do Manjaro: https://wiki.manjaro.org/index.php?title=Switching_Branches

As referências inspiram a separação entre candidato, evidência de testes e liberação. As 16 etapas acima são a regra deste repositório e não devem ser apresentadas como uma lista oficial do BigLinux.
