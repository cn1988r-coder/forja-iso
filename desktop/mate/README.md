# Forja OS MATE

Camada de ambiente gráfico da edição MATE da Forja OS. Ela fica separada das fundações técnicas `bases/archlinux/` e `bases/endeavouros/`.

## Princípio

Usar o MATE upstream dos repositórios oficiais do Arch/EndeavourOS como base funcional e aplicar a identidade Forja OS por cima. Não importar uma edição MATE de outra distribuição, não substituir componentes centrais sem necessidade e não copiar configurações de desktop de terceiros.

## Escopo inicial

- Sessão MATE com Marco, mate-panel, Caja e ferramentas essenciais.
- LightDM como gerenciador de login.
- NetworkManager com applet de rede.
- Blueman para Bluetooth.
- PipeWire/WirePlumber para áudio.
- Applets MATE essenciais, incluindo relógio/calendário.
- Calculadora GNOME (`gnome-calculator`) como aplicativo independente, sem instalar o ambiente GNOME.
- Tema Materia-dark e ícones Papirus-Dark como ponto de partida visual.
- Configuração GTK para tema escuro, fonte legível e animações GTK desligadas.
- Configurações de baixo consumo: compositor do Marco desligado e efeitos de fundo desnecessários desativados.
- **Captura de tela:** usar somente `xfce4-screenshooter`, como ferramenta isolada. O pacote `mate-utils` foi deixado de fora porque inclui o `mate-screenshot` nativo. Não instalar o desktop XFCE, painel, sessão, gerenciador de arquivos ou demais aplicativos XFCE.

## Arquivos

- `packages.x86_64`: seleção explícita de pacotes, sem instalar indiscriminadamente o grupo `mate-extra`. Inclui `gnome-calculator) como aplicativo GNOME independente, sem trazer o desktop GNOME; inclui também apenas `xfce4-screenshooter` como exceção pontual para captura de tela e exclui `mate-utils`, que fornece o `mate-screenshot` nativo.
- `skel/.config/gtk-3.0/settings.ini`: aparência GTK padrão para novos usuários quando o construtor copiar o esqueleto para `/etc/skel`.
- `apply-defaults.sh`: aplica configurações MATE seguras ao usuário da sessão, verificando primeiro se cada schema/chave existe.
- `services.enabled`: serviços que o perfil de imagem deverá habilitar.
- `scripts/validate-packages.sh`: verifica nomes de pacotes com o pacman.

## Dependências e limpeza

As bibliotecas exigidas pelos pacotes escolhidos devem permanecer. Não remover dependências runtime para tentar reduzir a lista: o pacman resolve dependências transitivas durante a instalação. A limpeza deve retirar aplicações opcionais sem uso, não bibliotecas necessárias.

A lista evita instalar o grupo completo `mate-extra), mas mantém os componentes funcionais necessários para sessão, calendário, energia, rede, Bluetooth, áudio e dispositivos removíveis. A Calculadora GNOME é incluída somente como aplicativo independente; isso não instala a sessão nem o desktop GNOME. O utilitário XFCE de captura de tela é a única aplicação XFCE selecionada e não equivale a instalar o ambiente XFCE. `mate-utils` não é instalado para que o `mate-screenshot` não venha junto.

## Validação

Execute `bash desktop/mate/scripts/validate-packages.sh` em um ambiente Arch/EndeavourOS atualizado, com as bases de pacotes sincronizadas. Isso verifica a existência dos nomes nos repositórios configurados; não substitui instalação, resolução integral de dependências, testes de sessão ou build de ISO.

## Estado

Esta é uma camada inicial de definição. Ainda não foi instalada em uma máquina, o validador não foi executado em Arch/EndeavourOS e não houve build de ISO. Não declarar o desktop completo ou funcional até concluir os testes.
