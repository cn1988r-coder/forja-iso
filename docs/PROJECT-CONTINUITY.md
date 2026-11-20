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
- Repositório de trabalho: cn1988r-coder/forja-iso.
- Branch autorizada: optimize/venom-iso-size.
- HEAD verificado antes deste registro: 65764d0705792f0a706b42da2a44b8a5c662fa25.
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

## Próximas etapas
1. Completar o perfil Archiso oficial.
2. Implementar o backend seguro do instalador C + GTK4.
3. Reproduzir a referência visual aprovada pelo usuário quando ela estiver disponível no contexto.
4. Implementar particionamento automático e personalizado em discos virtuais descartáveis.
5. Implementar instalação offline, usuário, MATE, LightDM, rede, ABNT2 e GRUB.
6. Criar testes automatizados e validar instalação e falhas em VM descartável.
7. Auditar indicadores de rede, Bluetooth e volume numa sessão MATE real.
8. Solicitar autorização expressa antes de qualquer compilação ISO.

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
