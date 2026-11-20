# Estado do Pacman e do repositório VENON

Registro atualizado em 20/11/2026.

## Arquitetura obrigatória

- O Pacman oficial é o único gerenciador de atualizações normais do sistema e dos aplicativos Arch.
- A atualização geral é feita pelo usuário com `sudo pacman -Syu`.
- A configuração global `/etc/pacman.conf` contém somente os repositórios oficiais Arch.
- VENON é um mecanismo próprio, totalmente independente do Pacman.
- VENON não chama `pacman` ou `pacman-key`, não usa configuração isolada do Pacman e não altera o banco de pacotes do Pacman.
- Nenhum serviço ou timer ativa VENON automaticamente.

## Comandos definitivos

- `venon-update`: consulta e lista atualizações VENON disponíveis. Não instala.
- `venon-upgrade`: baixa e instala atualizações VENON após confirmação explícita.

## Correções feitas no código

- Removido o cliente legado `/usr/bin/venom`, que utilizava Pacman e pacman-key.
- Removidos `/etc/venom/pacman.conf`, o arquivo de fingerprint legado e a mirrorlist VENOM colocada em `/etc/pacman.d`.
- Adicionados os comandos `/usr/bin/venon-update` e `/usr/bin/venon-upgrade`.
- Atualizado o script de preparação da ISO para instalar somente os dois comandos novos.
- Atualizada a documentação para não descrever o menu antigo nem uma falsa integração com Pacman.
- Atualizado o validador estático para rejeitar a presença do cliente/configuração antigos e qualquer chamada ao Pacman dentro dos comandos VENON.

## Limite operacional explícito

Os dois comandos estão presentes como bloqueios seguros. Eles não consultam nem instalam pacotes ainda, porque a infraestrutura independente VENON será construída em etapa posterior, depois da instalação e validação da VENOM OS. Até essa infraestrutura existir, os comandos encerram sem modificar o sistema.

Ainda faltam hospedagem, protocolo de metadados assinados, chave pública própria, verificação criptográfica independente, formato de pacote e instalador próprio. Não declarar VENON operacional antes de implementar e testar esses componentes.

## Validação

Nenhuma validação automatizada, compilação, workflow ou instalação foi executada nesta alteração.
