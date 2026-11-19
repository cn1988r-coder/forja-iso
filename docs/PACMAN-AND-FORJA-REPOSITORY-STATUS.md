# Estado do Pacman e do repositório Forja

Data do registro: 19/11/2026

## Decisão de arquitetura

- O Pacman do Arch Linux continua responsável pelas atualizações normais do sistema: kernel, bibliotecas, dependências, correções e segurança.
- O repositório Forja contém somente pacotes próprios da distribuição, identificados pelo prefixo forja-.
- O repositório Forja não substitui nem interfere na configuração normal do Pacman.
- O usuário acessa a interface do repositório digitando somente sudo forja no terminal.

## Implementado no código-fonte

- Cliente em build/airootfs/usr/bin/forja.
- O comando sem argumentos sudo forja abre um menu interativo.
- O menu oferece sincronização, pesquisa, instalação, atualização seletiva, remoção e listagem de pacotes Forja.
- A interface não exige que o usuário memorize subcomandos.
- Configuração isolada em build/airootfs/etc/forja/pacman.conf.
- Arquivo de mirrorlist próprio em build/airootfs/etc/pacman.d/forja-mirrorlist.
- Arquivo reservado ao fingerprint em build/airootfs/etc/forja/repository-key.
- Script de build copia esses arquivos para a imagem e aplica permissão executável ao cliente.
- Instalação e remoção direta pelo cliente são limitadas a nomes forja-*.
- A atualização seletiva consulta e atualiza somente pacotes instalados com prefixo forja-; não executa atualização geral do sistema.
- O cliente não modifica /etc/pacman.conf.

## Ainda não operacional

O serviço remoto ainda não está pronto. Faltam:
- hospedagem compatível com repositório Pacman;
- URL HTTPS real;
- chave pública oficial e fingerprint confirmado por canal confiável;
- pacotes Forja publicados e bancos de dados assinados.

O cliente mantém operações remotas bloqueadas enquanto a URL e o fingerprint não estiverem configurados e a chave não estiver no chaveiro Pacman. A configuração exige assinaturas de banco de dados e pacotes.

## Próximos passos

1. Definir a hospedagem e o endereço HTTPS.
2. Gerar e proteger a chave de assinatura do repositório.
3. Publicar os primeiros pacotes próprios com prefixo forja-.
4. Configurar o fingerprint público no sistema após conferência independente.
5. Em etapa autorizada, realizar testes reais do menu, instalação, atualização seletiva e isolamento da configuração.

## Limite desta etapa

A interface de menu foi registrada na branch de trabalho. Não foram executados build, validação, testes de integração ou geração de ISO. Portanto, o menu está implementado no código-fonte, mas ainda não foi comprovado em execução e o repositório remoto não está ativo.
