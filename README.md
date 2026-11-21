# VENOM OS

A VENOM OS é um projeto de distribuição independente baseada diretamente no **Arch Linux oficial**, com desktop MATE, LightDM, identidade própria e instalador gráfico desenvolvido pelo projeto.

## Arquitetura definida

- Base: Arch Linux oficial e seus repositórios oficiais.
- Construção da mídia: perfil próprio baseado no Archiso oficial.
- Desktop: MATE.
- Gerenciador de login: LightDM.
- Idioma: Português do Brasil.
- Teclado: Brasil ABNT2.
- Instalador: próprio, em C + GTK4, com backend separado.
- Instalação offline a partir da própria mídia é requisito obrigatório.
- Não usar Calamares, EndeavourOS, ferramentas de construção Manjaro ou componentes de outras distribuições na arquitetura final.

## Estado real do desenvolvimento

**A VENOM OS ainda não está pronta para instalação ou distribuição.**

O perfil Archiso em `build/` está incompleto. O instalador em `installer/` é somente um protótipo de interface: detecta discos e apresenta opções, mas não particiona, não formata e não instala o sistema. Não existe ainda uma ISO Arch independente validada.

A ISO VENOM OS Manjaro MATE #21 é mantida apenas como referência histórica testada do desktop MATE e dos indicadores. Ela não representa a arquitetura final Arch e não deve ser apresentada como a VENOM OS independente.

## Componentes do projeto

- `build/`: perfil Archiso em desenvolvimento.
- `installer/`: protótipo do instalador próprio C + GTK4.
- `docs/PROJECT-CONTINUITY.md`: registro técnico do estado, decisões, testes e bloqueios.
- `AGENTS.md`: regras obrigatórias de arquitetura e trabalho.

## Atualizações

O Pacman administra as atualizações normais do sistema e dos aplicativos:

```bash
sudo pacman -Syu
```

O VENON é separado do Pacman e acionado manualmente:

- `venon-upgrade`: consulta e lista atualizações disponíveis, sem instalar.
- `venon-update`: instala atualizações VENON somente após confirmação explícita.

## Critérios para declarar uma versão pronta

1. Perfil Archiso completo e validado com as ferramentas oficiais do Arch.
2. Mídia inicializável testada em BIOS e UEFI.
3. Sessão Live MATE, rede, Bluetooth, áudio e configurações verificadas.
4. Instalador próprio com backend concluído, testado em discos virtuais descartáveis e capaz de instalar offline.
5. Instalação concluída em VM, com boot do sistema instalado e validação pós-instalação.
6. ISO, checksum e logs de validação preservados.

Nenhum arquivo de ISO deve ser anunciado como pronto sem essas verificações reais.
