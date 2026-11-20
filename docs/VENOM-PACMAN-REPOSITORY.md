# Arquitetura de atualização: Pacman e VENON

## Pacman

O Pacman oficial administra o sistema e os aplicativos dos repositórios oficiais Arch. O comando de atualização completa é:

```bash
sudo pacman -Syu
```

O repositório VENON nunca será adicionado ao `/etc/pacman.conf`. A configuração global deve conter somente `core`, `extra` e, quando habilitado, `multilib`, usando a mirrorlist oficial Arch.

## VENON

VENON é um mecanismo independente. Não é um repositório Pacman, não usa libalpm, não chama `pacman` ou `pacman-key`, não usa chaveiro Pacman e não compartilha o banco de pacotes do sistema.

Comandos:

- `venon-update`: consulta e lista atualizações disponíveis, sem instalar.
- `venon-upgrade`: baixa e instala atualizações somente após confirmação explícita.

Ambos são acionados manualmente. Não haverá ativação automática por boot, serviço ou timer.

## Estado presente

Os comandos estão instalados como bloqueios seguros, pois o serviço independente ainda não foi desenvolvido. Eles informam que o repositório não está configurado e não fazem alterações. Não existe servidor, formato de metadados, verificador criptográfico ou instalador VENON operacional neste momento.

A implementação futura deverá incluir:
1. Repositório HTTPS próprio e metadados assinados por chave VENON independente.
2. Verificação criptográfica sem Pacman/pacman-key.
3. Formato de pacote próprio, com lista de arquivos, hashes, permissões e regras de instalação/remoção.
4. Instalação transacional ou mecanismo de recuperação para evitar deixar o sistema parcialmente alterado.
5. Confirmação explícita antes de baixar e aplicar atualizações.
6. Testes de assinatura inválida, pacote corrompido, interrupção, rollback e conflito de arquivos.

Não usar os comandos para administrar pacotes Arch ou dependências do sistema. Essas tarefas permanecem exclusivamente com Pacman.
