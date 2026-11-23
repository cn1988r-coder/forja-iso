# Personalização visual da VENOM OS XFCE

A edição XFCE utiliza exclusivamente estas três categorias de personalização:

- **Tema GTK e decoração de janelas:** Materia Dark (pacote materia-gtk-theme).
- **Ícones:** Papirus Blue, aplicado pela variante Papirus-Dark (pacote papirus-icon-theme).
- **Cursor:** Bibata Modern Classic (pacote bibata-cursor-theme).

Os três pacotes são declarados em Packages-Desktop, e as escolhas padrão são aplicadas aos novos usuários por meio dos arquivos XFCE em /etc/skel. O greeter GTK do LightDM recebe as mesmas escolhas visuais.

## Calamares oficial do Manjaro

O pacote calamares é declarado em Packages-Live, pois o instalador pertence ao ambiente live e não ao sistema instalado no disco. O perfil habilita mhwd_used="true" para usar a integração de detecção de hardware do Manjaro.

O pacote será resolvido exclusivamente pelos repositórios oficiais configurados do Manjaro. Não há download, compilação ou substituição do Calamares upstream, AUR ou de fontes externas.

Esta configuração registra a integração no perfil. A presença e o funcionamento do instalador na ISO final ainda dependem de uma futura construção e validação, que permanecem bloqueadas até autorização expressa.
