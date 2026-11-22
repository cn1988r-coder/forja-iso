# Construção da VENOM OS

O perfil ativo é `manjaro/venom-mate`. Use os perfis oficiais Manjaro ISO Profiles e `buildiso` de manjaro-tools compatível com mt-0.15.

O conteúdo antigo de `build/` é legado Archiso e não pode construir a VENOM Manjaro.

Calamares deve vir da lista compartilhada oficial Manjaro `shared/Packages-Live`. A versão é resolvida pelo repositório Manjaro selecionado. Não baixar nem compilar Calamares upstream.

## Validação e compilação

- `scripts/prepare-manjaro-profile.sh`: sincroniza os overlays VENOM para a sessão live e o sistema instalado.
- `scripts/validate-manjaro-profile.sh`: valida estrutura e arquivos localmente.
- `scripts/validate-manjaro-build.sh`: em ambiente Manjaro, executa `buildiso -x` para resolver/instalar pacotes sem gerar ISO.
- `scripts/build-manjaro-iso.sh`: só permite a geração completa com `VENOM_ISO_APPROVED=YES`.

Ordem obrigatória: validação estrutural, resolução real de pacotes, inspeção do Calamares gerado, testes gráficos e instalação em VM UEFI/BIOS. Só depois de tudo aprovado e com autorização expressa pode ser gerada a ISO.

A validação estática não substitui resolução de pacotes, boot ou instalação.
