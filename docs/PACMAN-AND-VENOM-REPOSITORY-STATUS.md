# Estado do Pacman e do repositório VENON

Registro atualizado em 20/11/2026.

## Arquitetura

- O Pacman oficial é o único gerenciador de atualizações normais do sistema e dos aplicativos Arch.
- A atualização geral é feita pelo usuário com `sudo pacman -Syu`.
- A configuração global do Pacman utiliza somente os repositórios oficiais Arch.
- VENON é um mecanismo próprio, totalmente independente do Pacman.
- VENON não chama `pacman` ou `pacman-key`, não altera o banco de pacotes do Pacman e não participa das atualizações normais.
- Nenhum serviço ou timer ativa VENON automaticamente.

## Comandos definitivos

- `venon-upgrade`: consulta e lista atualizações VENON disponíveis. Não instala.
- `venon-update`: baixa e instala atualizações VENON somente após confirmação explícita.

## Estado atual

Os dois comandos estão presentes como bloqueios seguros. Eles não consultam nem instalam pacotes, pois o mecanismo independente VENON ainda não foi implementado.

Ainda faltam hospedagem, protocolo de metadados assinados, chave pública própria, verificação criptográfica independente, formato de pacote e mecanismo seguro de instalação e recuperação.

## Critério para habilitação

O VENON só poderá ser ativado depois de implementar e testar:
- repositório HTTPS próprio;
- metadados assinados por chave VENON independente;
- verificação criptográfica sem Pacman ou pacman-key;
- formato de pacote próprio com hashes, permissões e regras de instalação e remoção;
- mecanismo de recuperação contra interrupções e conflitos;
- confirmação explícita antes de aplicar atualizações.

Não usar VENON para administrar pacotes Arch ou dependências do sistema. Essas tarefas permanecem exclusivamente com o Pacman.
