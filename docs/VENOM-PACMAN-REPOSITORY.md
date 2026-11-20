# Arquitetura de atualização: Pacman e VENON

## Pacman

O Pacman oficial administra o sistema e os aplicativos dos repositórios oficiais Arch. O comando de atualização completa é:

```bash
sudo pacman -Syu
```

A configuração global do Pacman deve conter somente os repositórios oficiais Arch.

## VENON

VENON é um mecanismo independente. Não é um repositório Pacman, não usa libalpm, não chama `pacman` ou `pacman-key`, não usa o chaveiro Pacman e não compartilha o banco de pacotes do sistema.

Comandos:

- `venon-upgrade`: consulta e lista atualizações disponíveis, sem instalar.
- `venon-update`: baixa e instala atualizações somente após confirmação explícita.

Ambos são acionados manualmente. Não haverá ativação automática por boot, serviço ou timer.

## Estado atual

Os comandos estão instalados como bloqueios seguros, pois o serviço independente ainda não foi desenvolvido. Eles informam que a infraestrutura não está configurada e não fazem alterações. Ainda não existe servidor, formato de metadados, verificador criptográfico ou instalador VENON operacional.

A implementação futura deverá incluir:
1. Repositório HTTPS próprio e metadados assinados por chave VENON independente.
2. Verificação criptográfica sem Pacman ou pacman-key.
3. Formato de pacote próprio, com lista de arquivos, hashes, permissões e regras de instalação e remoção.
4. Mecanismo transacional ou recuperação para impedir que interrupções deixem o sistema parcialmente alterado.
5. Confirmação explícita antes de baixar e aplicar atualizações.
6. Testes de assinatura inválida, pacote corrompido, interrupção, recuperação e conflito de arquivos.

Não usar os comandos para administrar pacotes Arch ou dependências do sistema. Essas tarefas permanecem exclusivamente com Pacman.
