# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Identidade e arquitetura
- Sistema: VENOM OS.
- Base exclusiva: Arch Linux oficial, com pacotes dos repositórios oficiais.
- Desktop único: MATE.
- Gerenciador de login: LightDM.
- Idioma: Português do Brasil (pt_BR.UTF-8).
- Teclado: Brasil ABNT2.
- Identidade visual: tema escuro próprio da VENOM OS.
- Nenhum instalador, serviço, repositório, configuração ou componente de outra distribuição integra o sistema.

## Repositório e fluxo de trabalho
- Repositório de trabalho: cn1988r-coder/forja-iso. O nome é mantido por ser o repositório disponível para o desenvolvimento; não é o nome do sistema.
- Branch autorizada: optimize/venom-iso-size.
- HEAD de código antes do registro desta correção: bab3513567d1addd4959ddd89dc4d7e541392219.
- Não alterar main ou outras branches sem autorização expressa.
- Não gerar ISO sem autorização expressa do usuário.
- Registrar somente resultados efetivamente verificados.

## Instalador próprio
- Tecnologia: C + GTK4, com backend separado.
- Interface totalmente gráfica e em Português do Brasil.
- Instalação offline usando os arquivos da própria mídia.
- Seleção de disco, instalação automática e personalizada.
- Confirmação explícita antes de operações destrutivas.
- Criação de usuário, configuração do MATE, LightDM, locale, ABNT2, rede e GRUB.
- Progresso real, logs persistentes e tratamento seguro de falhas.
- Não usar instalador de terceiros.
- Não habilitar escrita em discos reais antes dos testes em imagens descartáveis e VM.

## Atualizações
- Pacman administra o sistema e os aplicativos: sudo pacman -Syu.
- VENON é independente do Pacman e acionado manualmente.
- venon-upgrade apenas consulta e lista atualizações; nunca instala.
- venon-update instala somente após confirmação explícita.
- Backend, servidor e protocolo assinado do VENON ainda não estão implementados.

## Estado técnico atual
- A árvore atual contém um perfil Archiso inicial, ainda incompleto.
- Os manifests listam pacotes do Arch Linux e componentes MATE.
- O ambiente de validação é construído a partir de archlinux:latest.
- A validação compila a interface C + GTK4, executa ShellCheck e valida a configuração.
- A interface existente é somente um protótipo; não é um instalador funcional.
- O botão de instalação permanece sem operações de escrita.
- Não há backend de particionamento, formatação, cópia offline, criação de usuário ou instalação do GRUB.
- O workflow de compilação ISO permanece bloqueado.
- A auditoria da árvore atual não encontrou caminhos com nomes de componentes de instaladores externos.
- Commits anteriores permanecem no histórico Git, mas seus arquivos removidos não integram a árvore atual.
- As execuções de validação associadas ao commit 6830acf815d17dcd70ca955d7d8de7298fd5aeef falharam durante a compilação C: foi usada a função inexistente gtk_string_list_get_n_items().
- Correção aplicada em installer/src/main.c no commit 62382f80531b97e6bf4f163d5ab3662f1b333f13: a contagem agora usa g_list_model_get_n_items(G_LIST_MODEL(items)).
- A correção foi confirmada no diff do commit. A validação automatizada do novo commit ainda não foi confirmada; não declarar compilação bem-sucedida até obter resultado do CI.

## Próximas etapas
1. Confirmar que a compilação GTK4 passa no CI após a correção.
2. Completar o perfil Archiso oficial.
3. Implementar o backend seguro do instalador C + GTK4.
4. Reproduzir a referência visual aprovada pelo usuário quando ela estiver disponível no contexto.
5. Implementar particionamento automático e personalizado em discos virtuais descartáveis.
6. Implementar instalação offline, usuário, MATE, LightDM, rede, ABNT2 e GRUB.
7. Criar testes automatizados e validar instalação e falhas em VM descartável.
8. Auditar indicadores de rede, Bluetooth e volume numa sessão MATE real.
9. Solicitar autorização expressa antes de qualquer compilação ISO.

