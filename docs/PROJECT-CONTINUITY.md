# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Arquitetura definitiva

- Sistema: **VENOM OS**.
- Base: Arch Linux oficial.
- Repositórios: somente os oficiais do Arch Linux.
- Desktop: MATE.
- Gerenciador de login: LightDM.
- Idioma: Português do Brasil.
- Teclado: Brasil ABNT2.
- Mídia: perfil próprio baseado no Archiso oficial.
- Instalador: próprio, C + GTK4, com backend separado.
- Instalação offline a partir da mídia é obrigatória.
- Calamares, EndeavourOS, Manjaro e instaladores de terceiros não fazem parte da arquitetura final.

## Estado confirmado nesta revisão

Branch de trabalho: `optimize/venom-iso-size`.

HEAD verificado: `af236c33d84a63e2076e793ed3469660b7346285`.

### Perfil Archiso

Existem `build/profiledef.sh`, `build/pacman.conf`, manifests de pacotes e configurações parciais em `build/airootfs/`.

**Ainda não está completo nem validado como perfil Archiso.** O próprio `build/README.md` registra que faltam componentes de boot e integração do instalador. Nenhuma ISO Arch independente foi gerada ou validada nesta revisão.

### Instalador

O aplicativo em `installer/` é um protótipo de interface GTK4 em C.

Já presente:
- interface gráfica em português;
- enumeração informativa de discos via `lsblk`;
- seleção visual de disco;
- escolha visual entre instalação automática e personalizada;
- botão de instalação bloqueado para operações reais.

Ainda ausente:
- backend privilegiado;
- particionamento e formatação;
- cópia offline do sistema;
- criação de usuário e configuração do sistema instalado;
- instalação e configuração de GRUB;
- progresso real, logs transacionais e recuperação segura;
- testes de integração em VM e discos virtuais descartáveis.

Portanto, **não é um instalador funcional** e não pode ser anunciado como tal.

### Pipelines

O workflow legado `.github/workflows/build-manjaro-iso.yml` ainda usa `manjaro/manjaro-iso-action` e o perfil Manjaro `venom-mate`. Esse fluxo não constrói a arquitetura Arch definida e não deve ser usado como prova de progresso da VENOM OS independente.

Os arquivos e a ISO Manjaro MATE #21 permanecem apenas como referência histórica de desktop. Não confundir essa referência com a edição Arch final.

## Atualizações

- Pacman administra o sistema e aplicativos: `sudo pacman -Syu`.
- VENON é independente do Pacman e acionado manualmente.
- `venon-upgrade` apenas consulta e lista atualizações disponíveis.
- `venon-update` instala atualizações VENON somente após confirmação explícita.
- Não criar atualizações automáticas ou timers para o VENON.

## Critérios de conclusão

1. Perfil Archiso completo e validado com ferramentas oficiais.
2. Mídia inicializável em BIOS e UEFI.
3. Ambiente Live MATE validado, incluindo rede, Bluetooth, áudio e configurações.
4. Backend do instalador concluído e protegido contra seleção/alteração indevida de discos.
5. Instalação offline testada em VM descartável, incluindo boot pós-instalação.
6. ISO final, SHA256, logs e resultados dos testes preservados.

## Registro desta revisão

- Branch e HEAD consultados diretamente no GitHub.
- Arquivos de arquitetura, perfil, instalador e workflows inspecionados.
- Nenhuma ISO foi compilada, publicada ou declarada pronta.
- A ISO Manjaro MATE #21 não foi alterada.
- Nenhuma outra branch ou `main` foi modificada.
