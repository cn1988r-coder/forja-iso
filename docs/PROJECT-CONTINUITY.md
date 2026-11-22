# Continuidade VENOM OS

## Migração Manjaro MATE
- Escopo: somente VENOM OS MATE baseada no Manjaro.
- Branch autorizada: optimize/venom-iso-size.
- Perfil: manjaro/venom-mate.
- Construção: perfis oficiais Manjaro ISO Profiles e buildiso compatível com mt-0.15.
- Calamares: exclusivamente pacote dos repositórios oficiais Manjaro; nunca upstream ou fonte externa.
- Stack de áudio: manjaro-pipewire e manjaro-alsa.
- O perfil Archiso antigo em build/ é legado e não deve gerar a ISO Manjaro.

## Estado desta etapa
- Criado perfil inicial Manjaro MATE com LightDM, GRUB UEFI, NetworkManager e Bluetooth.
- Criada lista inicial de pacotes MATE/Manjaro.
- Adicionada configuração dconf escura e layout inicial do painel inferior.
- Nenhuma ISO foi gerada.

## Pendências obrigatórias
1. Preparar o perfil dentro da árvore oficial Manjaro.
2. Resolver pacotes com buildiso -p venom-mate -x, sem gerar ISO.
3. Confirmar Calamares oficial instalado e inspecionar a configuração gerada.
4. Corrigir pacotes ausentes/incompatíveis.
5. Validar tema, painel, agrupamento, rede, Bluetooth e áudio em sessão MATE real.
6. Testar instalação e primeiro boot em VM UEFI e BIOS.
7. Só depois de aprovado e com autorização expressa, gerar a ISO.

Perfil inicial criado não significa ISO pronta ou validada.
