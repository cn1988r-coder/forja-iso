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

## Data e hora de instalação
O aplicativo lê somente `/var/lib/forja-os/install-info.json`, campo `installed_at`, e exibe dia, mês, ano e hora local. O helper `/usr/bin/forja-record-install-time` deve ser chamado pelo instalador **uma única vez, no fim da instalação no disco**, executado como root. Sem argumento, ele captura a hora local real naquele momento; também aceita `--installed-at` em ISO 8601 com fuso horário, caso o instalador já tenha capturado o instante de conclusão.

O marcador é criado sem sobrescrever um registro existente. Assim, atualizações, reinicializações e troca de kernel não mudam a data. Timestamp ausente, inválido ou sem fuso resulta em “Data de instalação indisponível”, nunca em data inferida. O teste automatizado verifica gravação, preservação do fuso e bloqueio de sobrescrita.

**Limite atual de integração:** a árvore atual do repositório não contém um instalador de sistema nem um hook de conclusão identificável. Portanto, o helper está implementado e instalado no root filesystem preparado, mas ainda não existe um ponto real do instalador para chamá-lo automaticamente. Até essa ligação ser feita, a data não será gravada durante a instalação e a interface corretamente mostrará “Data de instalação indisponível”.

## Estado
O workflow do GitHub Actions executa compilação sintática e um smoke test GTK em display virtual (Xvfb), abrindo a janela, atualizando os quatro indicadores e fechando o aplicativo. Isso verifica inicialização e caminho básico da interface, mas não substitui teste visual em sessão MATE real, medição de RAM/CPU no hardware nem integração ao pipeline de instalação/ISO.
