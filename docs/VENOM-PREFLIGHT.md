# VENOM OS: preflight obrigatório

O comando `python scripts/venom-preflight.py` executa a auditoria estática antes de qualquer compilação.

## Escopo

- Estrutura obrigatória do perfil Archiso e arquivos de boot BIOS/Syslinux e UEFI/GRUB.
- Manifestos separados do sistema live e da instalação, duplicatas, pacotes essenciais e disponibilidade consultável via Pacman.
- Configuração do LightDM, sessão XFCE, autologin e readiness.
- Estrutura e ordenação das units systemd, com detecção de ciclos locais.
- XMLs de configuração XFCE, sintaxe Bash/Python, ShellCheck e YAML quando as ferramentas estão disponíveis.
- Regras de arquitetura: somente base Arch oficial, sem dependências finais de Manjaro, EndeavourOS ou Calamares.
- Proteção dos gatilhos de build e avisos de segurança.

## Resultado

- VERDE: verificação aprovada.
- AMARELO: aviso que exige avaliação.
- VERMELHO: erro que reprova e bloqueia o build.
- CINZA: verificação inconclusiva ou que depende de ambiente externo.

O processo termina com código diferente de zero quando encontra erros. Não faz correções automáticas nem altera configurações.

## Limites

A auditoria estática não prova que a ISO inicializa. Boot BIOS/UEFI, LightDM, sessão XFCE visível e funcionamento de áudio, rede, Bluetooth, GPU e periféricos exigem validação pós-build em máquina virtual e hardware real. Uma auditoria verde libera apenas a tentativa de compilação, não certifica a ISO.

O workflow de build executa este verificador imediatamente após o checkout e antes de qualquer etapa de compilação. O workflow de validação estática também o executa. O preflight não altera o arquivo `.github/trigger-final-build.txt` nem dispara workflows de build.
