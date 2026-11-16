# Repositório binário próprio da Forja OS

O cliente `forja-repo` é integrado à Forja Store e mantém o canal de aplicativos Forja separado das atualizações gerais do Arch Linux.

## Comandos

- `forja-repo list`: lista os pacotes publicados no canal Forja.
- `forja-repo search TERMO`: pesquisa somente no repositório Forja.
- `forja-repo updates`: compara as versões publicadas com os pacotes Forja instalados.
- `forja-repo check`: alias de `updates`.

A consulta usa um `pacman.conf` com DBPath e cache exclusivos em `/var/lib/forja-repo` e `/var/cache/forja-repo`. Assim, a atualização do catálogo Forja não sincroniza as bases do Arch e não inicia uma atualização parcial do sistema.

A instalação/atualização de um pacote selecionado usa outro arquivo de configuração, que inclui `/etc/pacman.conf` e acrescenta apenas o repositório Forja. O helper Polkit executa `pacman -S forja/NOME` para o pacote escolhido. Ele não executa `pacman -Syu` nem atualiza pacotes Arch sem relação com essa operação.

## Assinatura e publicação

O repositório remoto é publicado em:

`https://cn1988r-coder.github.io/forja-updates/$arch`

As bases e os pacotes exigem assinatura GPG. O workflow `.github/workflows/publish-forja-repository.yml` publica os pacotes `forja-store` e `forja-repo-client` no repositório separado `cn1988r-coder/forja-updates`.

Para ativar a publicação, o proprietário precisa configurar no repositório `forja-iso` os segredos:

- `FORJA_UPDATES_TOKEN`: token com permissão de escrita no repositório `forja-updates`.
- `FORJA_GPG_PRIVATE_KEY`: chave privada de assinatura GPG exportada em formato ASCII.
- `FORJA_GPG_KEY_ID`: fingerprint completo da chave de assinatura.
- `FORJA_GPG_PASSPHRASE`: somente se a chave privada tiver senha.

Também é necessário habilitar GitHub Pages para o repositório `forja-updates`, usando a branch `gh-pages`.

**Estado atual:** a integração da loja e o cliente estão preparados no código, mas o repositório remoto continua vazio e ainda não há publicação assinada. O canal só deve ser considerado operacional depois de configurar os segredos, publicar os pacotes e validar uma instalação/atualização real. A chave pública e sua impressão digital também precisam ser distribuídas e confiadas no sistema antes de aceitar pacotes assinados.