## Retenção de artefatos
- O GitHub é infraestrutura de desenvolvimento e entrega temporária.
- Não manter ISOs em commits, pastas versionadas, Releases ou armazenamento permanente.
- Após autorização de build, disponibilizar a ISO temporariamente.
- Só remover o artefato temporário depois de o usuário confirmar o download.
- Se a ferramenta não permitir excluir uma publicação ou artefato, informar a limitação sem declarar a exclusão.

## Testes e limitações
- Validações estáticas não comprovam boot, instalação, sessão MATE ou funcionamento dos indicadores.
- Nenhuma ISO deve ser declarada pronta sem build autorizada e testes reais.
- O histórico Git e referências administrativas do GitHub exigem auditoria separada da árvore de arquivos atual.

## Autorização de continuidade registrada em 20/11/2026
- O usuário autorizou prosseguir com o desenvolvimento da VENOM OS sem solicitar confirmação para cada correção técnica rotineira.
- Escopo autorizado: investigar falhas, corrigir código e scripts, ajustar CI, implementar o instalador próprio em C + GTK4, desenvolver o backend, criar testes automatizados e repetir ciclos de validação/correção.
- Ao encontrar erros, investigar a causa, corrigir e validar novamente; registrar resultados reais, inclusive falhas persistentes e bloqueios.
- Preservar a arquitetura Arch Linux oficial + MATE + LightDM e todas as restrições arquiteturais já registradas.
- Não usar Calamares, EndeavourOS ou componentes de outras distribuições.
- A autorização para desenvolver o instalador não autoriza operações destrutivas em discos reais. Validar operações de particionamento/formatação primeiro com imagens descartáveis e máquinas virtuais.
- A autorização não inclui compilar ou publicar ISO. Build e publicação de ISO continuam exigindo autorização específica do usuário.
- Limitação operacional: não existe execução contínua garantida depois que a conversa é fechada. O assistente só pode trabalhar quando uma sessão/tarefa efetivamente estiver em execução; não prometer trabalho noturno em segundo plano nem conclusão automática para o dia seguinte.
- Não declarar a VENOM OS ou o instalador prontos sem evidência de compilação, testes e validação em VM.


## Correção do painel MATE em 20/11/2026
- Escopo: somente a configuração do painel e a área de notificação; nenhuma alteração no instalador, base, serviços de boot ou workflow de ISO.
- Commit de implementação: e50768c566c767b7e2933f5466eb379ed0e5a7fd criou build/airootfs/usr/share/mate-panel/layouts/venom.layout.
- Commit de implementação: bab3513567d1addd4959ddd89dc4d7e541392219 alterou build/airootfs/etc/dconf/db/local.d/00-venom para selecionar default-layout='venom'.
- O layout explícito mantém a barra superior e inferior do MATE e inclui o applet NotificationAreaAppletFactory::NotificationArea na barra superior, onde os indicadores de NetworkManager, Bluetooth e volume podem aparecer; mantém relógio, lista de janelas e alternador de áreas de trabalho.
- Pacotes de NetworkManager, Blueman, BlueZ, PipeWire, WirePlumber e mate-media já constavam nos manifests; não foram duplicados nem substituídos.
- Verificação realizada: branch optimize/venom-iso-size aponta para bab3513567d1addd4959ddd89dc4d7e541392219; os dois arquivos foram relidos do GitHub e os conteúdos confirmados.
- Não executado: build de ISO, inicialização em VM, sessão gráfica MATE ou teste físico dos indicadores. Portanto, a presença visual e o funcionamento real dos três ícones ainda precisam de validação gráfica.

