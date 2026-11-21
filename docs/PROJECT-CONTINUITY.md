# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026, após a conclusão da execução #44.

## Identidade e arquitetura definitiva
- Sistema: VENOM OS.
- Base: Arch Linux oficial, com repositórios oficiais. Não usar Manjaro, EndeavourOS ou outra distribuição como base operacional.
- Edições planejadas: VENOM MATE, VENOM XFCE e VENOM Window Maker. Não criar edições extras nem misturar os ambientes.
- MATE: desktop principal; LightDM; idioma pt_BR.UTF-8; teclado br-abnt2.
- Instalador aprovado: Calamares upstream 3.3.14, branding VENOM e módulo customizado `venominstall`.
- Instalação exclusivamente online, usando pacotes oficiais Arch via Pacman/pacstrap. Sem internet, a instalação deve falhar claramente.
- Calamares deve executar particionamento/montagem, instalação no destino, fstab, locale, serviços, initramfs e bootloader. Não copiar a raiz live para o disco.
- Não substituir Calamares por instalador C/GTK4 sem autorização explícita.

## Gerenciamento de pacotes
- Pacman é o único responsável pelo gerenciamento normal e atualizações do sistema/aplicativos: `sudo pacman -Syu`.
- VENON é independente do Pacman e acionado manualmente por `sudo venom`.
- `venon-upgrade` apenas consulta/lista atualizações disponíveis.
- `venon-update` instala atualizações do repositório VENON somente após confirmação explícita.
- Não criar timers nem atualizações automáticas.

## Repositório e branches
Repositório oficial: `cn1988r-coder/forja-iso`.
- Preservar `main` e o histórico das branches.
- Branch Arch/MATE principal: `optimize/venom-iso-size`.
- Branch destinada ao XFCE: `feature/venom-community-xfce`.
- Branch destinada ao Window Maker: `feature/forja-window-maker-endeavouros`.
- Auditar `feature/venom-bigcommunity-mate` antes de qualquer alteração.
- Antes de editar uma branch, verificar se há workflow ativo nela.
- Não apagar branches, ISOs ou documentos sem autorização inequívoca.
- Não publicar ISO/release nem iniciar novo build sem autorização expressa.

## Estado da compilação #44, Arch/MATE
- Workflow: `.github/workflows/build-arch-iso.yml`.
- Branch: `optimize/venom-iso-size`.
- Run ID: `44852869086`.
- Commit de disparo: `1b5236f80d4b3747c1996fd518581a765431a314`.
- Resultado verificado: falha no passo 8, “Build VENOM OS ISO with official Archiso”.
- Passaram a compilação do Calamares 3.3.14, staging da configuração e validação do perfil Arch.
- Durante a geração do initramfs, mkinitcpio registrou componentes ausentes para hooks PXE: `/usr/lib/initcpio/ipconfig`, `nbd-client` e `/usr/lib/initcpio/nfsmount`. Também registrou erro na geração do initramfs.
- A falha fatal que encerrou o job ocorreu durante a criação do SquashFS: `FATAL ERROR: xz uncompress failed with error code 9`, com o processo em aproximadamente 78%.
- Verificação de payload Calamares, testes de boot BIOS/UEFI e upload foram ignorados porque a criação da ISO falhou.
- A consulta de artefatos retornou lista vazia. Não há ISO #44 nem SHA256 de saída para preservar.
- Link da execução: https://github.com/cn1988r-coder/forja-iso/actions/runs/44852869086
- Não declarar ISO funcional ou pronta. Mesmo uma futura aprovação dos smoke tests BIOS/UEFI não substitui teste completo de instalação em VM, incluindo particionamento, instalação, reboot, login, serviços e bootloader.

## Próximas correções na branch Arch/MATE
1. Investigar e corrigir os hooks PXE/mkinitcpio para que a geração do initramfs termine sem erros. Verificar se os hooks PXE são necessários; se forem removidos, ajustar a configuração de forma coerente, sem mascarar falhas.
2. Investigar a falha XZ/SquashFS no runner e corrigir a causa real antes de novo build.
3. Corrigir `scripts/build-venom-iso.sh`, que ainda contém chamadas antigas a `buildiso` e caminhos de perfil Manjaro. Antes, procurar todas as referências e definir o fluxo correto com Archiso.
4. Corrigir `AGENTS.md`, `README.md` e documentação para refletir a arquitetura definitiva: três edições, Arch oficial, Calamares 3.3.14 e instalação online.
5. Auditar resíduos operacionais Manjaro/EndeavourOS/BigLinux em workflows, scripts, manifests, mirrors e configurações. Preservar referências históricas úteis em documentação.

## Migração XFCE
A branch `feature/venom-community-xfce` está inconsistente apesar do nome:
- Contém workflow baseado em `manjaro/manjaro-iso-action`, perfil MATE Manjaro e perfil XFCE Manjaro.
- O build #76 terminou com falha por pacote `adwaita-gtk-theme` não encontrado.
- O perfil XFCE antigo contém `mhwd`, autologin e credenciais padrão hardcoded; remover essas práticas inseguras.
- Reconstruir a edição como perfil Archiso real, com XFCE de fato, usando a arquitetura Calamares online aprovada. Não apenas renomear o perfil MATE.

## Migração Window Maker
A branch `feature/forja-window-maker-endeavouros` contém workflow de build bloqueado intencionalmente e manifest previamente observado com pacotes MATE, não Window Maker.
- Migrar para Archiso oficial e desktop Window Maker real.
- Não introduzir LXQt, XFCE ou MATE como desktop subjacente.
- Manter Calamares online.
- Preservar branch e histórico.

## Restrições de execução e validação
- Não alterar uma branch enquanto houver workflow ativo nela.
- Não interromper builds ativos.
- A autorização geral do usuário permite implementar a migração Arch e correções necessárias sem pedir aprovações repetidas.
- Essa autorização não substitui a autorização expressa exigida para iniciar novo build ISO ou publicar release.
- Registrar resultados reais, hashes de commits e evidências de teste. Não afirmar conclusão sem validação.
- Não prometer execução em segundo plano: o trabalho com ferramentas ocorre durante uma sessão ativa.

## Referência histórica
A ISO VENOM OS Manjaro MATE #21, já testada pelo usuário, permanece apenas como referência histórica de aparência/configuração. O script `manjaro-mate-dark-complete.sh` é referência de configuração MATE, não base de sistema operacional.
