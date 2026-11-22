# Construção da VENOM OS

O perfil ativo é `manjaro/venom-mate`. Use os perfis oficiais Manjaro ISO Profiles e `buildiso` de manjaro-tools compatível com mt-0.15.

O conteúdo antigo de `build/` é legado Archiso e não pode construir a VENOM Manjaro.

Calamares deve vir da lista compartilhada oficial Manjaro `shared/Packages-Live`. A versão é resolvida pelo repositório Manjaro selecionado. Não baixar nem compilar Calamares upstream.

## Ordem obrigatória
1. Preparar o perfil na árvore oficial Manjaro.
2. Validar estrutura, symlinks e listas de pacotes.
3. Executar `buildiso -p venom-mate -x` em ambiente Manjaro para resolver/instalar pacotes sem gerar ISO.
4. Inspecionar a configuração Calamares gerada.
5. Testar MATE e indicadores em VM.
6. Testar instalação e primeiro boot em VM UEFI e BIOS.
7. Só então, com autorização expressa, gerar a ISO.

Validação estática não substitui resolução de pacotes, boot ou instalação.