## Auditoria de continuidade em 20/11/2026
- Repositório verificado: cn1988r-coder/forja-iso.
- Branch de trabalho autorizada: optimize/venom-iso-size. A branch main não foi alterada.
- HEAD verificado durante a auditoria: 3d7bd7cedf8f7a8173fd980acaaebe3ab2ebbcb4.
- A execução GitHub Actions #40 (run 44673298576), na branch antiga fix/forja-calamares-stability e commit 176355ffb49dcc59f5030842479222db93223049, terminou com failure. O job build-iso falhou na etapa mkarchiso porque o executável /usr/bin/calamares não existia. As etapas de hash e publicação foram ignoradas; a API confirmou zero artefatos. Nenhuma ISO ou hash foi produzido.
- A execução #40 é histórica e não está ativa; não reiniciar nem repetir essa compilação sem autorização expressa.
- As validações mais recentes na branch optimize/venom-iso-size também falharam. No run 44784518633, o validador compilou o protótipo C + GTK4, mas falhou no teste de documentação porque o README não contém literalmente a expressão esperada "C + GTK4". Isso é falha de validação documental, não prova de falha na compilação C.
- Os commits e50768c566c767b7e2933f5466eb379ed0e5a7fd e bab3513567d1addd4959ddd89dc4d7e541392219 adicionaram o layout venom e selecionaram default-layout='venom'. A existência do NotificationAreaApplet no arquivo não comprova que os indicadores aparecem ou funcionam numa sessão gráfica. Nenhum teste MATE em VM foi realizado.
- Direção solicitada mais recentemente pelo usuário nesta conversa: preparar o ambiente MATE tendo Manjaro como destino e usar como referência principal o segundo script de instalação MATE fornecido pelo usuário (script da Cláudia), preservando o layout completo, Brisk Menu, separadores e indicadores. Essa migração ainda NÃO está implementada na árvore do repositório; a árvore atual continua sendo Archiso/Arch Linux oficial.
- Não transportar cegamente o script para uma ISO: ele foi escrito para instalar MATE num Manjaro já instalado, executa pacman -Syu, tenta compilar Brisk via AUR e cria temporariamente sudoers NOPASSWD:ALL. Esses comportamentos precisam ser separados do perfil de ISO e revisados com segurança, preservando a configuração visual pretendida.
- A documentação oficial do Manjaro descreve o uso de manjaro-tools/buildiso e perfis iso-profiles, em vez de mkarchiso. A migração do pipeline e do perfil ainda está pendente.
- Nenhuma alteração de código, nenhum commit de implementação, nenhuma compilação ISO e nenhuma alteração em main foram feitas durante esta auditoria.

## Configuração MATE preparada para validação do usuário em 20/11/2026
- Branch: optimize/venom-iso-size.
- HEAD verificado antes deste registro: 942dbbac8c8ebeab62fc8b2cc79b36b19d8f0bc2.
- A configuração de primeiro login do MATE foi integrada em build/airootfs/usr/local/bin/venom-mate-first-login, com autostart em build/airootfs/etc/skel/.config/autostart/venom-mate-first-login.desktop.
- A configuração aplica Materia Dark, Papirus-Dark, cursor Bibata Modern Classic, Brisk Menu e wallpaper da Lua baseado no script fornecido pelo usuário.
- O layout permanece próprio da VENOM OS. A área de notificação existente foi preservada; não recriar nem duplicar os indicadores de rede, Bluetooth e volume, que o usuário confirmou já estarem habilitados.
- O primeiro login instala os componentes AUR necessários quando há conexão e permissões sudo. O script não executa atualização geral do sistema com pacman -Syu.
- O Dockerfile inclui verificações estáticas do script, mas isso não substitui teste numa sessão gráfica MATE.
- Situação solicitada pelo usuário: AGUARDANDO VALIDAÇÃO VISUAL DO USUÁRIO.
- Próximo passo: o usuário examina a configuração e informa se aprova ou pede ajustes. Somente depois da aprovação explícita, prosseguir com a compilação da ISO. Nenhuma ISO foi compilada por este registro.
