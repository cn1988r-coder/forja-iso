# Repositório binário próprio da Forja OS

## Separação obrigatória

- Arch Linux mantém kernel, drivers, bibliotecas e pacotes oficiais.
- O repositório Forja contém somente aplicativos e componentes com nomes próprios da Forja.
- A Forja não publica versões substitutas de pacotes oficiais.
- O comando `forja-repo check` consulta somente o banco isolado `/var/lib/forja-repo`. Não executa atualização completa nem altera `/etc/pacman.conf`.

## Repositório remoto existente

O repositório GitHub `cn1988r-coder/forja-updates` existe, mas foi encontrado vazio (sem commits). Ele será usado como hospedagem estática do repositório binário via GitHub Pages, branch `gh-pages`.

## Preparação única de segurança e publicação

No repositório `forja-iso`, configure os GitHub Actions secrets:
- `FORJA_UPDATES_TOKEN`: token fine-grained com acesso Contents: Read and write somente ao repositório `forja-updates`.
- `FORJA_GPG_PRIVATE_KEY`: chave privada dedicada, exportada em formato ASCII-armored.
- `FORJA_GPG_KEY_ID`: fingerprint completo da chave.
- `FORJA_GPG_PASSPHRASE`: senha da chave, se houver.

A chave privada deve ser criada e guardada pelo mantenedor. Nunca a coloque no código, no ISO ou no repositório público.

Ative GitHub Pages para `forja-updates`, usando a branch `gh-pages` e a pasta raiz. Depois execute manualmente o workflow **Publish Forja application repository** no repositório `forja-iso`.

O workflow compila os PKGBUILDs Forja, assina cada pacote, gera e assina o banco Pacman e publica os arquivos estáticos em `forja-updates`.

## Instalação e confiança da chave

Depois da primeira publicação, baixe a chave pública `forja-repo.gpg`, confira o fingerprint por um canal confiável e importe/assine localmente:

```bash
gpg --show-keys --with-fingerprint forja-repo.gpg
sudo pacman-key --add forja-repo.gpg
sudo pacman-key --lsign-key FINGERPRINT_COMPLETO
```

Não execute a assinatura local antes de conferir o fingerprint.

O pacote `forja-repo-client` instala o comando `forja-repo check` e uma configuração Pacman independente. A consulta não atualiza nem instala pacotes. A implementação de atualização transacional dos aplicativos Forja será uma etapa posterior, depois de testar dependências e assinatura em VM.

## Estado atual

O cliente, PKGBUILD e workflow de publicação estão no branch de desenvolvimento. O repositório remoto continua sem pacotes até que os secrets sejam configurados e o workflow seja executado. O cliente não deve ser distribuído como pronto antes disso.
