# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026, após as correções estáticas da compilação #44.

## Identidade e arquitetura definitiva
- Sistema: VENOM OS.
- Base: Arch Linux oficial e repositórios oficiais. Não usar Manjaro, EndeavourOS ou outra distribuição como base operacional.
- Edições planejadas: VENOM MATE, VENOM XFCE e VENOM Window Maker. Não criar edições extras nem misturar ambientes.
- MATE: desktop principal; LightDM; pt_BR.UTF-8; teclado br-abnt2.
- Instalador: Calamares upstream 3.3.14, branding VENOM e módulo customizado `venominstall`.
- Instalação exclusivamente online via pacstrap/Pacman. Sem internet, falhar claramente.
- Calamares deve particionar/montar, instalar no destino, configurar fstab, locale, serviços, initramfs e bootloader. Não copiar a raiz live.
- Não substituir Calamares por instalador C/GTK4 sem autorização explícita.

## Gerenciamento
- Pacman: `sudo pacman -Syu`.
- VENON independente e manual: `sudo venom`.
- `venon-upgrade` consulta/lista atualizações; `venon-update` instala somente após confirmação.
- Sem timers ou atualizações automáticas.

## Repositório e branches
Repositório oficial: `cn1988r-coder/forja-iso`.
- Preservar `main` e histórico.
- Arch/MATE: `optimize/venom-iso-size`.
- XFCE: `feature/venom-community-xfce`.
- Window Maker: `feature/forja-window-maker-endeavouros`.
- Auditar `feature/venom-bigcommunity-mate` antes de alterações.
- Verificar workflows ativos antes de editar branches.
- Não apagar branches/ISOs/documentos sem autorização inequívoca.
- Não publicar ISO/release nem iniciar novo build sem autorização expressa.

## Compilação #44, Arch/MATE
- Workflow `.github/workflows/build-arch-iso.yml`, run ID `44852869086`.
- Branch `optimize/venom-iso-size`; commit de disparo `1b5236f80d4b3747c1996fd518581a765431a314`.
- Compilação Calamares 3.3.14, staging e validação do perfil passaram.
- mkinitcpio falhou por ausência de `ipconfig`, `nfsmount` e `nbd-client` exigidos pelos hooks PXE.
- SquashFS falhou durante compactação XZ com `xz uncompress failed with error code 9`, em cerca de 78%.
- Sem ISO/artefatos; testes BIOS/UEFI e upload foram ignorados.
- Link: https://github.com/cn1988r-coder/forja-iso/actions/runs/44852869086

## Correções já aplicadas após #44
- `build/packages.x86_64`: incluídos `mkinitcpio-nfs-utils` e `nbd`, dependências oficiais Arch para os hooks PXE NFS/NBD.
- `build/airootfs/etc/mkinitcpio.conf.d/archiso.conf`: mantidos hooks PXE oficiais, agora com compressão zstd no initramfs.
- `build/profiledef.sh`: SquashFS passou de XZ para Zstandard nível 15, para reduzir pressão de memória do runner.
- `scripts/validate-arch-profile.sh`: valida dependências PXE e compressão zstd.
- `scripts/build-venom-iso.sh`: removidas chamadas Manjaro/buildiso; agora usa Archiso.
- `README.md` e `AGENTS.md`: atualizados para Arch e três edições, Calamares online, Pacman/VENON separados.
- Commits dessas alterações na branch: `c016c8a`, `9373483`, `916b032`, `25a9df0`, `4b5fb18`, seguidos pelas atualizações de manifest e validator.

## Validação pendente na edição MATE
- Executar validação estática em ambiente Arch com repositórios atualizados e confirmar os nomes dos pacotes.
- Novo build ainda não foi iniciado. Aguardar autorização expressa.
- Após build, verificar ISO, SHA256, smoke tests BIOS/UEFI e depois instalação completa em VM descartável. Não declarar pronta antes disso.

## XFCE
Branch `feature/venom-community-xfce` está inconsistente:
- Workflow anterior usava `manjaro/manjaro-iso-action`, apesar de existir profile MATE Manjaro e profile XFCE Manjaro.
- Run #76 (ID `44843598356`) falhou por pacote `adwaita-gtk-theme` não encontrado.
- Perfil XFCE antigo contém `mhwd`, autologin e credenciais padrão. Remover práticas inseguras.
- Reconstruir como perfil Archiso XFCE real, Calamares online. Não apenas renomear profile MATE.

## Window Maker
Branch `feature/forja-window-maker-endeavouros` tem workflow intencionalmente bloqueado e manifest previamente visto com pacotes MATE.
- Migrar para Archiso oficial e Window Maker real, sem MATE/XFCE/LXQt como desktop subjacente.
- Manter Calamares online e preservar branch/histórico.

## Restrições
- Não editar branch com workflow ativo nem interromper builds.
- Autorização para migração Arch permite correções necessárias, mas não inicia build ISO nem publica release sem autorização expressa.
- Registrar evidências, testes e hashes reais. Não afirmar conclusão sem validação.
- Trabalho com ferramentas ocorre durante sessão ativa, sem execução em segundo plano.

## Referência histórica
A ISO VENOM OS Manjaro MATE #21 permanece apenas referência histórica. `manjaro-mate-dark-complete.sh` é referência de configuração MATE, não base operacional.
