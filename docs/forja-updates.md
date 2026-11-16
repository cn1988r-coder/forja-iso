# Atualizações próprias da Forja OS

## Dois fluxos independentes

1. **Arch Linux:** atualiza o sistema-base, kernel, firmware, drivers, bibliotecas e pacotes oficiais pelo Pacman e pelos espelhos oficiais.
2. **Repositório binário Forja:** distribui exclusivamente aplicativos e componentes desenvolvidos ou mantidos pela Forja OS. Não publica kernel nem versões substitutas de pacotes oficiais.

O repositório Forja usa um banco Pacman próprio e isolado. O cliente `forja-repo check` utiliza um arquivo de configuração e um `DBPath` exclusivos, para consultar apenas o catálogo `[forja]`. Ele não executa `pacman -Syu`, não atualiza pacotes oficiais e não altera `/etc/pacman.conf`.

## Repositório remoto

O repositório `cn1988r-coder/forja-updates` existe, mas está vazio neste momento. O plano é publicar os pacotes binários em GitHub Pages no endereço `https://cn1988r-coder.github.io/forja-updates/x86_64/`.

## Publicação e assinatura

O workflow `publish-forja-repository.yml` compila os PKGBUILDs próprios, assina os pacotes e o banco com uma chave GPG dedicada e publica o conteúdo na branch `gh-pages` do repositório separado.

Antes da publicação, precisam ser configurados os secrets `FORJA_UPDATES_TOKEN`, `FORJA_GPG_PRIVATE_KEY`, `FORJA_GPG_KEY_ID` e, se aplicável, `FORJA_GPG_PASSPHRASE`. O token precisa ter permissão de escrita no repositório `forja-updates`. GitHub Pages deve usar a branch `gh-pages`, pasta raiz.

A chave pública deve ser conferida pelo fingerprint por um canal confiável antes de ser importada e localmente assinada com `pacman-key`. Não reduzir `SigLevel` para contornar erros de assinatura.

## Limites atuais

- O cliente e os PKGBUILDs estão no branch de desenvolvimento, mas ainda não foram publicados como pacotes.
- O workflow de publicação ainda não foi executado com credenciais e chave reais.
- `forja-repo check` apenas consulta versões disponíveis de pacotes Forja já instalados; ainda não instala nem atualiza pacotes.
- A consulta Forja não interfere no fluxo de atualização do Arch Linux.