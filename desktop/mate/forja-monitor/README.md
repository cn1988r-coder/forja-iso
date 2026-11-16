# Forja Monitor

Monitor de recursos e informações do sistema próprio da Forja OS, escrito em Python com GTK3.

## Leveza por projeto
- Não usa GNOME Shell, libadwaita, GTK4, WebKit, Electron, JavaScript ou serviços residentes.
- Não depende de psutil. CPU, memória e rede são lidos diretamente de /proc; disco e sensores, de APIs simples do sistema.
- Não mantém daemon em segundo plano. A amostragem acontece somente enquanto a janela está aberta, a cada 2 segundos.
- Gráficos são desenhados por Cairo/GTK e guardam no máximo 48 amostras.
- A página de informações consulta detalhes sob demanda.
- Sem animações ou efeitos de transição.

## Dependências
GTK3, Python e PyGObject, já selecionados na camada MATE/Forja Store. O pacote não instala componentes do GNOME.

## Instalação no root filesystem
`sudo desktop/mate/install-forja-monitor.sh /caminho/para/airootfs`

## Data de instalação
O aplicativo lê somente `/var/lib/forja-os/install-info.json`, campo `installed_at`. Até que o instalador real grave esse marcador ao concluir a instalação, o app informa “Data de instalação indisponível”. Não usa data de criação de arquivos nem primeiro boot como substituto.

## Estado
Implementação inicial. A validação sintática não substitui teste visual, medição de RAM/CPU em sessão MATE real, nem integração ao pipeline de instalação/ISO.
