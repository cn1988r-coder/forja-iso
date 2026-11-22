# AGENTS.md

## VENOM OS
- Base única: Manjaro Linux e repositórios oficiais.
- Edição única: MATE + LightDM.
- Idioma padrão: pt_BR.UTF-8; teclado Brasil ABNT2.
- Não criar edições XFCE, Arch ou outras variantes.
- O perfil Archiso antigo não pode ser usado para construir a VENOM.

## Construção
- Usar os perfis oficiais Manjaro ISO Profiles e manjaro-tools/buildiso compatível com mt-0.15.
- Perfil VENOM: manjaro/venom-mate.
- Packages-Root, Packages-Live e Packages-Mhwd devem usar as listas compartilhadas oficiais.
- Não usar Archiso, mkarchiso, repositórios Arch ou pacman.conf Arch.

## Calamares
- Usar exclusivamente o pacote e a versão fornecidos pelos repositórios oficiais Manjaro selecionados.
- Não baixar, compilar, substituir ou integrar Calamares upstream ou de fontes externas.
- Deixar manjaro-tools gerar a configuração a partir do perfil oficial.

## Desktop
- MATE é o único ambiente.
- Visual escuro VENOM: preto/grafite, azul elétrico e prata.
- A personalização deve ser idêntica na sessão live e no sistema instalado.
- Painel inferior com lançador VENOM, lista de janelas agrupadas, área de notificação, volume e relógio.
- Rede: NetworkManager e network-manager-applet. Bluetooth: BlueZ/Blueman. Áudio: stack Manjaro PipeWire.
- Não declarar validação visual sem sessão gráfica real.

## Segurança
- Não gerar/publicar ISO antes de resolver pacotes, validar Calamares, testar boot/instalação em VM e receber autorização expressa.
- Primeiro usar buildiso -x para resolver pacotes sem gerar ISO.
- Testes destrutivos somente em discos virtuais descartáveis.
- Registrar testes realmente executados em docs/PROJECT-CONTINUITY.md.
