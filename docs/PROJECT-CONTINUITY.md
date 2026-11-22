# Continuidade VENOM OS

## Migração Manjaro MATE
- Escopo: somente VENOM OS MATE baseada no Manjaro.
- Branch autorizada: optimize/venom-iso-size.
- Perfil: manjaro/venom-mate.
- Construção: perfis oficiais Manjaro ISO Profiles e buildiso compatível com mt-0.15.
- Calamares: pacote da lista compartilhada oficial Manjaro Packages-Live; nenhuma versão upstream ou fonte externa.
- O perfil usa as listas compartilhadas oficiais Packages-Root, Packages-Live e Packages-Mhwd.
- Os antigos arquivos Archiso, scripts de build Arch e o instalador próprio C/GTK4/TUI foram retirados para impedir uso acidental da base errada.

## Estado desta etapa
- Perfil inicial Manjaro MATE criado com LightDM, GRUB, NetworkManager, Bluetooth e áudio Manjaro PipeWire.
- Calamares vem da lista oficial Manjaro Packages-Live e inicia automaticamente na sessão live MATE.
- Overlays comuns para live e instalado com tema escuro, painel inferior, menu VENOM, wallpaper, locale pt_BR e teclado ABNT2.
- Serviços de rede, Bluetooth e atualização do banco dconf configurados.
- Validação estática e integração estrutural com o repositório oficial de perfis Manjaro aprovadas no commit 8506bf84c29ab19197007338173d7f0e106d6c68 (workflow 45082441054).
- Workflow de resolução real de pacotes sem ISO iniciada no commit 3cb752f0be7bcfd8b7428f9c4e0b4359a42c04dd (workflow 45082537559). Resultado ainda pendente neste registro.
- Nenhuma ISO foi gerada.

## Pendências obrigatórias
1. Concluir buildiso -x e corrigir todos os pacotes ausentes/incompatíveis.
2. Inspecionar a configuração Calamares gerada e confirmar a versão instalada a partir do repositório oficial Manjaro.
3. Testar inicialização direta do instalador, idioma pt_BR, teclado ABNT2 e fluxo de saída/erro.
4. Validar tema, painel, agrupamento, rede, Bluetooth e áudio em sessão MATE real.
5. Testar instalação e primeiro boot em VM UEFI e BIOS.
6. Só depois de aprovado e com autorização expressa, gerar a ISO.

Perfil e validação estática aprovados não significam ISO pronta ou validada.
