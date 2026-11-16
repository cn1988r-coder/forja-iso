# Forja Recovery

Primeiro componente funcional da ferramenta oficial de recuperação do Forja OS.

## Recursos desta versão inicial

- Diagnóstico somente de leitura: sistema de arquivos raiz, Snapper, integridade da base local do Pacman, GRUB, kernel, initramfs e ferramentas Btrfs.
- Listagem de snapshots da configuração Snapper chamada `root`.
- Criação manual de snapshot da raiz, somente quando a raiz é Btrfs e Snapper já está configurado.
- Preparação de rollback via Snapper com número do snapshot e confirmação explícita no terminal.
- Interface GTK3 e comando de terminal.

## Limites explícitos

O rollback exige `--confirm`, o número de um snapshot existente e uma raiz Btrfs montada pelo subvolume padrão. O Forja Recovery verifica `/etc/fstab` e `rootflags` e bloqueia a operação quando encontra um subvolume raiz fixado, evitando um rollback que não seria aplicado no próximo boot. O fluxo completo de rollback, boot e retorno ao sistema deve ser testado em VM antes de distribuir a ISO. Esta ferramenta não reinstala pacotes automaticamente nem repara initramfs.

A criação de snapshots não inclui automaticamente /home. A política real de subvolumes depende da configuração de instalação; não se deve presumir que /home esteja separado.

## Comandos

- `forja-recovery`: abre a interface.
- `forja-recovery-cli diagnose`: diagnóstico JSON.
- `forja-recovery-cli snapshots`: lista snapshots.
- `sudo forja-recovery-cli create-snapshot --description "Antes de atualizar"`: cria snapshot manual.
- `sudo forja-recovery-cli rollback --snapshot 12 --confirm`: prepara rollback para o snapshot 12; confira o número antes de confirmar.
