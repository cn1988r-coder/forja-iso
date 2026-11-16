# Forja Recovery

Interface própria do Forja OS para diagnóstico e acesso à recuperação do sistema.

## Responsabilidades

- O **Timeshift** é o único gerenciador de snapshots e a ferramenta oficial de restauração.
- O **GRUB-Btrfs** disponibiliza snapshots compatíveis no menu do GRUB.
- O Forja Recovery executa diagnóstico, lista snapshots, permite criar snapshot manual e abre a interface oficial do Timeshift para restaurar.
- O Forja Recovery não implementa rollback próprio nem altera diretamente o subvolume padrão do Btrfs.

## Comandos

- `forja-recovery`: abre a interface.
- `forja-recovery-cli diagnose`: diagnóstico JSON.
- `forja-recovery-cli snapshots`: lista snapshots Timeshift.
- `forja-recovery-cli create-snapshot --description "Antes de atualizar"`: cria snapshot com elevação administrativa.
- `forja-recovery-cli open-timeshift`: abre a interface gráfica oficial do Timeshift.

## Limites

O Timeshift em modo Btrfs exige o layout compatível com Ubuntu: raiz `@` e, opcionalmente, `@home`. A entrada de raiz no `/etc/fstab` não pode fixar `subvolid=`, pois a restauração precisa poder trocar a raiz ativa. O snapshot root não inclui /home nesta configuração. A restauração deve ser feita pelo Timeshift, com revisão do dispositivo e do snapshot escolhido. O ciclo completo de restauração e boot ainda precisa ser testado em máquina virtual antes de distribuir a ISO.
