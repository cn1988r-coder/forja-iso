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
3. Gerenciador/loja gráfica de aplicativos do Arch Linux (identidade exata ainda precisa ser confirmada pelo usuário).
4. Pamac.

Firefox já aparece nos manifestos atuais. Ferdium e a loja gráfica ainda não estão confirmados nos manifestos. Pamac/libpamac já aparecem como pacotes AUR nos manifestos atuais. Antes de adicionar novos pacotes, confirmar origem, nome do pacote, manutenção e compatibilidade com Arch Linux.

## Critérios técnicos antes de implementar

- Não presumir que o CSS atual do Docklike remove fundos/bordas ou que `indicatorOrientation=1` significa indicador inferior. Conferir documentação/código e testar no XFCE real.
- Comparar opções nativas do XFCE e escolher um componente mantido e compatível; não usar GNOME Shell como dependência.
- Validar os arquivos .desktop reais dos aplicativos antes de fixar seus ícones.
- Evitar duplicar dock e painel de tarefas.
- Preservar a ISO #74. Não iniciar build nem substituir artefatos até passar revisão estática, build, boot UEFI, sessão XFCE e teste visual.
- Esta especificação não declara que a interface já foi implementada ou testada.
