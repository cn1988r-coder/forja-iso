# Processo completo de engenharia e qualidade da VENOM OS

## Objetivo e regra de liberação

A VENOM OS deve ser desenvolvida e mantida como uma distribuição baseada em Manjaro, com identidade, perfis, automação, política de qualidade, documentação e ciclo de manutenção próprios. Não basta personalizar uma ISO e chamá-la de distribuição.

O objetivo é adotar, adaptar e executar as práticas públicas verificáveis do ecossistema BigLinux/BigCommunity, além dos controles adicionais necessários para a VENOM. A documentação pública da BigCommunity descreve, entre outros pontos, construção de pacotes em CI dentro de contêiner limpo, assinatura com chave própria, passagem pelo repositório `testing` antes de `stable`, validação do kernel em `testing`, perfis de ISO centralizados e geração automatizada de imagens.

**Bloqueio obrigatório:** nenhuma versão poderá ser declarada estável ou recomendada para instalação cotidiana enquanto houver etapa obrigatória reprovada, ignorada ou ainda não executada. Testes ignorados não contam como aprovados. Não reduzir a suíte, remover testes, mascarar falhas ou publicar artefatos incompletos para obter um resultado verde.

## Referências públicas do ecossistema

- BigCommunity: https://github.com/big-comm
- ISO Builder: https://github.com/big-comm/build-iso
- Perfis de ISO: https://github.com/big-comm/iso-profiles
- Documentação BigLinux: https://apps.biglinux.com.br/pt-br/home
- Apresentação pública do processo BigCommunity: https://github.com/big-comm

A documentação pública não revela necessariamente todos os procedimentos internos, critérios privados, infraestrutura ou testes executados pela equipe BigLinux. Portanto, este plano não afirma conhecer etapas internas não publicadas nem promete equivalência integral sem evidência. A cada descoberta pública, registrar a fonte, a versão/revisão examinada e como a prática foi adaptada para Manjaro e MATE.

## Execução sequencial obrigatória: do início até a etapa 17

As 17 etapas formam **um único processo completo, sequencial e obrigatório**. A execução começa na etapa 1 e avança na ordem numérica até a etapa 17. Não é permitido escolher apenas algumas etapas, pular etapas, tratar este documento como uma lista opcional ou declarar o processo concluído antecipadamente.

**Regra de avanço:** cada etapa deve ser executada por inteiro, produzir as evidências exigidas e receber estado explícito de APROVADA antes de iniciar a etapa seguinte. Se uma etapa falhar, o trabalho para nela: investigar a causa, corrigir, repetir os testes necessários e os testes de regressão, anexar evidências e só então avançar. Etapas dependentes podem exigir repetir validações anteriores após mudanças.

**Registro de andamento:** manter para cada etapa: estado (PENDENTE, EM ANDAMENTO, REPROVADA ou APROVADA), data, commit/versão, ambiente, comandos/workflows executados, logs/artefatos e resultado. Não marcar APROVADA com base em intenção, inspeção superficial, teste ignorado ou resultado de outra etapa.

**Etapas condicionais:** quando uma etapa disser “quando aplicável” ou “quando existirem”, a decisão de aplicabilidade deve ser documentada e justificada. A etapa não pode simplesmente desaparecer do processo. Se não houver componente próprio, registrar formalmente “NÃO APLICÁVEL”, com justificativa e evidência, antes de avançar.

**Critério de conclusão:** somente quando as etapas 1 a 17 estiverem APROVADAS ou formalmente justificadas como NÃO APLICÁVEIS, com evidências revisadas, a VENOM poderá ser considerada candidata a lançamento estável. A etapa 17 ainda exige aprovação final e autorização de publicação. Até lá, não recomendar a ISO para instalação cotidiana.

## Processo obrigatório, etapa por etapa

### 1. Governança, escopo e rastreabilidade
- Manter decisões de arquitetura, requisitos, versões suportadas e critérios de aceitação documentados.
- Manter histórico de alterações, responsáveis, issues, revisões e justificativas.
- Separar claramente requisitos confirmados, hipóteses e itens ainda não implementados.
- Resultado exigido: documentação atualizada e rastreável antes de alterar componentes críticos.

### 2. Perfil e identidade da distribuição
- Manter o perfil próprio `manjaro/venom-mate` como fonte central da edição.
- Revisar listas de pacotes, overlays, serviços, configurações, branding, idioma e teclado.
- Garantir consistência entre ambiente de instalação, sistema instalado e atualizações.
- Validar o perfil contra a versão real das ferramentas Manjaro usadas.
- Resultado exigido: perfil reproduzível, sem arquivos ou configurações órfãs.

