# Build da Forja OS

O build usa o framework oficial EndeavourOS-ISO fixado no commit
`90376d8f52ab19e19073eed33d6f36c46ec7c409`. A revisão está fixada para
evitar que uma mudança no upstream altere silenciosamente a compilação.

## Host

Use EndeavourOS ou Arch Linux com os repositórios EndeavourOS habilitados.
O build precisa de acesso à rede, privilégios administrativos, espaço livre
amplo (recomendado: pelo menos 40 GiB) e memória suficiente. Não é um build
adequado para o runner gratuito padrão do GitHub Actions.

## Executar

Na raiz do repositório:

```bash
bash scripts/build-forja-iso.sh
```

O script prepara o framework, substitui o conjunto KDE por MATE, aplica as
configurações Forja, constrói o Calamares do EndeavourOS e os pacotes
Ferdium/Shelly a partir das receitas publicadas pelos respectivos projetos,
e chama o compilador EndeavourOS. A saída fica em `work/EndeavourOS-ISO/out/`.

Pacotes do AUR são receitas comunitárias, não binários oficiais. Revise as
receitas antes de usá-las em uma compilação de produção.

## Estado de validação

A existência do script e dos arquivos de perfil não prova que o build foi
concluído. A ISO só pode ser marcada como validada depois de uma compilação
real e testes de boot, sessão MATE e instalação do Calamares em máquina
virtual. O build requer um host Arch/EndeavourOS; este repositório não fornece
uma máquina remota persistente.
