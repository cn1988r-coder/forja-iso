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

## Branch e alterações desta etapa

Branch autorizada: optimize/venom-iso-size.

Implementações registradas nesta etapa:
- perfil Archiso x86_64 com boot BIOS/Syslinux e UEFI/GRUB;
- manifest unificado de pacotes oficiais Arch;
- initramfs Archiso e configuração da sessão live;
- criação da sessão temporária MATE com LightDM, rede e Bluetooth;
- frontend C/GTK4 e backend separado para instalação automática offline;
- validação estática do perfil e workflow de compilação/testes QEMU.

## Estado do instalador

Implementado no código:
- detecção visual de discos;
- formulário de usuário, hostname e senha;
- confirmação explícita de apagamento;
- backend privilegiado chamado por pkexec;
- particionamento automático GPT para BIOS/UEFI;
- cópia offline do sistema live para o destino;
- configuração de locale, teclado, usuário, serviços, GRUB e initramfs;
- logs em /var/log/venom-installer/.

Pendente:
- particionamento personalizado;
- testes em discos virtuais descartáveis;
- validar primeiro boot instalado em BIOS e UEFI;
- testar falhas e recuperação;
- inspecionar MATE, indicadores, áudio, rede e Bluetooth após reinicialização.

## Build e validação

Workflow: .github/workflows/build-arch-iso.yml.

O workflow foi criado para validar pacotes/estrutura, executar ShellCheck, compilar o instalador com Meson, gerar ISO via mkarchiso e realizar smoke tests BIOS/UEFI com QEMU. A execução precisa terminar com sucesso e publicar o artefato para que a ISO possa ser considerada compilada. Não registrar sucesso antes de consultar o resultado real.

## Estado confirmado nesta atualização

- Código de perfil, inicialização live, frontend e backend foram adicionados/alterados na branch autorizada.
- A ISO ainda não foi confirmada como compilada ou testada com sucesso.
- O instalador ainda não foi validado em VM.
- A sessão MATE ainda não foi validada visualmente em VM.
- A ISO Manjaro MATE #21 permanece como referência histórica, sem alteração.
- main e outras branches não foram modificadas.

## Atualizações

- Pacman administra o sistema e aplicativos: sudo pacman -Syu.
- VENON é independente do Pacman e acionado manualmente.
- venon-upgrade apenas consulta e lista atualizações disponíveis.
- venon-update instala atualizações VENON somente após confirmação explícita.
- Não criar atualizações automáticas ou timers para o VENON.
