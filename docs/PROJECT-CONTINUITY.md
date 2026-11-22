# Continuidade técnica oficial: VENOM OS

## Regra principal do projeto

A VENOM OS possui **um único instalador oficial**: o aplicativo próprio em C + ncurses, em modo texto (TUI), localizado em `installer/src/`.

- O pendrive inicia diretamente o instalador na tty1.
- Não existe sessão Live nem desktop de demonstração.
- Não criar, integrar ou manter um segundo frontend/instalador.
- As únicas edições oferecidas são VENOM OS XFCE e VENOM OS MATE.
- O fluxo de instalação seleciona o disco, cria a conta, apresenta a revisão e exige a confirmação literal `APAGAR` antes de apagar o disco inteiro.

## Inicialização da mídia

- Perfil Archiso: `build/`.
- BIOS: Syslinux.
- UEFI: GRUB.
- O perfil configura a inicialização direta do TUI na tty1.
- A configuração BIOS deve conter `/syslinux/isolinux.cfg`, selecionar `DEFAULT venom` e incluir `archiso_sys-linux.cfg`.
- O script de build agora extrai e valida `isolinux.cfg` de dentro da ISO antes de publicar o artefato. Se o arquivo estiver ausente ou apontar para outra entrada, a compilação falha.

## Instalação e edições

A mídia inclui o bundle local de pacotes e dependências para XFCE e MATE. O backend em `build/airootfs/usr/lib/venom/install-system` aplica o plano, configura Btrfs, usuário, locale brasileiro, LightDM, initramfs e GRUB. A lista de aplicativos é a mesma nas duas edições, exceto os pacotes necessários ao ambiente desktop.

## Validação automatizada

O workflow `.github/workflows/build-arch-iso.yml`:
1. Compila o TUI com Meson.
2. Executa os testes unitários.
3. Valida os scripts, o perfil e as configurações XFCE/MATE.
4. Prepara e valida o bundle de pacotes offline.
5. Gera a ISO com Archiso.
6. Verifica a configuração Syslinux dentro da ISO.
7. Publica a ISO e o checksum como artefatos.

O validador também impede que o workflow volte a instalar dependências de outro frontend.

## Estado conhecido em 22/11/2026

A compilação anterior gerou `venom-2026.11.22-x86_64.iso`, mas a foto enviada pelo usuário mostrou o ISOLINUX parado em `WARNING: No configuration file found` e no prompt `boot:`. Portanto, o boot BIOS dessa imagem ainda não está comprovado e essa ISO não deve ser declarada pronta para uso.

As alterações seguintes corrigem a documentação contraditória, removem as dependências gráficas desnecessárias do workflow e adicionam uma verificação obrigatória do arquivo `isolinux.cfg` na ISO. Ainda é necessário concluir o workflow atualizado e confirmar o boot BIOS/UEFI e a instalação em VM antes de entregar a imagem como final.
