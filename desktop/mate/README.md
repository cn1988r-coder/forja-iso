# Forja OS MATE

Camada gráfica oficial da Forja OS, baseada no MATE upstream dos repositórios oficiais do **Arch Linux**. A base EndeavourOS permanece preservada, mas inativa.

## Direção do desktop

- MATE com Marco, mate-panel, Caja e ferramentas essenciais.
- LightDM como gerenciador de login.
- Tema escuro Materia-dark, ícones Papirus-Dark e identidade Forja.
- Paleta discreta, preto/grafite/cinza; prioridade para desempenho.
- Compositor do Marco desligado e efeitos desnecessários desativados.
- Áudio PipeWire/WirePlumber, rede NetworkManager e Bluetooth BlueZ/Blueman.
- LibreOffice Still com pt-BR, Atril, GNOME Calculator independente e `xfce4-screenshooter` como exceção pontual. Não instalar o desktop XFCE nem o GNOME.
- Wallpaper Forja com fundo cinza e chama preta.
- Fastfetch com configuração própria.

## Integração no perfil live Archiso

O script `bases/archlinux/build-profile.sh` usa o perfil oficial `releng` do Archiso, fixado em commit upstream, combina `bases/archlinux/packages.x86_64` e esta lista `packages.x86_64`, copia as personalizações para o root filesystem e chama os instaladores de Forja Store, Forja Monitor e indicador de atualizações. Também instala Forja Luz Noturna e prepara o LightDM.

O perfil Archinstall incluído em `bases/archlinux/airootfs/etc/archinstall/forja-mate.json` preenche o conjunto de pacotes MATE enxuto, locale pt_BR, teclado brasileiro, fuso de São Paulo e serviços. O usuário ainda escolhe disco, particionamento, bootloader e conta durante a instalação.

Ao final, o Archinstall executa um comando pós-instalação que obtém o código Forja no commit fixado e chama `install-target.sh`. Esse script copia configurações para `/etc/skel` e os usuários existentes, instala Forja Store, Forja Monitor, indicador, Forja Luz Noturna, wallpaper, configura dconf e habilita LightDM, NetworkManager e Bluetooth.

## Aplicativos Forja incluídos no plano

- **Forja Store:** loja GTK3 para pacotes oficiais, AUR e Flatpak, com as limitações documentadas no próprio código.
- **Forja Monitor / Sobre do Forja OS:** monitor GTK3/Cairo e informações de hardware. Não usa daemon residente.
- **Indicador de atualizações:** consulta atualizações oficiais via checkupdates e abre a Forja Store.
- **Forja Luz Noturna:** protótipo GTK3/XRandR; depende do suporte do driver gráfico.
- **IPTVnator:** instalador separado, ainda não integrado ao primeiro perfil ISO.
- **Forja Repo:** cliente separado em `forja-repo/`; não será ativado no ISO até que o repositório binário assinado tenha sido publicado.

## Validação e limitações

O workflow de validação confere nomes de pacotes, sintaxe, PKGBUILDs, smoke test GTK do Forja Monitor e instaladores em rootfs temporário. O workflow de build tenta compilar uma ISO real usando Archiso upstream.

Esses testes não substituem boot em VM, teste visual da sessão MATE, instalação completa no disco e validação pós-instalação. A ISO ainda não deve ser considerada pronta até esses testes passarem.

A data/hora exata da instalação permanece indisponível: o helper existe, mas ainda não foi conectado a um hook confirmado de conclusão do Archinstall. Não usar data da ISO, primeiro boot ou mtime como substituto.

## Estrutura principal

- `packages.x86_64`: pacotes MATE e ferramentas da edição.
- `skel/.config/`: configurações padrão de usuário.
- `apply-defaults.sh`: aplica preferências MATE seguras na sessão.
- `install-target.sh`: integração pós-instalação no sistema instalado.
- `forja-store/`, `forja-monitor/`, `forja-update-indicator/`, `forja-luz-noturna/`: aplicativos próprios.
- `forja-repo/`: cliente do repositório binário separado.