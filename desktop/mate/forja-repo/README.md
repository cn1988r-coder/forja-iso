# Cliente do repositório binário Forja

O comando `forja-repo check` sincroniza e consulta apenas a base de dados do
repositório `[forja]`, usando um `pacman.conf` e um DBPath exclusivos em
`/var/lib/forja-repo`. Não chama `pacman -Syu`, não atualiza pacotes oficiais
e não altera a configuração global `/etc/pacman.conf`.

O cliente só lista atualizações de pacotes Forja que já estejam instalados.
A instalação/atualização efetiva dos pacotes Forja será adicionada depois de
validarmos a assinatura, resolução de dependências e transações isoladas.

O repositório remoto usa GitHub Pages em
`https://cn1988r-coder.github.io/forja-updates/$arch`. O cliente exige
assinatura de banco de dados e pacotes. A chave pública deverá ser importada e
assinada localmente no sistema antes da primeira consulta.

O cliente e o repositório ainda estão em preparação. Até o primeiro deploy
assinado e a instalação do pacote cliente, o comando não está disponível.
