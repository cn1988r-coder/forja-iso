# Ferramentas upstream incorporadas ao repositório

O projeto completo **GitRepo**, mantido por BigCommunity, foi incorporado como submódulo Git em `vendor/gitrepo`.

- Origem: https://github.com/big-comm/gitrepo
- Commit upstream fixado: a0ffb0ce46407774325da57dd5796b76a291bdd9
- Licença upstream: MIT (arquivo LICENSE preservado no submódulo)
- Escopo: Build ISO, Build Package, CLIs, interfaces, módulos compartilhados e testes upstream.

Para obter o código ao clonar VENOM OS:
```bash
git submodule update --init --recursive
```

## Limite de uso no VENOM OS

A incorporação disponibiliza o código original completo para inspeção e integração. Ela não significa que os executáveis upstream estejam habilitados para construir VENOM: o Build ISO upstream usa por padrão a imagem `talesam/community-build` e o motor `biglinux/iso-profiles`, que não são a cadeia oficial Manjaro exigida pelo VENOM OS. Não executar o builder upstream com configurações padrão para gerar a ISO VENOM. A integração precisa apontar e validar a cadeia Manjaro oficial, mantendo `manjaro-tools-iso`, repositórios Manjaro e kernel `linux618`.
