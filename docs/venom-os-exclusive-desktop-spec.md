# VENOM OS Exclusive — especificação do desktop XFCE

Status: especificação registrada; implementação e validação visual ainda pendentes.
Branch: `feature/venom-os-2.0-xfce`.

## Referência de comportamento: GNOME Dash to Dock

Usar a extensão Dash to Dock como referência funcional, sem instalar GNOME Shell nem a extensão original no XFCE. A extensão GNOME oferece dock inferior/lateral, favoritos fixados, acesso rápido às janelas e áreas de trabalho, modos fixo/auto-ocultar/intelligent-hide, transparência e indicadores configuráveis.

## Experiência desejada na VENOM OS Exclusive

- XFCE continua sendo o ambiente de desktop.
- Dock horizontal na parte inferior, visual moderno e integrado ao painel.
- Ícones de aplicativos favoritos fixos e organizados, com tamanho uniforme e espaçamento equilibrado.
- Aplicativos em execução identificados pelo indicador redondo e discreto somente abaixo do ícone.
- Nenhum tile/fundo quadrado, moldura, borda ou botão retangular envolvendo os ícones.
- Clique no ícone abre o aplicativo ou alterna para a janela existente; janelas do mesmo aplicativo agrupadas.
- Previews de janelas ao passar o cursor, se o componente XFCE escolhido oferecer suporte estável.
- Avaliar ocultação inteligente quando uma janela maximizada/ocupando a área da dock precisar de espaço. Não ativar auto-hide por padrão sem validar a usabilidade.
- Animações discretas e transições suaves, sem efeitos excessivos.
- Painel inferior um pouco mais alto, relógio/data integrados, menu VENOM à esquerda e indicadores de sistema organizados.
- Menu de aplicativos moderno, com busca, categorias e favoritos.
- Tema GTK Materia Dark, ícones Yaru Blue e aparência coerente entre painel, menu, janelas e aplicativos.
- Não alterar nem escolher wallpaper nesta etapa; o usuário fornecerá a imagem posteriormente.
- Manter estabilidade gráfica: compositor XFCE permanece desativado até teste específico justificar mudança.

## Aplicativos que devem estar acessíveis

Fixar no dock e disponibilizar no menu:
1. Firefox.
2. Ferdium.
3. Pamac: gerenciador e loja gráfica de aplicativos da VENOM OS.
4. Pamac.

Firefox já aparece nos manifestos atuais. Ferdium ainda não está confirmado nos manifestos. Pamac/libpamac já aparecem como pacotes AUR nos manifestos atuais. Antes de adicionar Shelly, confirmar o projeto/repositório correto, origem do pacote, manutenção e compatibilidade com Arch Linux.

## Função do Pamac

- **Pamac será a única loja/gerenciador gráfico de aplicativos incluído na VENOM OS Exclusive.**
- Não incluir Shelly nesta edição, para evitar duplicação de ferramentas e consumo desnecessário de recursos.
- Pamac deverá iniciar com a sessão XFCE e exibir seu indicador de bandeja para avisar sobre atualizações disponíveis.
- Confirmar o nome do executável, a opção de autostart e o suporte real ao indicador no pacote Arch/AUR escolhido.
- Pamac deve aparecer no menu e ter lançador acessível no dock conforme o arquivo .desktop real.
- Validar o indicador e as notificações em uma sessão XFCE real antes de considerar a tarefa concluída.

## Critérios técnicos antes de implementar

- Não presumir que o CSS atual do Docklike remove fundos/bordas ou que `indicatorOrientation=1` significa indicador inferior. Conferir documentação/código e testar no XFCE real.
- Comparar opções nativas do XFCE e escolher um componente mantido e compatível; não usar GNOME Shell como dependência.
- Validar os arquivos .desktop reais dos aplicativos antes de fixar seus ícones.
- Evitar duplicar dock e painel de tarefas.
- Preservar a ISO #74. Não iniciar build nem substituir artefatos até passar revisão estática, build, boot UEFI, sessão XFCE e teste visual.
- Esta especificação não declara que a interface já foi implementada ou testada.
