# VENOM OS

A VENOM OS passa a usar **Manjaro Linux** como base, com desktop MATE e LightDM.

## Base e desktop
- Distribuição base: Manjaro Linux, repositórios oficiais Manjaro.
- Perfil próprio: `manjaro/venom-mate`, construído pelo `manjaro-tools/buildiso` oficial.
- Desktop: MATE + MATE Extra.
- Gerenciador de login: LightDM.
- Idioma padrão: Português do Brasil.
- Teclado padrão: Brasil ABNT2.
- O perfil não inclui Calamares nem Endeavouros.

## Configuração MATE do DeepSeek
O script `scripts/manjaro-mate-dark-complete.sh` foi mantido com sua lógica original. A única correção foi retirar `manjaro-mate-settings`, pacote que o Manjaro informa não oferecer atualmente para MATE. O layout `manjaro` usado pelo script é fornecido diretamente no perfil. A cópia instalada em `/usr/local/bin/manjaro-mate-dark-complete.sh` é verificada byte a byte contra o arquivo de origem.

No menu do MATE existe o atalho **Configurar MATE**. Ele abre um terminal e executa o script original, permitindo que os comandos sudo do script solicitem autenticação quando necessário. O script não é executado silenciosamente no primeiro login.

## Construção
- Workflow: `.github/workflows/build-manjaro-iso.yml`.
- Ferramenta de construção: ação oficial `manjaro/manjaro-iso-action`, baseada em `manjaro-tools/buildiso` e nos perfis Manjaro.
- Perfil: `venom-mate`.
- Canal: `stable`.
- Kernel: `linux618`.
- Artefato ISO temporário do GitHub Actions: retenção de 3 dias.

## Limite atual
O perfil gera uma sessão live MATE para validar o desktop e o script. Ele **não contém instalador**: Calamares foi excluído e o instalador próprio VENOM ainda não possui backend funcional. Portanto, esta imagem não deve ser tratada como instalável em disco até o instalador próprio ser implementado e testado.

## Atualizações
O Pacman administra o sistema e os aplicativos: `sudo pacman -Syu`.

O VENON continua sendo um mecanismo separado, manual e independente do Pacman:
- `venon-upgrade`: consulta e lista atualizações disponíveis, sem instalar.
- `venon-update`: instala atualizações VENON somente após confirmação explícita.
