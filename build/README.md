# Build da VENOM OS

O caminho recomendado é o ambiente isolado Docker/Podman, baseado em Arch Linux
com os repositórios EndeavourOS configurados a partir de revisões fixadas.

## Requisitos do computador

- Docker ou Podman instalado.
- Arquitetura x86_64.
- Pelo menos 40 GiB livres no disco do projeto.
- Conexão com a internet.
- Memória recomendada: 8 GiB ou mais.

## Compilar no Manjaro ou em outra distribuição

Na raiz do repositório:

```bash
bash scripts/build-container.sh
```

O script constrói a imagem de build e executa a compilação em container privilegiado. O sistema live usa MATE/LightDM e oferece um launcher próprio “Instalar VENOM OS”, que chama o Calamares original do EndeavourOS no modo offline. O app Welcome do EndeavourOS foi retirado porque o fluxo atual só reconhece sessões KDE e XFCE. O cleaner do instalador remove o launcher live e o autologin do liveuser na instalação final, mantendo o LightDM habilitado para o usuário criado pelo Calamares.
O diretório `work/` permanece no projeto e a ISO será criada em
`work/EndeavourOS-ISO/out/`.

O container usa revisões fixadas do framework EndeavourOS e da lista de pacotes
oficial. O usuário de build interno tem sudo restrito ao container, não ao host.

## Build direto em EndeavourOS/Arch

Também é possível usar o script diretamente em um host Arch/EndeavourOS com
repositórios EndeavourOS habilitados:

```bash
bash scripts/build-venom-iso.sh
```

## Pacotes externos

Ferdium, Shelly e Bibata são construídos a partir de receitas externas. O
AUR contém receitas comunitárias, não binários oficiais. As revisões do
framework e do Shelly são fixadas; as receitas AUR de Ferdium e Bibata são
obtidas do HEAD no momento da compilação.

## Estado de validação

A estrutura e a sintaxe do build são verificadas pelo GitHub Actions. Isso não
prova que os pacotes compilaram nem que a ISO inicializa. A ISO só poderá ser
marcada como validada depois de uma compilação real e testes de boot, sessão
MATE e instalação do Calamares em máquina virtual.
