# Construção da VENOM OS

O perfil ativo está em `manjaro/venom-mate`. Use os perfis oficiais Manjaro ISO Profiles e `buildiso` de manjaro-tools compatível com mt-0.15.

Os antigos arquivos Archiso e o instalador C/GTK4/TUI foram retirados do caminho ativo. A VENOM não deve usar Archiso, mkarchiso, listas de pacotes Arch ou o instalador próprio antigo.

Calamares deve vir da lista compartilhada oficial Manjaro `shared/Packages-Live`. A versão é resolvida pelo repositório Manjaro selecionado. Não baixar nem compilar Calamares upstream.

## Validação e compilação

- `scripts/prepare-manjaro-profile.sh`: sincroniza os overlays VENOM para a sessão live e o sistema instalado.
- `scripts/validate-manjaro-profile.sh`: valida estrutura e arquivos.
- `scripts/test-manjaro-profile-links.sh`: confere os symlinks e a lista Calamares contra o repositório oficial Manjaro.
- `scripts/validate-manjaro-build.sh`: em ambiente Manjaro, executa `buildiso -x` para resolver/instalar pacotes sem gerar ISO.
- `scripts/build-manjaro-iso.sh`: só permite a geração completa com `VENOM_ISO_APPROVED=YES`.

Ordem obrigatória: validação estrutural, resolução real de pacotes, inspeção da configuração Calamares gerada, testes gráficos e instalação em VM UEFI/BIOS. Só depois de tudo aprovado e com autorização expressa pode ser gerada a ISO.

A validação estática não substitui resolução de pacotes, boot ou instalação.
