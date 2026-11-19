# Auditoria técnica: framework EndeavourOS

## Fonte upstream

- Framework: https://github.com/endeavouros-team/EndeavourOS-ISO
- Desenvolvimento EndeavourOS: https://endeavouros-team.github.io/EndeavourOS-Development/
- O framework é uma versão significativamente modificada do Archiso.
- A documentação upstream orienta preparar o build em EndeavourOS ou em sistema Arch com os repositórios EndeavourOS habilitados.
- Dependências de build indicadas: `archiso`, `git` e `squashfs-tools`.
- O build upstream é executado por `./prepare.sh` e `sudo ./mkarchiso -v .`.

## Pontos de adaptação confirmados

1. `packages.x86_64` upstream contém o desktop KDE Plasma e seus aplicativos. Não pode ser usado sem uma substituição cuidadosa pela seleção MATE da Forja.
2. `prepare.sh` upstream chama `get_pkg "eos-settings-plasma"` e constrói `endeavouros-skel-liveuser`. Essas etapas são específicas da sessão atual e precisam ser substituídas por uma configuração MATE equivalente.
3. `run_before_squashfs.sh` faz referência ao tema e ao wallpaper do EndeavourOS e configura o esqueleto da sessão live. A adaptação deve remover as referências a wallpaper e configurar o fundo preto, além de garantir que MATE seja a única sessão gráfica.
4. A lista upstream consultada comenta que Calamares não está mais disponível diretamente no repositório e orienta construir o pacote. É obrigatório identificar e integrar o fork/receita oficial EndeavourOS, seus módulos e dependências. Não substituir pelo Calamares genérico sem validação.
5. Shelly tem receita de pacote própria e dependências GTK4, GLib, D-Bus, libarchive, curl, SQLite, dconf, GnuPG e zstd, entre outras. O pacote deve ser construído e instalado no ambiente de build e testado dentro da sessão MATE da ISO. Compatibilidade declarada com Arch não comprova integração no EndeavourOS.

## Próximas etapas técnicas

- Fixar uma revisão upstream do framework para builds reproduzíveis.
- Trazer/adaptar o perfil sem perder os arquivos de boot, firmware, rede, chaves e scripts essenciais do EndeavourOS.
- Substituir o desktop KDE por MATE e validar a sessão live.
- Construir e integrar o fork Calamares do EndeavourOS e testar a abertura, módulos, particionamento e instalação em VM.
- Empacotar Shelly de forma reproduzível e testar instalação, atualização e remoção.
- Aplicar Materia Dark, Papirus, Bibata e fundo #000000 ao usuário live e ao usuário instalado.
- Executar validação de pacotes e scripts, depois compilar em host EndeavourOS/Arch com repositórios EndeavourOS.
- Testar a ISO em VM com boot UEFI/BIOS, rede, sessão MATE e instalação completa antes de publicar.

## Limite desta auditoria

Esta auditoria é documental e baseada nos arquivos upstream consultados. Não foi executada em um host Arch/EndeavourOS, não resolve dependências de pacotes e não representa teste de boot ou instalação.
