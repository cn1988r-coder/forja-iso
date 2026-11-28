# BuildMaker

Perfil Manjaro com **Window Maker como gerenciador de janelas principal**. XFCE fornece apenas aplicativos auxiliares (terminal e monitor de processos), não é o ambiente de trabalho nem o gerenciador de janelas.

## Interface prevista
- Identidade BuildMaker, sem marcas ou elementos visuais do Manjaro.
- Window Maker como WM principal, preservando o dock nativo em quadrados.
- Barra Tint2 inferior com botão V clicável, lista de janelas e bandeja do sistema.
- Menu jgmenu categorizado, com aplicativos, configurações e energia.
- Relógio digital e data no topo, com monitor Conky à direita (CPU, RAM, armazenamento, rede e processos).
- Tema grafite com azul elétrico e prata, sem efeitos pesados.
- Ação gráfica para energia e opção para habilitar mouse para canhotos.

## Arquivos principais
- `Packages-Desktop`: dependências da sessão.
- `profile.conf`: metadados do perfil.
- `desktop-overlay/`: configurações padrão copiadas para o usuário live/instalado.
- `scripts/`: preparação idempotente da sessão.

## Estado de validação
As configurações e os lançadores estão preparados no perfil. Ainda é necessário testar a sessão em um servidor gráfico real: dock nativo e botões de janela do Window Maker, execução do jgmenu pelo botão V, bandeja, ações de energia, detecção de dispositivos de entrada e inicialização automática. Nenhuma ISO é declarada compilada ou testada neste estágio.
