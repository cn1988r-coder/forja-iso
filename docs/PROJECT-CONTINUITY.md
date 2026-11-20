# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Repositório e branch
- Repositório: cn1988r-coder/forja-iso.
- Branch autorizada: optimize/venom-iso-size.
- HEAD de referência antes desta limpeza: 3f3fb1b447de4cbd04e3a361ac48009d4b53211c.

## Decisões permanentes
- VENOM OS é uma distribuição independente baseada no Arch Linux oficial.
- MATE + LightDM são o único desktop e gerenciador de login.
- Idioma exclusivo: Português do Brasil.
- Teclado padrão: Brasil ABNT2.
- Instalador próprio em C + GTK4, totalmente gráfico e com instalação offline.
- Pacman administra atualizações normais com sudo pacman -Syu.
- VENON é independente do Pacman e só funciona por comandos manuais após confirmação.
- Nenhuma compilação de ISO sem autorização expressa do usuário.

## Política permanente de uso do GitHub e retenção de ISOs
- O GitHub é somente infraestrutura temporária de desenvolvimento, validação e compilação da VENOM OS. Não é depósito, arquivo histórico de imagens, hospedagem permanente ou biblioteca de releases.
- Não manter nenhuma ISO no repositório, em Releases, em tags, em commits, em pastas versionadas ou em qualquer outro armazenamento permanente do projeto.
- Não criar Releases permanentes. A área Releases deve permanecer sem publicações após a limpeza das publicações antigas.
- Uma ISO só pode ser gerada mediante autorização expressa do usuário. Quando autorizada, a compilação e a disponibilização do arquivo serão temporárias e destinadas exclusivamente ao download pelo usuário.
- Após o usuário confirmar que baixou e recebeu a ISO, excluir a publicação temporária e todos os artefatos/arquivos temporários correspondentes que estiverem sob controle do projeto. Não excluir antes da confirmação do usuário.
- Não iniciar outra compilação enquanto a entrega anterior não tiver sido confirmada e os artefatos temporários anteriores tiverem sido removidos.
- Ao terminar cada ciclo, verificar que não restaram Releases, artefatos de workflow ou arquivos ISO armazenados no repositório. O objetivo é não deixar nenhuma ISO publicada ou armazenada no GitHub.
- Se a conexão/ferramenta disponível não permitir excluir uma Release, tag ou artefato, informar a limitação claramente e não afirmar que a limpeza foi feita. A publicação não deve ser considerada concluída até que a exclusão seja verificada.
- As oito Releases antigas identificadas na auditoria de 20/11/2026 são resíduos históricos indevidos e permanecem pendentes de exclusão. Não devem ser tratadas como releases válidas da VENOM OS.

## Limpeza executada nesta revisão
- Removidos os arquivos do instalador legado e suas regras de autorização.
- Removidos os diretórios de branding e configuração do instalador de terceiros.
- Removidos scripts de patch e validadores que dependiam da arquitetura anterior.
- Reescritos Dockerfile e scripts de validação para usar somente a base Arch Linux oficial.
- Reorientada a configuração de mídia para o perfil Archiso mantido pelo projeto.
- Configurados locale pt_BR.UTF-8 e teclado br-abnt2.
- Corrigido o workflow de validação para a branch autorizada.
- Mantido o workflow de ISO intencionalmente bloqueado.

## Estado real após a limpeza
### Feito
- Arquivos de configuração e documentação operacional reescritos.
- Perfil inicial Archiso e manifesto x86_64 adicionados.
- Scripts estáticos reescritos para não gerar ISO.
- Indicadores MATE permanecem listados nos pacotes necessários.

### Pendente
1. Completar a estrutura de boot do perfil Archiso e validar o perfil sem gerar ISO.
2. Implementar o instalador próprio C + GTK4 e seu backend seguro.
3. Corrigir e testar individualmente os indicadores de rede, Bluetooth e volume/áudio numa sessão MATE real.
4. Criar testes unitários e de integração para particionamento, instalação offline, usuário e GRUB.
5. Validar o sistema live e a instalação numa VM descartável, somente depois da implementação.
6. Excluir as oito Releases antigas e as respectivas tags, assim que houver acesso administrativo capaz de executar e verificar essa exclusão.

