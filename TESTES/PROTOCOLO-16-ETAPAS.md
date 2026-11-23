# Regra obrigatória: sistema de testes em 16 etapas

**ESTADO DO PROJETO: BLOQUEADO POR FALTA DE AUTORIZAÇÃO PARA EXECUÇÃO.**

Este documento estabelece o sistema de testes e a ordem obrigatória das 16 etapas. Ele não autoriza a execução de nenhuma delas. Neste momento, o trabalho é exclusivamente documental: definir o processo, os critérios e os registros.

## 1. Proibição vigente

Até que o usuário dê autorização expressa para iniciar uma fase técnica, é proibido:

- compilar ou construir pacotes;
- executar comandos ou ferramentas para construir uma ISO;
- gerar ISO de qualquer tipo, inclusive experimental, de teste ou candidata;
- executar validações técnicas, testes automatizados ou testes manuais do sistema/ISO;
- iniciar CI que compile, construa, teste ou valide artefatos;
- publicar, distribuir ou disponibilizar imagens, pacotes ou versões para instalação;
- declarar qualquer etapa aprovada, concluída, validada ou estável.

Não interpretar a existência deste protocolo como autorização. Não iniciar etapas automaticamente, não antecipar etapas e não decidir por conta própria que existe autorização. Uma autorização para uma atividade não significa autorização para as demais.

**Até nova autorização explícita, somente documentação e organização do próprio protocolo são permitidas.**

## 2. Ordem fixa das 16 etapas

As etapas são obrigatórias, sequenciais e não podem ser puladas. A descrição de uma etapa define o que deverá ser avaliado futuramente; não é uma ordem para executar agora.

1. **Perfil próprio XFCE:** revisar o perfil já registrado em `manjaro/xfce`, sua estrutura, manifestos, serviços, overlay e configurações do desktop. A base `manjaro/base` permanece neutra e sem ambiente gráfico; o XFCE é uma camada separada da edição.
2. **Pacotes e dependências:** estabelecer a lista de pacotes e avaliar dependências, conflitos, disponibilidade e compatibilidade com os repositórios Manjaro escolhidos.
3. **Desenvolvimento e código:** revisar o código, scripts, configurações e automações mantidos pelo projeto.
4. **Construção de pacotes:** avaliar o processo de empacotamento, integridade, dependências e rastreabilidade dos pacotes do projeto. Nenhuma compilação está autorizada no estado atual.
5. **Canal Testing e Stable:** definir e avaliar o fluxo de promoção entre canais, distinguindo os canais de pacotes Manjaro dos estados de liberação do projeto.
6. **Kernel e drivers:** avaliar kernel, módulos, firmware e compatibilidade com o hardware previsto.
7. **Integração contínua (CI):** definir e revisar o fluxo de CI, os bloqueios, os critérios e a rastreabilidade. Não ativar automações que compilem, construam ou validem artefatos sem autorização expressa.
8. **Construção da ISO:** quando autorizada, construir a imagem com ferramentas oficiais e compatíveis do Manjaro, registrando ambiente e versões utilizadas. Esta etapa está proibida no momento.
9. **Integridade e segurança:** quando autorizada e havendo artefato, verificar integridade, checksums, assinaturas quando aplicáveis e requisitos de segurança.
10. **Boot e hardware:** quando autorizada e havendo imagem, testar inicialização nos modos de firmware e equipamentos definidos.
11. **Instalação completa:** quando autorizada, testar o processo completo de instalação previsto para a edição.
12. **Primeiro boot:** quando autorizada, testar o primeiro início do sistema instalado, serviços e sessão previstos.
13. **Atualização e recuperação:** quando autorizada, testar atualizações, recuperação e tratamento de falhas.
14. **Estabilidade e regressão:** quando autorizada, executar testes de estabilidade e regressão e registrar os resultados.
15. **Documentação de uso:** preparar e revisar a documentação de instalação, operação, limitações, suporte e recuperação.
16. **Aprovação e publicação STABLE:** revisar todas as evidências e obter autorização expressa antes de qualquer publicação. Esta etapa não pode ser aprovada por inferência.

## 3. Estados permitidos para cada etapa

- **PENDENTE:** ainda não executada ou não concluída.
- **BLOQUEADO:** depende de autorização, pré-requisito ou correção.
- **EM EXECUÇÃO:** somente após autorização expressa para aquela fase.
- **REPROVADO:** execução autorizada realizada e critério não atendido.
- **INCONCLUSIVO:** evidência insuficiente ou resultado ambíguo.
- **APROVADO:** execução concluída, critérios atendidos e evidências verificáveis registradas.

Não marcar uma etapa como APROVADO apenas por análise documental, intenção, configuração preparada ou ausência de erro aparente. Aprovação exige evidência correspondente à atividade real.

## 4. Critérios e evidências

Quando a execução vier a ser autorizada, cada etapa deverá ter critérios objetivos definidos antes do teste. O registro deverá conter, conforme aplicável:

- número e nome da etapa e casos de teste;
- critério de aprovação;
- data e responsável;
- commit exato do código;
- versões e canais dos repositórios Manjaro;
- ambiente, firmware e hardware usados;
- identificação do artefato e SHA-256, quando houver;
- resultado, logs e evidências;
- falhas encontradas, correções e retestes.

Resultados de uma imagem não podem ser reutilizados para outra imagem ou para um commit diferente. Toda candidata deverá ser identificada de forma inequívoca.

## 5. Portões de autorização

A passagem de uma fase para outra exige duas coisas distintas: conclusão documentada dos requisitos anteriores e autorização expressa do usuário para iniciar a próxima atividade. A aprovação técnica não concede, por si só, permissão para distribuir ou publicar.

A publicação STABLE exige todas as 16 etapas aprovadas, evidências completas da mesma versão e autorização expressa específica para publicar.

## 6. Estado inicial obrigatório

| Item | Estado atual |
|---|---|
| Protocolo de 16 etapas | REGISTRADO |
| Execução de testes técnicos | NÃO AUTORIZADA |
| Compilação de pacotes | PROIBIDA |
| Construção/geração de ISO | PROIBIDA |
| Validação técnica de ISO | NÃO AUTORIZADA |
| CI de build/teste/validação | NÃO AUTORIZADA |
| Distribuição de artefatos | PROIBIDA |
| Etapas 1 a 15 | PENDENTES |
| Etapa 16 | BLOQUEADA |
| Publicação STABLE | BLOQUEADA |

Este é o estado deliberado do projeto. Nenhum teste técnico foi autorizado por este documento e nenhuma ISO é declarada existente, construída, testada ou aprovada.

## 7. Referências de processo

- Documentação Manjaro: https://wiki.manjaro.org/
- Perfis oficiais do Manjaro: https://code.manjaro.org/profiles-and-settings/iso-profiles
- Ferramentas oficiais do Manjaro: https://code.manjaro.org/tools/manjaro-tools

As 16 etapas acima são regras próprias deste repositório VENOM OS.
