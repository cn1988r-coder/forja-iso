# Infraestrutura de compilação VENOM OS

## Objetivo

Reproduzir, tanto quanto possível, a organização de compilação usada pelo BigCommunity: pipeline por etapas, ambiente previsível, preflight, logs, manifesto de pacotes, checksums e artefatos identificáveis. A adaptação preserva a regra da VENOM de usar a cadeia oficial do Manjaro para o sistema e suas ferramentas.

## Ferramentas adotadas

| Ferramenta | Papel na VENOM |
|---|---|
| GitHub Actions | Orquestrar as etapas, registrar resultados e guardar artefatos. |
| Runner Manjaro self-hosted | Executar a compilação em um sistema Manjaro real, sem instalar ferramentas Arch/upstream em Ubuntu. |
| manjaro-tools / buildiso | Resolver dependências e construir a ISO a partir do perfil. |
| Manjaro ISO Profiles | Fornecer a estrutura compartilhada oficial, incluindo listas e overlays base. |
| ShellCheck | Verificar os scripts antes de executar operações de build. |
| Manifesto de pacotes | Registrar o conjunto de pacotes gerado pelo buildiso. |
| MD5, SHA-256 e SHA-512 | Registrar checksums para detectar corrupção ou alteração dos artefatos. |
| GitHub Actions Artifacts | Guardar logs, ISO, manifesto e checksums com retenção definida. |

## Fluxo

1. Confirmar que o runner é Manjaro e que buildiso, manjaro-tools-iso, manjaro-keyring e linux618 estão instalados.
2. Executar ShellCheck e as validações estruturais do perfil.
3. Sincronizar o perfil VENOM com os overlays live e instalado.
4. Atualizar os perfis oficiais com buildiso -i.
5. Executar buildiso -p venom-mate -b stable -k linux618 -x para resolver e instalar os pacotes no ambiente de build sem produzir ISO.
6. Somente quando a opção manual de geração for selecionada, executar a compilação completa.
7. Exigir exatamente uma ISO e um manifesto de pacotes.
8. Calcular MD5, SHA-256 e SHA-512, registrar branch, commit, kernel e versão de manjaro-tools-iso.
9. Guardar logs e artefatos no GitHub Actions.

O workflow está em `.github/workflows/build-manjaro-iso.yml`. A opção de geração da ISO começa desativada; o padrão é executar somente preflight e resolução de dependências.

## Diferenças deliberadas em relação ao BigCommunity

O projeto BigCommunity usa componentes próprios, como GitRepo e uma imagem Docker comunitária. Eles não são componentes oficiais do Manjaro. A VENOM não os incorpora diretamente porque a regra de origem do projeto proíbe ferramentas, pacotes e repositórios externos à cadeia oficial Manjaro.

A arquitetura de automação, logs, manifesto, checksums e publicação é reproduzida no próprio pipeline da VENOM. O uso de container fica reservado para uma etapa posterior de validação técnica com uma imagem-base mantida pelo próprio Manjaro; não se deve presumir que buildiso funcione dentro de Docker sem validar acesso a loop devices, montagem, systemd-nspawn e permissões. Até essa validação, o runner Manjaro nativo é o ambiente de compilação.

## Limites atuais

- O workflow requer um runner self-hosted com os rótulos `self-hosted`, `linux`, `manjaro` e `x64`.
- A existência do workflow não comprova que esse runner esteja registrado ou disponível.
- O preflight `buildiso -x` não gera uma ISO.
- A compilação completa ainda não foi executada por este workflow.
- Checksums e manifesto verificam identidade e integridade dos artefatos, não comprovam boot ou instalação.
- A ISO só poderá ser considerada validada depois de testes reais de boot, sessão MATE, Calamares, instalação e primeiro boot em máquinas virtuais BIOS e UEFI.
