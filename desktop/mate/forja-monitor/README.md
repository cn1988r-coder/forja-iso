# Forja Monitor

Monitor e gerenciador de sistema próprio da Forja OS, desenvolvido em Python com GTK3.

## Recursos

- Painel em tempo real com CPU total e por núcleo, memória RAM, SWAP, armazenamento, tráfego de rede de entrada e saída e sensores térmicos disponíveis.
- Gráficos Cairo leves, com histórico limitado a 48 amostras.
- Visão de volumes montados, sem contabilizar pseudo-filesystems como discos.
- Gerenciador de processos com PID, usuário, estado, CPU, memória, pesquisa e ordenação.
- Encerramento normal (SIGTERM) e forçado (SIGKILL), sempre com confirmação. A aplicação não eleva privilégios: processos protegidos pelo sistema permanecem protegidos.
- Informações do sistema: distribuição, kernel, arquitetura, CPU, GPU identificável pelo sysfs, memória, armazenamento, resolução, uptime e data de instalação quando registrada.
- Marca FORJA clicável para abrir as informações do sistema.

## Leveza e privacidade

- Não usa psutil, GNOME Shell, libadwaita, GTK4, WebKit, Electron ou serviços residentes.
- Lê informações locais de /proc, /sys, /etc/os-release e APIs padrão do Python.
- Não executa comandos externos, não envia dados pela rede e não precisa ser executado como root.
- Atualiza métricas a cada 2 segundos e processos a cada 3 segundos, somente enquanto a janela está aberta.
- Sem animações, transparências, blur ou efeitos de transição.

## Dependências

GTK3, Python, PyGObject e python-cairo. O Cairo é usado para desenhar os gráficos dentro do GTK.

## Instalação no root filesystem

`sudo desktop/mate/install-forja-monitor.sh /caminho/para/airootfs`

## Data e hora da instalação

O aplicativo lê `/var/lib/forja-os/install-info.json`, campo `installed_at`. O helper `/usr/bin/forja-record-install-time` deve ser chamado pelo instalador uma única vez, no fim da instalação no disco, executado como root. Sem argumento, captura a hora local real; também aceita `--installed-at` em ISO 8601 com fuso horário.

O marcador é criado sem sobrescrever registro existente, preservando a data entre atualizações e reinicializações. A árvore atual ainda não contém um hook de conclusão do instalador para chamar o helper automaticamente. Até essa integração existir, o aplicativo informa corretamente que a data não foi registrada, em vez de inventá-la.

## Validação

O workflow `.github/workflows/validate-mate-packages.yml` executa `py_compile`, smoke test GTK com Xvfb, leitura de métricas, presença de processos e teste de instalação em root filesystem temporário. Esses testes automatizados não substituem teste visual em sessão MATE real e validação em hardware físico.
