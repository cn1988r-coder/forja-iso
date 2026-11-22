# Continuidade VENOM OS

## Migração Manjaro MATE
- Escopo: somente VENOM OS MATE baseada no Manjaro.
- Branch autorizada: optimize/venom-iso-size.
- Perfil: manjaro/venom-mate.
- Construção: perfis oficiais Manjaro ISO Profiles e buildiso compatível com mt-0.15.
- Calamares: pacote da lista compartilhada oficial Manjaro Packages-Live; nenhuma versão upstream ou fonte externa.
- O perfil usa as listas compartilhadas oficiais Packages-Root, Packages-Live e Packages-Mhwd.
- O perfil antigo Archiso em build/ é legado e não deve gerar a ISO Manjaro.

## Estado desta etapa
- Perfil inicial Manjaro MATE criado com LightDM, GRUB, NetworkManager, Bluetooth e áudio Manjaro PipeWire.
- Configuração Calamares personalizada via opções suportadas pelo profile.conf (janela fullscreen e cores VENOM).
- Overlay comum para live e instalado com MATE escuro, painel inferior, menu VENOM, wallpaper, locale pt_BR e teclado ABNT2.
- Calamares configurado para iniciar automaticamente na sessão live MATE; o sistema instalado mantém a sessão MATE normal.
- Scripts criados para sincronizar overlays, validar estrutura, testar resolução de pacotes com buildiso -x e bloquear a geração da ISO sem autorização explícita.
- Nenhuma ISO foi gerada.

## Validação já observada
- A primeira execução da validação estática falhou porque symlinks oficiais ainda não existem na árvore local; o verificador foi corrigido para validar os links sem exigir que os destinos compartilhados estejam clonados.
- A execução corrigida precisa ser confirmada pela workflow mais recente.
- Ainda não houve resolução real de pacotes com buildiso, teste visual MATE, teste do Calamares ou instalação em VM.

## Pendências obrigatórias
1. Executar scripts/validate-manjaro-build.sh em ambiente Manjaro e corrigir todos os pacotes ausentes.
2. Confirmar que Calamares foi instalado da lista/repositório oficial Manjaro e inspecionar settings/modules gerados.
3. Testar inicialização direta do instalador, idioma pt_BR, teclado ABNT2 e comportamento de saída/erro.
4. Validar tema, painel, agrupamento de janelas, rede, Bluetooth e áudio em VM.
5. Testar instalação e primeiro boot em VM UEFI e BIOS.
6. Só depois de aprovado e com autorização expressa, gerar a ISO.

Perfil criado não significa ISO pronta ou validada.
