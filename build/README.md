# Perfil Archiso da VENOM OS

A mídia usa o Archiso oficial e pacotes dos repositórios oficiais do Arch Linux. O perfil x86_64 está em `build/`.

## Inicialização

- BIOS via Syslinux e UEFI via GRUB.
- A mídia inicia diretamente o instalador TUI VENOM na tty1.
- Não há sessão Live, ambiente gráfico de demonstração ou desktop carregado pelo pendrive.
- A imagem contém somente a base necessária para iniciar o instalador em C + ncurses e executar o backend.

## Instalador único

O único instalador da VENOM OS está em `installer/src/` e é compilado pelo Meson durante a geração da ISO. O executável é instalado na mídia como `/usr/bin/venom-installer`.

O fluxo oferece exclusivamente VENOM OS XFCE e VENOM OS MATE. O backend executa a instalação no disco selecionado, com confirmação destrutiva explícita. Não adicionar outro frontend ou tecnologia de instalação.

## Pacotes de instalação

A preparação da ISO monta um repositório local com os pacotes e dependências exigidos pelas duas edições. Esse repositório é incluído na mídia e usado pelo backend para instalar o sistema sem depender de conexão de rede durante a instalação.

## Validação

O workflow compila o TUI, executa os testes Meson, valida os scripts e o perfil Archiso, prepara os pacotes offline e gera a ISO. A geração também verifica se o arquivo de configuração do Syslinux foi incluído na imagem, evitando publicar uma ISO que pare em `ISOLINUX: No configuration file found`.

A compilação e a presença dos arquivos de boot não substituem os testes de inicialização BIOS/UEFI e a instalação completa em máquinas virtuais descartáveis.