### 3. Auditoria de fontes e dependências
- Usar exclusivamente a base Manjaro e repositórios oficiais Manjaro para os componentes do sistema.
- Registrar origem, versão, licença, dependências e função dos pacotes selecionados.
- Verificar dependências ausentes, conflitos, pacotes abandonados, arquivos substituídos e serviços ativados.
- Calamares deve ser exclusivamente o pacote/versão dos repositórios oficiais Manjaro; não baixar, compilar nem substituir por upstream.
- Resultado exigido: relatório de dependências e procedência sem conflitos não resolvidos.

### 4. Desenvolvimento e revisão de código
- Aplicar revisão de alterações, análise estática, formatação, verificações de shell e testes unitários/integrados pertinentes.
- Fixar revisões de fontes externas usadas no processo de construção e registrar patches locais.
- Cada patch deve ter motivação, escopo mínimo, teste de regressão e plano de remoção quando deixar de ser necessário.
- Resultado exigido: revisão e verificações automatizadas aprovadas.

### 5. Construção reproduzível de pacotes próprios (quando existirem)
- Para pacotes mantidos pela VENOM, preparar construção automatizada em ambiente limpo e isolado.
- Fixar fontes e dependências; registrar logs e resultados.
- Assinar pacotes com chave de confiança da VENOM quando houver repositório próprio.
- Nunca publicar pacote sem verificação de integridade, metadados e instalação.
- Resultado exigido: pacote reproduzível, verificável e assinado antes de distribuição.
- Nota: não criar repositório próprio apenas por aparência. Enquanto a política da VENOM for usar exclusivamente repositórios oficiais Manjaro, esta etapa se aplica somente a componentes realmente mantidos pela VENOM e não autoriza substituir pacotes oficiais.

### 6. Canal de testes e promoção de pacotes
- Adotar, quando houver pacotes próprios, fluxo separado de desenvolvimento/testes e estável.
- Pacotes e atualizações devem ser validados no canal de testes antes de qualquer promoção para estável.
- Registrar versão, changelog, testes executados, falhas conhecidas e decisão de promoção.
- Para pacotes oficiais Manjaro, respeitar os canais e o ciclo de atualização oficiais; não misturar repositórios ou antecipar pacotes de outra base.
- Resultado exigido: nenhuma promoção sem evidência de testes e aprovação.

### 7. Kernel e componentes de baixo nível
- Acompanhar versões e ciclo de suporte do kernel escolhido para a VENOM.
- Validar kernel, módulos, firmware, initramfs, microcódigo, bootloader e drivers no ambiente de testes antes da adoção.
- Testar regressões de boot, armazenamento, rede, vídeo, suspensão/retomada e periféricos.
- Resultado exigido: matriz de compatibilidade e evidência de boot e funcionamento nos ambientes-alvo.

### 8. Integração contínua e pré-validação
- Executar pipeline automatizado em cada alteração relevante.
- Separar claramente testes de código, validação do perfil, resolução de dependências e construção da imagem.
- A pré-validação deve rodar em ambiente Manjaro compatível e verificar ferramentas, repositórios, pacotes e dependências.
- Resolver dependências sem gerar ISO antes de liberar a etapa de construção.
- Guardar logs e relatórios como artefatos.
- Resultado exigido: todos os jobs obrigatórios concluídos com sucesso; nenhum job obrigatório pode ficar ignorado ou ser marcado manualmente como aprovado.

### 9. Construção automatizada da ISO
- Usar ferramentas e perfis compatíveis com Manjaro, conforme as decisões de arquitetura do projeto.
- Construir em ambiente limpo e reproduzível, com versões e fontes registradas.
- Gerar logs completos, manifesto de pacotes e metadados da imagem.
- Não iniciar build de ISO enquanto as etapas anteriores não estiverem aprovadas.
- Resultado exigido: imagem gerada sem erros, acompanhada de manifesto, logs e identificação do commit/perfil.

### 10. Integridade e segurança do artefato
- Validar estrutura da ISO, bootloader, arquivos essenciais, manifesto e ausência de arquivos inesperados.
- Calcular SHA-256 e verificar o arquivo após upload/download.
- Quando aplicável, assinar os metadados e publicar a chave de verificação.
- Resultado exigido: artefato íntegro e rastreável ao código-fonte e ao pipeline.

### 11. Testes de inicialização e hardware
- Testar boot em UEFI e BIOS/Legacy quando suportado pelo perfil.
- Testar máquinas virtuais com configurações distintas e hardware físico representativo.
- Verificar vídeo, teclado, touchpad, armazenamento, rede cabeada, Wi-Fi, Bluetooth, áudio, USB e resolução.
- Testar inicialização repetida e mensagens/logs de falha.
- Resultado exigido: matriz preenchida; falhas críticas bloqueiam a versão.

