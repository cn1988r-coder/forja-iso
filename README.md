# VENOM OS

Distribuição baseada no **Manjaro Linux**, com uma única edição: **MATE + LightDM**.

- Idioma: Português do Brasil (pt_BR.UTF-8).
- Teclado: Brasil ABNT2.
- Kernel padrão: **Linux 6.18 LTS do Manjaro**.
- Tema VENOM: preto/grafite, azul elétrico e prata.
- MATE tradicional com painel superior e inferior.
- Brisk Menu no painel superior, com o símbolo V fornecido pelo tema de ícones VENOM.
- Relógio superior em formato 24 horas, com a data primeiro e a hora depois: `DD/MM/AAAA  HH:MM`.
- Atalho do Pamac centralizado no painel superior; área de notificação mantém os indicadores de Bluetooth e volume.
- Painel inferior com lista de janelas agrupadas.

## Base e instalador

A construção usa os perfis oficiais Manjaro ISO Profiles e o utilitário `buildiso`. O perfil está em `manjaro/venom-mate`.

O instalador é o **Calamares fornecido pelos repositórios oficiais do Manjaro**. Pamac, MATE, Brisk Menu, kernel, drivers e demais pacotes também devem ser resolvidos exclusivamente nos repositórios oficiais Manjaro. Não usar AUR, pacotes externos ou versões upstream baixadas separadamente.

## Compilação e automação

A infraestrutura de build segue o modelo por etapas do BigCommunity, adaptado à cadeia oficial Manjaro: GitHub Actions, runner Manjaro, manjaro-tools/buildiso, validação de perfil, resolução de dependências, logs, manifesto de pacotes, checksums e armazenamento de artefatos. Consulte [docs/BUILD-PIPELINE.md](docs/BUILD-PIPELINE.md). O workflow manual está em `.github/workflows/build-manjaro-iso.yml`; a geração da ISO é uma opção separada e começa desativada.

## Estado

A configuração do perfil e os testes de integração estrutural não substituem a resolução real dos pacotes, a inspeção do Calamares gerado nem os testes de boot e instalação. A inicialização dos aplicativos e applets ainda precisa ser confirmada em sessão MATE real. Nenhuma ISO deve ser gerada antes dessas etapas e da autorização expressa.
