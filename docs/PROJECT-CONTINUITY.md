# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Arquitetura definitiva

- Sistema: VENOM OS.
- Base: Arch Linux oficial.
- Repositórios: somente os oficiais do Arch Linux.
- Desktop: MATE.
- Gerenciador de login: LightDM.
- Idioma: Português do Brasil.
- Teclado: Brasil ABNT2.
- Mídia: perfil próprio baseado no Archiso oficial.
- Instalador: próprio, C + GTK4, backend separado.
- Instalação offline a partir da própria mídia.
- Calamares, EndeavourOS e Manjaro não fazem parte da arquitetura final.

## Branch e HEAD

- Repositório: cn1988r-coder/forja-iso.
- Branch de trabalho: optimize/venom-iso-size.
- HEAD auditado antes deste registro: 4792c81da635a7a83ace7d02514d0d14bdfe9f2c.
- main e as demais branches não foram modificadas nesta etapa.

## Implementações realizadas

### Perfil Archiso

- Perfil x86_64 com BIOS via Syslinux e UEFI via GRUB.
- Manifest de pacotes MATE/LightDM, GTK4, ferramentas de instalação, rede, Bluetooth e áudio.
- Initramfs configurado com hooks oficiais do Archiso.
- Locale pt_BR.UTF-8 e teclado br-abnt2.
- Configuração de boot com parâmetro de inicialização da sessão live.
- Script de inicialização cria usuário temporário venom, prepara MATE/LightDM e ativa NetworkManager e Bluetooth.
- Launcher gráfico do instalador adicionado ao menu.

### Instalador

- Frontend C + GTK4 compilável via Meson.
- Backend separado em Bash, chamado pelo sudo não interativo com regra restrita ao instalador e Pacman na sessão live.
- Detecção visual de discos inteiros.
- Formulário para usuário, hostname e senha.
- Confirmação explícita de apagamento.
- Particionamento automático GPT para BIOS (partição BIOS Boot + raiz) e UEFI (ESP + raiz).
- Formatação ext4/FAT32 e cópia offline da árvore live via rsync.
- Configuração de fstab, usuário, senha, hostname, locale, ABNT2, LightDM, NetworkManager, Bluetooth, GRUB e initramfs.
- Log de execução em /var/log/venom-installer/.

### Validação e compilação automatizadas

- scripts/validate-arch-profile.sh valida estrutura, bootmodes, locale, teclado, hooks, repositórios oficiais e disponibilidade dos pacotes quando executado em Arch.
- Workflow .github/workflows/build-arch-iso.yml executa ShellCheck, compila o instalador, integra os binários ao overlay, gera a ISO com mkarchiso, testa boot BIOS/UEFI em QEMU e publica ISO + SHA-256 como artefato.
- O workflow é acionado por push na branch autorizada e também oferece workflow_dispatch.
- Foi configurada concorrência para manter somente a execução mais recente da branch.

## Verificações executadas nesta sessão

- Inspeção dos arquivos e do HEAD diretamente no GitHub.
- bash -n passou localmente para o backend do instalador e profiledef.sh.
- bash -n passou localmente para o script validador após corrigir o tratamento de linhas comentadas.
- O ambiente local desta sessão não possui GTK4/meson, ShellCheck, mkarchiso ou QEMU; portanto, não foi possível compilar ou gerar a ISO localmente.
- A execução do GitHub Actions precisa ser consultada para confirmar o resultado real do build e dos smoke tests. Não registrar sucesso sem artefato e logs.

## Pendências reais

1. Confirmar a execução do workflow: validação de pacotes, ShellCheck, compilação C/GTK4, mkarchiso, testes QEMU BIOS/UEFI e artefato SHA-256.
2. Implementar particionamento personalizado; atualmente a interface oferece somente instalação automática.
3. Testar a instalação em discos virtuais descartáveis nos dois modos de firmware.
4. Validar o primeiro boot do sistema instalado, não apenas o boot da mídia live.
5. Inspecionar visualmente MATE, painel e indicadores de rede/Bluetooth/volume, áudio e persistência após reinicialização.
6. Simular falhas do backend e validar recuperação e logs.

## Atualizações

- Pacman administra atualizações normais: sudo pacman -Syu.
- VENON é separado do Pacman e acionado manualmente.
- venon-upgrade apenas consulta/lista atualizações disponíveis.
- venon-update instala atualizações VENON somente após confirmação explícita.
- Não criar timers nem atualizações automáticas do VENON.

## Referência histórica

A ISO VENOM OS Manjaro MATE #21 e o script manjaro-mate-dark-complete.sh permanecem como referência histórica de desktop, sem alteração e sem serem usados como base de build da edição Arch.
