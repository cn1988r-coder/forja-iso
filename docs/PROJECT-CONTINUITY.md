# Continuidade VENOM OS

## Migração Manjaro MATE
- Escopo: somente VENOM OS MATE baseada no Manjaro.
- Branch autorizada: optimize/venom-iso-size.
- Perfil: manjaro/venom-mate.
- Construção: perfis oficiais Manjaro ISO Profiles e buildiso compatível com mt-0.15.
- Calamares: pacote da lista compartilhada oficial Manjaro Packages-Live; nenhuma versão upstream ou fonte externa.
- O perfil usa as listas compartilhadas oficiais Packages-Root, Packages-Live e Packages-Mhwd.
- Os antigos arquivos Archiso, scripts de build Arch e o instalador próprio C/GTK4/TUI foram retirados.

## Estado
- Perfil Manjaro MATE com LightDM, GRUB, NetworkManager, Bluetooth e áudio Manjaro PipeWire.
- Calamares oficial inicia automaticamente na sessão live MATE; o sistema instalado usa MATE normal.
- Overlays live/instalado com tema escuro, painel inferior, menu VENOM, wallpaper, locale pt_BR e teclado ABNT2.
- Validação estática e integração estrutural com iso-profiles oficial aprovadas no workflow 45082662203.
- Primeira tentativa de resolver pacotes falhou antes da etapa de buildiso: a compilação de manjaro-tools tentou gerar documentação e faltava db2x_manxml. O perfil ainda não havia sido avaliado.
- Workflow corrigido para pular documentação e repetir resolução de pacotes sem gerar ISO.
- Nenhuma ISO foi gerada.

## Pendências
1. Concluir buildiso -x e corrigir pacotes ausentes/incompatíveis.
2. Inspecionar a configuração Calamares gerada e confirmar a versão instalada do repositório oficial Manjaro.
3. Testar inicialização direta do instalador, idioma pt_BR, teclado ABNT2 e fluxo de saída/erro.
4. Validar tema, painel, agrupamento, rede, Bluetooth e áudio em sessão MATE real.
5. Testar instalação e primeiro boot em VM UEFI e BIOS.
6. Só depois de aprovado e com autorização expressa, gerar a ISO.

Perfil e validação estática aprovados não significam ISO pronta ou validada.
