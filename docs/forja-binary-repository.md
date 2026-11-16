# Repositório binário próprio da Forja OS

## Separação obrigatória

- Arch Linux mantém kernel, drivers, bibliotecas e pacotes oficiais.
- O repositório Forja contém somente aplicativos e componentes com nomes próprios da Forja.
- A Forja não publica versões substitutas de pacotes oficiais.
- O comando `forja-repo check` consulta somente o banco isolado `/var/lib/forja-repo`. Não executa atualização completa nem altera `/etc/pacman.conf`.

## Repositório remoto

O repositório GitHub `cn1988r-coder/forja-updates` existe, mas está vazio (sem commits). Ele será usado como hospedagem estática do repositório binário via GitHub Pages, branch `gh-pages`.

## Chave de assinatura

Crie uma chave GPG dedicada no computador e guarde a chave privada fora do repositório. Exemplo:

```bash
gpg --quick-generate-key "Forja OS Repository Signing <forja-repo@users.noreply.github.com>" ed25519 sign 3y
gpg --list-secret-keys --keyid-format long
gpg --armor --export-secret-keys FINGERPRINT_COMPLETO > forja-repo-private.asc
gpg --armor --export FINGERPRINT_COMPLETO > forja-repo.gpg
```

Não publique `forja-repo-private.asc`, não a coloque no ISO e não a envie em mensagens. Guarde-a em local seguro e apague cópias temporárias depois de configurar o secret.

## Secrets e publicação

No repositório `forja-iso`, configure os GitHub Actions secrets:

- `FORJA_UPDATES_TOKEN`: token fine-grained com acesso Contents: Read and write somente ao repositório `forja-updates`.
- `FORJA_GPG_PRIVATE_KEY`: conteúdo ASCII-armored da chave privada.
- `FORJA_GPG_KEY_ID`: fingerprint completo da chave.
- `FORJA_GPG_PASSPHRASE`: senha da chave, se houver.

Ative GitHub Pages para `forja-updates`, usando a branch `gh-pages` e a pasta raiz. Depois que o workflow estiver disponível no branch padrão do `forja-iso`, execute manualmente **Publish Forja application repository**.

O workflow compila os PKGBUILDs Forja, assina cada pacote, gera e assina o banco Pacman e publica os arquivos estáticos em `forja-updates`.

## Instalação e confiança da chave

Depois da primeira publicação, baixe `forja-repo.gpg`, confira o fingerprint por um canal confiável e importe/assine localmente:

```bash
gpg --show-keys --with-fingerprint forja-repo.gpg
sudo pacman-key --add forja-repo.gpg
sudo pacman-key --lsign-key FINGERPRINT_COMPLETO
```

Não execute a assinatura local antes de conferir o fingerprint.

O pacote `forja-repo-client` instala o comando `forja-repo check` e uma configuração Pacman independente. A consulta não atualiza nem instala pacotes. A implementação de atualização transacional dos aplicativos Forja será uma etapa posterior, depois de testar dependências e assinatura em VM.

## Estado atual

O cliente, PKGBUILD e workflow de publicação estão no branch de desenvolvimento. O repositório remoto continua sem pacotes até que os secrets sejam configurados e o workflow seja executado. O cliente não deve ser distribuído como pronto antes disso.