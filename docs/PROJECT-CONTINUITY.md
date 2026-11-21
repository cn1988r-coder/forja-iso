# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Arquitetura definitiva

- Sistema: VENOM OS.
- Base: Arch Linux oficial.
- Repositórios: somente os oficiais do Arch Linux.
- Desktop: MATE.
- Gerenciador de login: LightDM.
- Idioma: Português do Brasil.
- Teclado: Brasil ABNT2.
- Mídia: perfil próprio baseado no Archiso oficial.
- Instalador: próprio, C + GTK4, backend separado.
- **Instalação exclusivamente online:** pacstrap/Pacman baixa os pacotes diretamente dos repositórios oficiais Arch.
- Não existe instalação offline nem cópia do sistema live para o disco.
- Calamares, EndeavourOS e Manjaro não fazem parte da arquitetura final.

## Branch e repositório

- Repositório: cn1988r-coder/forja-iso.
- Branch de trabalho: optimize/venom-iso-size.
- main e as demais branches permanecem preservadas.

## Correção arquitetural aplicada

O backend anterior apagava o disco, copiava a árvore do sistema live com rsync e configurava essa cópia como instalação. Essa abordagem foi removida.

O backend atual:
- exige conectividade HTTPS com o mirror oficial do Arch;
- usa a configuração oficial Arch em /etc/pacman.conf;
- instala os pacotes de build/packages.x86_64 com pacstrap;
- não copia a raiz live e não possui caminho alternativo offline;
- configura sistema, usuário, locale, serviços, GRUB e initramfs após a instalação dos pacotes.

O Meson instala o manifest de pacotes em /usr/share/venom/packages.x86_64 para uso pelo backend na sessão live.

## Pendências de validação

1. Executar ShellCheck e bash -n no backend atualizado.
2. Compilar o frontend C/GTK4.
3. Gerar a ISO com mkarchiso.
4. Testar o boot live BIOS e UEFI.
5. Executar instalação real em discos virtuais descartáveis, conectados à internet, nos modos BIOS e UEFI.
6. Simular ausência de rede e indisponibilidade do mirror: o instalador deve falhar com mensagem clara sem tentar instalar offline.
7. Validar o primeiro boot do sistema instalado, MATE, LightDM, rede, áudio, Bluetooth e persistência.
8. Implementar particionamento personalizado, se mantido como requisito do produto.

Não declarar build, testes ou instalação concluídos sem logs e artefatos verificáveis.

## Atualizações do sistema

- Pacman administra atualizações normais: sudo pacman -Syu.
- VENON é separado do Pacman e acionado manualmente.
- venon-upgrade apenas consulta/lista atualizações disponíveis.
- venon-update instala atualizações VENON somente após confirmação explícita.
- Não criar timers nem atualizações automáticas do VENON.

## Referência histórica

A ISO VENOM OS Manjaro MATE #21 e o script manjaro-mate-dark-complete.sh permanecem como referência histórica de desktop, sem alteração e sem serem usados como base da edição Arch.
