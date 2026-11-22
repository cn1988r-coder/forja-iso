# Continuidade VENOM OS

## Decisões atuais
- Escopo: somente VENOM OS MATE baseada no Manjaro.
- Branch autorizada: optimize/venom-iso-size.
- Perfil: manjaro/venom-mate.
- Desktop: MATE tradicional com painel superior e inferior.
- Menu: Brisk Menu no painel superior, com símbolo V através do tema de ícones VENOM; não usar o menu padrão MATE nem o antigo lançador personalizado.
- Painel superior: data primeiro e hora depois, em 24h, no formato `DD/MM/AAAA  HH:MM`; atalho Pamac centralizado; área de notificação e volume mantidos.
- Kernel padrão da imagem: linux618, Linux 6.18 LTS.
- Construção: perfis oficiais Manjaro ISO Profiles e buildiso compatível com mt-0.15.
- Calamares, Pamac, Brisk Menu, MATE, kernel e demais pacotes: somente repositórios oficiais Manjaro Stable. Sem AUR ou fontes externas para pacotes do sistema.
- Os antigos arquivos Archiso e o instalador próprio C/GTK4/TUI não fazem parte do caminho ativo.

## Infraestrutura de build
- Criado `.github/workflows/build-manjaro-iso.yml` com runner Manjaro self-hosted, ShellCheck, validação estrutural, resolução de pacotes por `buildiso -x`, geração opcional da ISO, manifesto, checksums e upload de logs/artefatos.
- Criado `docs/BUILD-PIPELINE.md` documentando as ferramentas adotadas e as diferenças deliberadas em relação ao BigCommunity.
- GitRepo e a imagem Docker comunitária BigCommunity não foram incorporados porque são componentes externos à cadeia oficial Manjaro. O container oficial Manjaro permanece uma possibilidade a validar; o build atual exige runner Manjaro nativo.
- O workflow ainda não foi executado: depende de runner self-hosted Manjaro registrado com rótulos `self-hosted`, `linux`, `manjaro`, `x64`. Nenhuma ISO foi gerada.

## Estado
- Perfil Manjaro MATE com LightDM, GRUB, NetworkManager, Bluetooth e áudio Manjaro PipeWire.
- Calamares oficial está configurado para iniciar automaticamente na sessão live MATE; isso ainda precisa ser confirmado em boot real.
- Overlays live/instalado com tema escuro, painéis MATE tradicionais, Brisk Menu, wallpaper, locale pt_BR e teclado ABNT2. O overlay instalado foi sincronizado com o relógio dinâmico `DD/MM/AAAA  HH:MM`, agrupamento de janelas e tema de ícones VENOM.
- A validação estática foi ajustada para exigir a ordem correta data/hora e conferir o comando do lançador Pamac. O resultado do CI desse commit ainda precisa ser consultado.
- O workflow antigo de resolução foi desativado como etapa automática porque instalava componentes do Arch/upstream, contrariando a regra de origem. O workflow foi convertido em preflight estático manual; ele não resolve pacotes nem compila ISO.
- A resolução real de pacotes continua pendente e deve ocorrer em ambiente Manjaro com manjaro-tools e repositórios Stable oficiais, especialmente para confirmar Brisk Menu, linux618, Pamac e Calamares.
- Nenhuma ISO foi gerada. Não afirmar boot, sessão gráfica, aplicativos abertos ou instalação testados sem executar esses testes.

## Pendências
1. Revisar a origem de todas as ferramentas usadas pelo workflow de resolução de pacotes, que atualmente baixa componentes de fontes Arch/upstream e conflita com a regra de usar a cadeia oficial Manjaro.
2. Executar resolução de pacotes usando ferramentas e repositórios oficiais Manjaro e corrigir qualquer pacote ausente/incompatível.
3. Confirmar Calamares e Pamac instalados a partir dos repositórios oficiais e inspecionar a configuração Calamares gerada.
4. Confirmar Brisk Menu carregado no painel superior, símbolo V e relógio `DD/MM/AAAA  HH:MM` em sessão MATE real.
5. Validar os lançadores de aplicativos e os applets de rede, Bluetooth e volume em sessão MATE real.
6. Testar inicialização e instalação em VM UEFI e BIOS, incluindo primeiro boot do sistema instalado.
7. Só depois de aprovado e com autorização expressa, gerar a ISO.

Perfil e validação estática não significam ISO pronta ou validada.
