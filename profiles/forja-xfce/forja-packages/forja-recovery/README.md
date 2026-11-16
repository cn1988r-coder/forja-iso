# Forja Recovery

Primeiro componente funcional da ferramenta oficial de recuperação do Forja OS.

## Recursos desta versão inicial

- Diagnóstico somente de leitura: sistema de arquivos raiz, Snapper, integridade da base local do Pacman, GRUB, kernel, initramfs e ferramentas Btrfs.
- Listagem de snapshots da configuração Snapper chamada `root`.
- Criação manual de snapshot da raiz, somente quando a raiz é Btrfs e Snapper já está configurado.
- Interface GTK3 e comando de terminal.

## Limites explícitos

Esta versão **não executa rollback**, não altera o GRUB, não reinstala pacotes automaticamente e não repara initramfs. Essas ações dependem de validar o layout Btrfs produzido pelo Calamares, a configuração de boot e o comportamento de recuperação em VM. A interface não deve oferecer ações destrutivas antes desses testes.

A criação de snapshots não inclui automaticamente /home. A política real de subvolumes depende da configuração de instalação; não se deve presumir que /home esteja separado.

## Comandos

- `forja-recovery`: abre a interface.
- `forja-recovery-cli diagnose`: diagnóstico JSON.
- `forja-recovery-cli snapshots`: lista snapshots.
- `sudo forja-recovery-cli create-snapshot --description "Antes de atualizar"`: cria snapshot manual.
