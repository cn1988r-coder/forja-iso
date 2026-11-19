# Pacman e repositório Forja OS

## Separação de responsabilidades

O Pacman normal em /etc/pacman.conf continua responsável pelo sistema Arch: kernel, bibliotecas, dependências, correções e atualizações de segurança.

O repositório Forja é separado e destinado somente a pacotes próprios da distribuição. O comando forja usa /etc/forja/pacman.conf, sem editar nem substituir a configuração normal do Pacman.

Pacotes publicados no repositório próprio devem usar o prefixo forja-. Dependências normais podem ser resolvidas pelos repositórios oficiais Arch listados na configuração isolada.

## Comandos

- sudo forja sync: sincroniza as bases pela configuração isolada.
- forja search TERMO: pesquisa nos repositórios dessa configuração.
- sudo forja install forja-pacote: instala pacote próprio Forja.
- sudo forja upgrade: atualiza somente pacotes instalados com prefixo forja-.
- sudo forja remove forja-pacote: remove pacote próprio.
- forja list: lista pacotes Forja instalados.

O comando não executa atualização geral do sistema. Para isso, o usuário continua usando o Pacman normal.

## Arquivos da imagem

- /usr/bin/forja
- /etc/forja/pacman.conf
- /etc/pacman.d/forja-mirrorlist
- /etc/forja/repository-key

## Estado operacional

A integração do comando e a configuração isolada estão preparadas no código-fonte. O repositório remoto ainda NÃO está operacional: faltam hospedagem, URL HTTPS real, chave pública de assinatura, fingerprint oficial e pacotes Forja publicados.

A configuração exige assinatura de banco de dados e pacotes (SigLevel = Required DatabaseRequired). O comando recusa operações remotas enquanto a URL e o fingerprint não estiverem configurados e a chave não estiver no chaveiro Pacman.

Para ativar futuramente:
1. Criar hospedagem compatível com repositório Pacman.
2. Publicar pacotes próprios forja-* e bancos assinados.
3. Definir o servidor HTTPS no arquivo /etc/pacman.d/forja-mirrorlist.
4. Instalar a chave pública oficial no chaveiro Pacman e assiná-la localmente após conferir o fingerprint por canal confiável.
5. Registrar o fingerprint completo em /etc/forja/repository-key.

Não aceitar automaticamente chaves ou fingerprints. A chave oficial deve ser confirmada pelo responsável pelo projeto.

## Limitações atuais

- Sem servidor configurado.
- Sem chave oficial ou fingerprint.
- Sem pacotes Forja publicados.
- Operações remotas permanecem bloqueadas até esses itens existirem.
- A implementação ainda precisa de testes reais em Arch/Forja antes de ser considerada pronta para uso.
