# Registro de decisões da VENOM OS

**Projeto:** VENOM OS  
**Repositório:** `cn1988r-coder/forja-iso`  
**Branch de trabalho:** `feature/venom-os-2.0-xfce`  
**Última atualização:** 2026-11-22

Este arquivo é a referência versionada para as decisões do projeto. Deve ser consultado antes de planejar ou executar mudanças.

## 1. Direção atual do projeto

- A VENOM OS deve ser uma distribuição baseada no Arch Linux, com identidade, estrutura, integração e decisões técnicas próprias.
- O objetivo não é entregar apenas o Arch Linux com tema, papel de parede, ícones, cores ou nome diferentes.
- Usar componentes e infraestrutura do Arch como base é permitido. A identidade da distribuição deve vir também da integração do sistema, ferramentas, configurações, instalador, manutenção e experiência de uso.
- Não é necessário reimplementar do zero todos os componentes para que a VENOM OS tenha identidade própria.

## 2. Regras obrigatórias de continuidade

1. Registrar neste arquivo cada nova decisão aprovada pelo usuário, com data e descrição clara.
2. Consultar este registro e o estado atual do repositório antes de propor ou executar mudanças.
3. A decisão mais recente e explícita do usuário prevalece sobre registros anteriores.
4. Não apresentar decisões substituídas ou descartadas como se ainda estivessem vigentes. Se for necessário preservar seu histórico, identificá-las claramente como **SUBSTITUÍDAS** ou **DESCARTADAS**.
5. Não pedir ao usuário que decida novamente algo que já esteja decidido e registrado.
6. Não alterar uma decisão aprovada sem explicar o motivo e obter autorização explícita do usuário.
7. Em caso de contradição, ambiguidade ou falta de informação, interromper a mudança e pedir esclarecimento antes de agir.
8. Registrar também o andamento técnico: arquivos afetados, commits, testes executados e resultados observados.
9. Distinguir sempre entre **planejado**, **implementado**, **testado** e **concluído**. Não declarar uma etapa concluída sem evidência correspondente.
10. Investigar logs e evidências antes de propor correções. Evitar alterações especulativas.

## 3. Como manter este registro

- Acrescentar novas decisões na seção **Histórico de atualizações**, sem apagar o histórico válido.
- Quando uma decisão mudar, atualizar a seção de direção atual e marcar a decisão anterior como **SUBSTITUÍDA**, registrando a data e a nova decisão.
- Cada atualização deste documento deve ser commitada na branch de trabalho do projeto.
- Não fazer alterações na branch principal como parte desse procedimento, salvo autorização explícita do usuário.
- Antes de cada etapa de trabalho, conferir este documento junto com os arquivos e commits atuais. Este registro não substitui a verificação do estado real do código.

## 4. Histórico de atualizações

### 2026-11-21 | Registro inicial das regras de continuidade

- **APROVADO:** a VENOM OS não deve ser apenas um tema aplicado ao Arch Linux; deve desenvolver identidade, estrutura, integração e decisões técnicas próprias, mantendo o Arch como base.
- **APROVADO:** manter cada decisão nova registrada no repositório para evitar perda de contexto e repetição de perguntas.
- **APROVADO:** decisões antigas não podem ser tratadas como atuais quando tiverem sido substituídas ou descartadas. A decisão mais recente do usuário prevalece.
- **APROVADO:** antes de modificar decisões ou componentes já aprovados, explicar a razão e pedir autorização.
- **APROVADO:** manter histórico técnico de alterações, commits, testes e resultados, distinguindo planejamento de implementação e validação.
- **APROVADO:** este arquivo, `docs/REGISTRO-DE-DECISOES.md`, é o local oficial no repositório para registrar e atualizar as decisões.


### 2026-11-21 | Kernel principal e kernel de reserva

- **APROVADO:** o kernel estável oficial do Arch Linux, pacote `linux`, é o kernel principal da VENOM OS.
- **APROVADO:** o kernel de suporte prolongado, pacote `linux-lts`, deve permanecer instalado como alternativa de recuperação, não como opção padrão.
- **APROVADO:** nos menus de inicialização Live BIOS e UEFI, a entrada padrão deve usar `linux`; o `linux-lts` deve aparecer como opção identificada de reserva.
- **APROVADO:** o sistema instalado deve receber ambos os kernels, mantendo o kernel estável como primeira opção do GRUB e o LTS como alternativa.
- **JUSTIFICATIVA:** o usuário relatou falhas intermitentes no teclado interno e desligamentos no Dell Inspiron 5458. Isso ainda não comprova defeito no LTS; a mudança estabelece uma opção principal e uma rota de recuperação, permitindo comparação real entre os kernels.
- **IMPLEMENTAÇÃO:** manifesto de instalação, entradas Syslinux/GRUB Live e validador atualizados na branch de trabalho. A geração da ISO e os testes em hardware ainda precisam confirmar os arquivos e o comportamento de boot.


### 2026-11-21 | Comunicação do andamento para o usuário

- **APROVADO:** nas atualizações do projeto, priorizar informações sobre compilação e validação em linguagem simples, sem exigir que o usuário acompanhe ou interprete hashes, identificadores ou detalhes de commits.
- **APROVADO:** informar principalmente o estado da compilação (não iniciada, em andamento, concluída ou falhou), o resultado de cada etapa, erros relevantes, se a ISO foi gerada e se os testes de inicialização/instalação foram realizados.
- **APROVADO:** quando útil, apresentar um resumo organizado dos resultados das compilações e validações, destacando o que passou, o que falhou e o que ainda falta. Não chamar isso de conclusão se houver etapas pendentes.
- **ORIENTAÇÃO:** detalhes de commits podem ser omitidos das atualizações comuns. Só apresentar esses dados se o usuário pedir ou se forem indispensáveis para explicar uma alteração.
- **REGRA:** nunca confundir validação estática, compilação bem-sucedida, ISO gerada e teste real em hardware. São etapas diferentes e devem ser comunicadas separadamente.

## 5. Estado inicial deste registro

Este documento registra as decisões confirmadas nesta conversa em 2026-11-21. Não presume que funcionalidades ou etapas técnicas estejam implementadas apenas por estarem descritas aqui. Para o estado de implementação, verificar a branch, os arquivos, os commits e os resultados dos testes.


### 2026-11-22 | Instalador gráfico simples próprio

- **APROVADO:** por pedido explícito do usuário, substituir o Calamares por um instalador gráfico próprio, simples e suficiente para instalar a VENOM OS. A decisão anterior de usar Calamares está **SUBSTITUÍDA**.
- **APROVADO:** fluxo mínimo: selecionar disco, informar nome completo, usuário e senha, confirmar apagamento, instalar automaticamente e concluir.
- **APROVADO:** instalação limpa no disco escolhido, com aviso/confirmacão explícita; sem particionamento manual ou recursos extras.
- **IMPLEMENTAÇÃO INICIAL:** interface GTK4 e backend Bash adicionados à branch XFCE. Backend usa pacstrap, manifesto e overlay existentes, configura usuário, pt_BR, ABNT2, serviços e GRUB para BIOS/UEFI.
- **SEGURANÇA:** o backend recusa o disco de boot Live, exige disco inteiro com ao menos 20 GB e conexão com a internet. A senha é recebida por arquivo temporário com permissão restrita.
- **PENDENTE:** compilar, testar a interface, testar o backend em discos virtuais descartáveis em BIOS e UEFI e validar uma instalação completa antes de declarar a ISO pronta. Nenhuma nova compilação foi iniciada nesta alteração.
