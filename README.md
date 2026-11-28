# BuildMaker - perfil Manjaro com Window Maker

Perfil de sistema Manjaro com Window Maker como gerenciador de janelas. A interface preserva o dock clássico em quadrados e acrescenta controles por mouse, painel inferior e monitoramento real.

## Escopo
- Base Manjaro, Pamac, Firefox e Calamares.
- Window Maker como sessão principal.
- Dock nativo do Window Maker em quadrados; a configuração dos ícones ainda precisa ser concluída.
- Painel inferior clicável para alternar janelas.
- Controles de janela por mouse: pendentes de configuração e teste.
- Paleta grafite/chumbo com azul elétrico, sem aparência metálica exagerada.
- Configuração de acessibilidade para canhotos: pendente de implementação e teste.

## Estrutura
- `Packages-Desktop`: pacotes da sessão e aplicativos.
- `profile.conf`: metadados do perfil Manjaro.
- `desktop-overlay/`: configurações padrão da sessão live.
- `scripts/`: configuração idempotente do desktop.

## Limite importante
Este commit prepara o perfil e os arquivos-base. A geração de uma ISO Manjaro exige um runner Linux com os Manjaro Tools, repositórios acessíveis e espaço de build. Não declare uma ISO compilada até o workflow terminar com sucesso e publicar o artefato.
