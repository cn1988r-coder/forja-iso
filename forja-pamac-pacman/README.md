# Forja Store

A Forja Store é a interface visual personalizada do **Pamac**, não um gerenciador de pacotes independente.

## Arquitetura

- **Interface:** Pamac Manager GTK4 com libadwaita, compilado a partir do código-fonte upstream.
- **Visual Forja:** folha de estilos GTK própria, superfícies escuras, cartões arredondados, navegação discreta e paleta monocromática.
- **Backend:** libpamac e transações originais do Pamac. Não substituímos a lógica de dependências, resolução, download ou instalação.
- **Repositórios e AUR:** mantidos pelo próprio Pamac.
- **Flatpak:** suporte do libpamac via plugin Flatpak, com Flathub configurado no sistema.
- **Atualizações no painel XFCE:** indicador Forja separado, que consulta Pamac e Flatpak e abre a Forja Store na seção de atualizações.

## Integração

O construtor obtém o código Pamac upstream em um commit fixo, aplica apenas as alterações visuais e de identidade da Forja e compila o alvo gráfico. O executável e a biblioteca GTK do Pamac são instalados em `/usr/lib/forja`, sem substituir o `pamac` CLI nem a biblioteca `libpamac` do sistema.

O código-fonte correspondente, já com as alterações Forja, é instalado em:

`/usr/share/doc/forja-store/pamac-11.7.5-forja-source.tar.gz`

O lançador `/usr/bin/forja-store` carrega a biblioteca GTK compilada junto com a interface. O Pamac é executado como usuário da sessão e solicita a autorização necessária por Polkit. Não executar com `sudo`.

## Compilação e validação

`build-pamac.sh` compila a interface no ambiente Manjaro de construção. A validação Manjaro executa essa compilação antes de aceitar o perfil XFCE. A compilação da interface não gera uma ISO.

O indicador de atualizações continua usando os utilitários CLI e os parsers da Forja. O antigo frontend GTK3 independente não é instalado.
