# Continuidade VENOM OS

## Decisões atuais
- Escopo: somente VENOM OS MATE baseada no Manjaro.
- Branch autorizada: optimize/venom-iso-size.
- Perfil: manjaro/venom-mate.
- Desktop: MATE tradicional com painel superior e inferior.
- Menu: Brisk Menu no painel superior, com símbolo V através do tema de ícones VENOM; não usar o menu padrão MATE nem o antigo lançador personalizado.
- Kernel padrão da imagem: linux618, Linux 6.18 LTS.
- Construção: perfis oficiais Manjaro ISO Profiles e buildiso compatível com mt-0.15.
- Calamares, Pamac, Brisk Menu, MATE, kernel e demais pacotes: somente repositórios oficiais Manjaro Stable. Sem AUR ou fontes externas.
- Os antigos arquivos Archiso e o instalador próprio C/GTK4/TUI não fazem parte do caminho ativo.

## Estado
- Perfil Manjaro MATE com LightDM, GRUB, NetworkManager, Bluetooth e áudio Manjaro PipeWire.
- Calamares oficial é iniciado automaticamente na sessão live MATE; o sistema instalado usa MATE normal.
- Overlays live/instalado com tema escuro, painéis MATE tradicionais, Brisk Menu, wallpaper, locale pt_BR e teclado ABNT2.
- Validação estática e integração estrutural com iso-profiles oficial foram reportadas anteriormente como aprovadas.
- A resolução de pacotes deve ser repetida com a lista atualizada, especialmente para confirmar Brisk Menu e linux618 no repositório Stable.
- Nenhuma ISO foi gerada. Não afirmar boot, sessão gráfica ou instalação testados sem executar esses testes.

## Pendências
1. Executar buildiso -x no Manjaro Stable e corrigir qualquer pacote ausente/incompatível.
2. Confirmar Calamares e Pamac instalados a partir dos repositórios oficiais e inspecionar a configuração Calamares gerada.
3. Confirmar Brisk Menu carregado no painel superior e o símbolo V exibido no applet em sessão MATE real.
4. Validar os dois painéis, agrupamento de janelas, tema, rede, Bluetooth e áudio em sessão MATE real.
5. Testar inicialização e instalação em VM UEFI e BIOS, incluindo primeiro boot do sistema instalado.
6. Só depois de aprovado e com autorização expressa, gerar a ISO.

Perfil e validação estática não significam ISO pronta ou validada.
