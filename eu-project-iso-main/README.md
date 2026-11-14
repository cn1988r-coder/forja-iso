# Forja de ISO

A Forja prepara imagens ISO x86_64 de Arch Linux e Manjaro na infraestrutura de CI do GitLab. O computador do usuário é usado para configurar a compilação e baixar o resultado, não para compilar.

## Opções disponíveis no pipeline

- Distribuição: Arch Linux ou Manjaro.
- Ambiente gráfico: XFCE, MATE, GNOME ou KDE Plasma.
- Kernel: mais recente estável ou LTS.

No GitLab, abra **Build > Pipelines > New pipeline** e selecione os três inputs. A compilação não é disparada em cada push: pushes executam apenas a validação de fontes.

## Compilação e entrega

O job de build usa runner Linux com Docker-in-Docker, prepara o ambiente isolado, gera a ISO, calcula SHA-256 e publica o arquivo no Generic Package Registry do projeto, organizado pelo ID do pipeline. Os artifacts ficam disponíveis por sete dias.

## Detalhes por base

- Arch: usa o perfil oficial `archiso/releng`, substitui o kernel conforme a opção e instala o desktop/gerenciador de login escolhido.
- Manjaro: usa `manjaro-tools` e os perfis oficiais atuais XFCE, GNOME e KDE. O perfil MATE parte da estrutura oficial XFCE, mas remove componentes de sessão/branding XFCE, instala o núcleo MATE e usa utilitários XFCE individuais apenas como substitutos quando um aplicativo MATE opcional não existe. LightDM é configurado explicitamente para iniciar a sessão MATE. O preflight entende linhas `>repo pacote`, percorre listas compartilhadas, preserva placeholders `KERNEL-*` e interrompe a build se faltar componente essencial de boot, MATE, LightDM, rede ou Bluetooth. O kernel é resolvido pela versão estável/LTS upstream e precisa existir nos repositórios estáveis Manjaro.

## Loja de aplicativos Shelly

As imagens Arch e Manjaro recebem Shelly-ALPM com interface GTK4 e CLI, além do backend opcional de Flatpak. O pacote é compilado dentro do ambiente da própria distribuição, usando a receita oficial upstream fixada no commit `9adb7c7c725cba40f60f0af546194a0449a70706` e Zig 0.17.1 verificado por SHA-256. Durante a build, um repositório HTTP temporário fornece os pacotes ao instalador; ele não depende de pacotes CachyOS nem de binários pré-compilados de outra distribuição.

## Limites de validação

A validação de fontes verifica sintaxe e presença dos scripts. A geração real ainda depende de runner disponível, rede, imagens e repositórios externos, permissões de Docker-in-Docker e compatibilidade atual das ferramentas oficiais. Uma ISO produzida e acompanhada de SHA-256 não está automaticamente certificada para boot: é necessário testar BIOS e UEFI e verificar o instalador em máquina virtual.
