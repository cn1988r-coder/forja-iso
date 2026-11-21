# Perfil Archiso da VENOM OS

Este diretório contém a base em desenvolvimento da mídia VENOM OS, diretamente sobre o Arch Linux oficial e usando o Archiso oficial.

## Estado atual

**Perfil incompleto. Não está liberado para declarar uma ISO pronta.**

Os manifests de pacotes e algumas configurações do sistema já existem, mas a estrutura ainda não corresponde a um perfil Archiso completo e validado. A presença de `profiledef.sh`, `pacman.conf` e listas de pacotes não basta para produzir uma mídia inicializável.

## Regras obrigatórias

- Usar somente Arch Linux oficial, seus repositórios e ferramentas oficiais.
- Não usar Manjaro, EndeavourOS, Calamares ou componentes de outras distribuições.
- Manter MATE + LightDM.
- Manter Português do Brasil e teclado Brasil ABNT2.
- Não iniciar build/publicação de ISO sem autorização expressa do usuário.
- Não declarar o perfil válido sem executar validações reais com Archiso.

## Bloqueios conhecidos

1. Completar a estrutura de boot BIOS/UEFI exigida pelo Archiso.
2. Revisar os manifests e confirmar a existência dos pacotes nos repositórios oficiais atuais.
3. Completar a configuração do ambiente Live e os serviços necessários.
4. Integrar o instalador próprio somente quando o backend estiver implementado e testado.
5. Validar a mídia em VM antes de qualquer declaração de conclusão.

O perfil deve permanecer separado de qualquer pipeline histórico baseado em Manjaro.
