# Continuidade técnica: VENOM OS XFCE

Atualizado em 20/11/2026.

## Arquitetura
- Branch: `feature/venom-community-xfce`.
- HEAD atual: `4eba81ed8bd433b6b6db182f64c5420c4c17a2c3`.
- Base: Arch Linux oficial e repositórios oficiais.
- Desktop: XFCE real + LightDM; sem MATE.
- Idioma pt_BR.UTF-8; teclado br-abnt2.
- Perfil de mídia Archiso oficial.
- Instalador Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`.
- Instalação online via pacstrap/Pacman. Sem unpackfs, rsync ou cópia da raiz live.
- Atualizações normais pelo Pacman; VENON separado e manual.

## Migração executada
- Reconstruída a estrutura operacional sobre Archiso e os arquivos Calamares aprovados na branch Arch/MATE.
- Manifest específico com grupos `xfce4` e `xfce4-goodies`, Thunar, LightDM, rede, Bluetooth, áudio e dependências Calamares.
- Sem pacotes MATE, Pamac, MHWD ou Manjaro no manifest ativo.
- LightDM configurado para a sessão `xfce` e usuário live `venom`.
- Configurações XFCE/GTK migradas para `build/airootfs/etc/skel`.
- Tema XFWM4 e wallpaper VENOM incluídos no perfil.
- Removidos workflows Manjaro, diretórios de perfil Manjaro e credenciais padrão antigas.
- Workflow Archiso restrito a esta branch e validação específica `scripts/validate-xfce-profile.sh`.
- Script de build chama o validador XFCE, não o validador MATE.

## Estado anterior
- Run #76, ID `44843598356`, falhou por pacote `adwaita-gtk-theme` não encontrado.
- Perfil antigo continha `mhwd`, autologin e senha padrão `venom`.
- Nenhuma ISO desse estado é considerada instalável.

## Validação pendente
- Executar `scripts/validate-xfce-profile.sh` em container Arch com pacman e repositórios atualizados.
- Não iniciar build ISO sem autorização expressa.
- Após build autorizado, validar boot BIOS/UEFI e instalação completa em VM descartável, incluindo primeiro login XFCE.
