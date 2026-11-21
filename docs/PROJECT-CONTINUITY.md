# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Arquitetura definitiva
- Sistema: VENOM OS.
- Base: Arch Linux oficial e repositórios oficiais.
- Edições: VENOM MATE, VENOM XFCE e VENOM Window Maker.
- MATE é a edição principal, com LightDM, pt_BR.UTF-8 e teclado br-abnt2.
- Instalador aprovado: Calamares upstream 3.3.14, branding VENOM e módulo `venominstall`.
- Instalação exclusivamente online via pacstrap/Pacman. Sem instalação offline, unpackfs, rsync ou cópia da raiz live.
- Pacman atualiza o sistema: `sudo pacman -Syu`.
- VENON é independente e manual: `venon-upgrade` consulta; `venon-update` instala somente após confirmação.
- Sem timers nem atualização automática.

## Repositório e branch
- Repositório: `cn1988r-coder/forja-iso`.
- Branch Arch/MATE: `optimize/venom-iso-size`.
- HEAD atual: `4cc0e1fdfd9871081076e3cdae0be678a00c7acd`.
- Preservar `main`, branches e histórico.
- Não publicar ISO/release nem iniciar build sem autorização expressa.

## Execução #44
- Workflow `.github/workflows/build-arch-iso.yml`.
- Run ID `44852869086`, commit de disparo `1b5236f80d4b3747c1996fd518581a765431a314`.
- Compilação Calamares 3.3.14, staging e validação do perfil passaram.
- mkinitcpio falhou por falta de `ipconfig`, `nfsmount` e `nbd-client` exigidos pelos hooks PXE.
- SquashFS falhou durante XZ com `xz uncompress failed with error code 9`, por volta de 78%.
- Sem ISO ou artefatos. Smoke tests BIOS/UEFI e upload foram ignorados.
- Link: https://github.com/cn1988r-coder/forja-iso/actions/runs/44852869086

## Correções após #44
- Manifest `build/packages.x86_64`: adicionados `mkinitcpio-nfs-utils` e `nbd`.
- `archiso.conf`: hooks PXE mantidos com dependências correspondentes; compressão do initramfs alterada para zstd.
- `profiledef.sh`: SquashFS alterado de XZ para zstd nível 15 para reduzir pressão de memória.
- `scripts/validate-arch-profile.sh`: valida hooks/dependências PXE, zstd, locale, teclado, pacotes e repositórios oficiais.
- `scripts/build-venom-iso.sh`: usa Archiso oficial, não Manjaro buildiso.
- `README.md` e `AGENTS.md`: documentam três edições, Arch oficial, Calamares online e separação Pacman/VENON.
- Commits de correção principais: `c016c8a`, `9373483`, `916b032`, `25a9df0`, `4b5fb18`, `653efe1`, `dedcc07`, `4cc0e1f`.

## Estado de validação
- Os arquivos foram revisados e os manifestos não apresentam duplicatas na inspeção estática remota.
- O validador ainda precisa ser executado em container Arch com pacman e repositórios atualizados.
- Nenhum novo build foi iniciado nesta etapa.
- Depois de build autorizado: confirmar ISO/SHA256, boot BIOS/UEFI e instalação completa em VM descartável, incluindo reboot e primeiro login.
- Não declarar a ISO pronta antes de todos os testes.

## Referência histórica
A ISO VENOM OS Manjaro MATE #21 e o script `manjaro-mate-dark-complete.sh` permanecem somente como referências históricas de configuração MATE. Não são base operacional.