### Não testado
- Nenhuma ISO foi compilada.
- Nenhuma instalação foi executada.
- Nenhuma sessão gráfica MATE foi iniciada nesta revisão.
- Os indicadores não foram comprovados após login/reinicialização.
- O perfil Archiso ainda não está pronto para compilação.

## Próximo passo
Completar o perfil Archiso e iniciar o esqueleto do instalador C + GTK4 sem disparar qualquer build de ISO. Antes de qualquer entrega futura, garantir que o fluxo temporário de publicação e exclusão esteja disponível e verificável.

## Auditoria de vestígios do repositório em 20/11/2026
- Os PRs históricos #1, #2, #3 e #5 tiveram título e descrição substituídos por um aviso neutro de arquivamento. Os PRs #6, #17, #18 e #20 já haviam recebido o mesmo tratamento em revisão anterior.
- As 51 branches verificadas apontam para o commit limpo 3fde0b616228067c44594c4eb27207cfafef0a36. Permanecem nomes antigos em branches, inclusive seis com referências textuais à arquitetura anterior. A conexão GitHub disponível não oferece operação de exclusão ou renomeação de branch.
- Ainda existem 8 releases antigos com imagens Manjaro MATE e Arch XFCE, e 8 tags correspondentes. A conexão disponível permite leitura, mas não oferece exclusão de releases ou refs de tags.
- O histórico Git antigo continua acessível. A conexão não oferece operação para criar commit órfão/recriar o histórico sem pais, nem apagar referências históricas protegidas pela plataforma.
- A árvore de arquivos atual foi auditada novamente nesta revisão: não há caminhos, pacotes, configurações, scripts ou workflows do instalador legado.
- Portanto, a limpeza da árvore atual e dos metadados editáveis de PR foi realizada, mas a remoção total de branches antigas, releases, tags e histórico depende de permissões/operações administrativas que não estão disponíveis nesta conexão. Não declarar o repositório integralmente livre de vestígios até essa etapa ser concluída.


## Retomada do instalador em 20/11/2026
- HEAD de início desta retomada: 160c4c4eaebae08a326a671c3c530fdf6d9420ce.
- Causa confirmada do atraso: a limpeza anterior removeu os componentes do instalador herdado e deixou somente a especificação. Não havia implementação própria C/GTK4 no repositório.
- Criado `installer/src/main.c`: protótipo inicial da interface GTK4, com detecção informativa de discos via lsblk, escolha visual de disco e modo automático/personalizado.
- Criado `installer/meson.build` e `installer/README.md`.
- O botão de instalação está deliberadamente bloqueado. O protótipo não particiona, formata nem grava em discos.
- Dockerfile atualizado com Meson/Ninja; workflows de validação agora tentam compilar a interface em runner Ubuntu com GTK4; validação estática passou a exigir os arquivos do protótipo.
- README atualizado para não descrever o instalador como inexistente, mas deixar explícito que ainda não é funcional.
- Commits desta etapa: cb4cde8, c58e2ed, 247a937, ec5e0f7, 7f85cf5, 9c78577, 0030feb, 2924b5a (na ordem de criação; cada um na branch autorizada).
- Ainda não há backend privilegiado, particionamento, instalação offline, criação de usuário, configuração de GRUB, progresso real ou logs operacionais. O protótipo não pode ser usado para instalar o sistema.
- A compilação CI foi configurada, mas seu resultado precisa ser consultado antes de afirmar que o código compila.
- Prazo desejado pelo usuário: sistema com instalador utilizável amanhã. Não prometer esse prazo como garantido; priorizar implementação e testes reais em VM descartável. Não habilitar operações destrutivas nem compilar ISO sem autorização expressa.
