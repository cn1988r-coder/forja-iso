# Forja OS

A Forja OS é uma distribuição baseada em **Manjaro Stable**, para **x86_64**, com ambiente gráfico único **MATE** e kernel LTS.

## Especificação

- Base: Manjaro Linux Stable, rolling release.
- MHWD habilitado no Live e no Calamares, com drivers livres e proprietários disponíveis para detecção de hardware.
- Identidade do sistema: Forja OS, mantendo o identificador interno Manjaro para compatibilidade.
- Desktop: MATE.
- Inicialização: LightDM.
- Instalador: Calamares oficial do Manjaro, com identidade visual Forja OS e regras de partição próprias.
- Sistema de arquivos padrão: BTRFS; mountpoints de dados padrão (/, /home, /boot, /var, /srv, /opt e /data) restritos a BTRFS.
- Partição EFI: FAT32.
- Idioma padrão: português do Brasil.
- Teclado padrão: brasileiro ABNT2.
- Fuso horário padrão: America/Sao_Paulo.
- Gerenciador de pacotes: Pacman e Pamac.
- Fontes no Pamac: repositórios oficiais Manjaro (core, extra e multilib) e AUR habilitados; Flatpak e Snap desativados.

## Aparência

- Tema GTK e MATE: Materia Dark.
- Ícones: Papirus Dark.
- Cursor: Bibata Modern Classic.
- Papel de parede oficial Forja OS e brasão Forja no menu, na tela de login e no instalador.
- Dois painéis MATE nativos: barra superior de 32 px e barra inferior de 40 px, com menu, atalhos, janelas abertas, bandeja de sistema, volume e relógio. Não há dock externo.
- Fastfetch com brasão industrial Forja, campos em azul e valores em cinza.
- Preferências visuais aplicadas por GTK, dconf e configurações do usuário.
- Marco: encaixe lateral/cantos habilitado; encaixe pelo topo e ciclos desativados. Animações GTK e do painel desativadas; compositor mantido para reprodução de vídeo.
- Brilho: padrão inicial de 50% na alimentação AC; alterações feitas pelo usuário permanecem salvas no dconf pessoal e não são redefinidas no login.
- Boot silencioso com tela preta durante o carregamento. Não utiliza Plymouth.

## Sessão Live e instalação

- Live USB: entrada automática na sessão MATE com o usuário Live.
- Sistema instalado: LightDM solicita usuário e senha; não recebe configuração de autologin.
- Configurações Live e instaladas ficam separadas nos overlays oficiais do Manjaro.
- Rede e Bluetooth são habilitados separadamente nas duas sessões.
- Idioma, geração de locales, teclado e fuso horário têm padrões brasileiros.

## Aplicativos

Firefox, Ferdium, Pamac, Fastfetch, Caja, Terminal MATE, Calculadora, visualizador de imagens, Atril, Engrampa, Pluma e ferramentas essenciais do sistema.

O Ferdium é empacotado como `ferdium-bin` a partir do AUR. Durante a preparação da ISO, o construtor cria um repositório HTTP temporário para disponibilizar o pacote ao `buildiso`. Esse repositório é temporário e não é adicionado às fontes permanentes do sistema instalado. O Pamac mantém o AUR habilitado para o usuário.

## Construção e entrega

- Repositório de trabalho: `cn1988r-coder/forja-iso`.
- Branch: `feature/forja-manjaro-mate`.
- A validação de origem é automática em push na branch `feature/forja-manjaro-mate`; a compilação da ISO é exclusivamente manual (`workflow_dispatch`).
- O construtor compila os utilitários oficiais `manjaro-tools` diretamente do Forgejo do Manjaro, sem depender do repositório `[overlay]`. O sistema Live e instalado usa os repositórios oficiais `core`, `extra` e `multilib`; o AUR é habilitado separadamente no Pamac.
- O workflow de compilação executa verificações de origem antes de iniciar o build.
- A ISO, o checksum SHA-256 e os metadados são publicados somente como artefato temporário do GitHub Actions, com retenção de 24 horas.
- Não publicar ISO em Releases nem versionar a imagem no repositório.

## Estado técnico

As configurações e correções descritas acima estão registradas na branch de trabalho. O construtor usa o layout de overlays documentado pelo Manjaro, com configurações do sistema instalado no `desktop-overlay` e configurações exclusivas da sessão Live no `live-overlay`.

**A ISO ainda não foi compilada nem testada.** Nenhuma validação, build ou inicialização de ISO foi executada nesta etapa. Portanto, o funcionamento real do boot, do ambiente MATE, do Calamares, da instalação BTRFS, do login e dos serviços ainda depende de validação e teste em mídia/VM ou hardware. Não considerar o sistema final aprovado antes dessas etapas.