### 12. Testes completos do instalador e instalação
- Validar o fluxo real do instalador VENOM e a integração com Calamares oficial Manjaro.
- Testar idioma, teclado, particionamento, bootloader, instalação em UEFI/Legacy conforme suportado, criptografia se oferecida e tratamento de erros.
- Executar instalação em discos virtuais descartáveis; nunca usar disco real do usuário como ambiente de teste destrutivo.
- Verificar instalação em disco vazio e cenários de particionamento suportados.
- Resultado exigido: instalação completa sem erro, com logs e evidência do resultado.

### 13. Primeiro boot e validação pós-instalação
- Confirmar boot pelo disco instalado, LightDM e sessão MATE.
- Verificar tema escuro VENOM, painel, menu, rede, Bluetooth, áudio, impressoras/periféricos aplicáveis e aplicativos definidos.
- Conferir usuários, permissões, serviços, fstab, initramfs, bootloader e logs do sistema.
- Garantir que a configuração instalada corresponda ao perfil aprovado.
- Resultado exigido: checklist pós-instalação completo e sem falha crítica.

### 14. Atualização, manutenção e recuperação
- Testar atualização completa do sistema em instalação limpa e em instalação já atualizada anteriormente.
- Verificar conflitos, migrações de configuração, espaço em disco, integridade de pacotes e capacidade de reiniciar após atualização.
- Testar recuperação de boot e procedimentos de restauração documentados, quando oferecidos.
- Documentar política de suporte, atualizações, kernels e correções de segurança.
- Resultado exigido: atualização e reinicialização concluídas com sucesso, sem regressão crítica.

### 15. Regressão, estabilidade e compatibilidade
- Reexecutar suítes relevantes após correções e mudanças de pacote, kernel, perfil ou instalador.
- Manter testes de regressão para falhas já corrigidas.
- Realizar ciclos repetidos de boot, login, instalação, atualização e uso prolongado em VM e hardware físico.
- Registrar falhas conhecidas, severidade, reprodução e correção.
- Resultado exigido: nenhuma falha bloqueadora ou crítica aberta; falhas menores devem ser documentadas e avaliadas explicitamente.

### 16. Documentação, suporte e preparação da versão
- Preparar notas de versão, requisitos mínimos, hardware testado, limitações, instruções de instalação e recuperação.
- Publicar manifesto de pacotes, checksums e instruções de verificação.
- Manter canal de reporte de bugs e processo de triagem.
- Resultado exigido: usuário consegue instalar, verificar, atualizar e pedir suporte com informação suficiente.

### 17. Aprovação final e publicação
- Fazer revisão final dos resultados de todas as etapas.
- Confirmar que artefato publicado corresponde exatamente ao commit e perfil testados.
- Publicar somente após aprovação documentada e autorização de release.
- Se qualquer etapa obrigatória falhar, bloquear publicação, corrigir e repetir os testes afetados e os testes de regressão.
- Resultado exigido: release rastreável, verificável e aprovada; caso contrário, permanece pré-lançamento.

## Regras específicas e permanentes da VENOM

- Base Manjaro Linux; não importar base ou repositórios BigLinux/BigCommunity.
- Desktop MATE único, totalmente escuro, com identidade VENOM.
- LightDM.
- Calamares somente dos repositórios oficiais Manjaro, na versão compatível selecionada.
- Não substituir ferramentas críticas Manjaro por versões upstream sem aprovação e validação explícita.
- O processo de qualidade do GitRepo é apenas uma parte do processo, nunca prova isolada de que a ISO está pronta.
- A execução de testes em GitHub Actions não substitui teste real de boot, instalação, atualização e hardware.
- Nenhuma ISO estável antes de concluir todas as etapas aplicáveis e registrar evidências.

## Estado atual conhecido

- A execução #79 do workflow aprovou os testes upstream do GitRepo: 773 testes passaram e houve 1 aviso de depreciação.
- A pré-validação Manjaro estava em fila na última consulta.
- Isso não equivale à aprovação deste processo completo.
- A geração da ISO continua bloqueada até cumprir os gates de qualidade e pré-validação definidos no projeto, além das verificações de instalação e pós-instalação exigidas antes de declarar uma versão estável.

## Como manter este documento

Este documento é um plano de qualidade e uma lista de critérios de aceitação, não um registro de etapas já concluídas. Atualizar o estado de cada etapa com evidência verificável (workflow, logs, artefatos, relatório de VM ou teste físico). Nunca converter um item planejado em aprovado sem executar o teste correspondente.
