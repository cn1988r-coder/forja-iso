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
GTK3, Python, PyGObject e python-cairo. O Cairo é usado somente para desenhar os gráficos leves no GTK. O pacote não instala componentes do GNOME.

## Instalação no root filesystem
`sudo desktop/mate/install-forja-monitor.sh /caminho/para/airootfs`

## Data de instalação
O aplicativo lê somente `/var/lib/forja-os/install-info.json`, campo `installed_at`. Até que o instalador real grave esse marcador ao concluir a instalação, o app informa “Data de instalação indisponível”. Não usa data de criação de arquivos nem primeiro boot como substituto.

## Estado
O workflow do GitHub Actions executa compilação sintática e um smoke test GTK em display virtual (Xvfb), abrindo a janela, atualizando os quatro indicadores e fechando o aplicativo. Isso verifica inicialização e caminho básico da interface, mas não substitui teste visual em sessão MATE real, medição de RAM/CPU no hardware nem integração ao pipeline de instalação/ISO.
