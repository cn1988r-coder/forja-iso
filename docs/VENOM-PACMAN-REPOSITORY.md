# Pacman e repositório VENOM OS

## Separação de responsabilidades

O Pacman normal em /etc/pacman.conf continua responsável pelo sistema Arch: kernel, bibliotecas, dependências, correções e atualizações de segurança.

O repositório VENOM é separado e destinado somente a pacotes próprios da distribuição. O comando de entrada é **sudo venom** e utiliza /etc/venom/pacman.conf, sem editar nem substituir a configuração normal do Pacman.

Pacotes publicados no repositório próprio devem usar o prefixo venom-. Dependências normais podem ser resolvidas pelos repositórios oficiais Arch listados na configuração isolada.

## Uso

O usuário executa somente:

```bash
sudo venom
```

O comando abre um menu interativo com as opções:
1. Atualizar a lista de pacotes do repositório VENOM.
2. Pesquisar pacotes.
3. Instalar pacote VENOM.
4. Atualizar somente pacotes VENOM já instalados.
5. Remover pacote VENOM.
6. Listar pacotes VENOM instalados.
0. Sair.

Não é necessário memorizar subcomandos. O menu permanece aberto até a opção Sair. Todas as operações de pacotes usam a configuração isolada. A atualização geral do sistema continua sendo responsabilidade do Pacman normal, fora do menu VENOM.

## Arquivos da imagem

- /usr/bin/venom
- /etc/venom/pacman.conf
- /etc/pacman.d/venom-mirrorlist
- /etc/venom/repository-key

## Estado operacional

A interface de menu e a configuração isolada estão preparadas no código-fonte. O repositório remoto ainda NÃO está operacional: faltam hospedagem, URL HTTPS real, chave pública de assinatura, fingerprint oficial e pacotes VENOM publicados.

A configuração exige assinatura de banco de dados e pacotes (SigLevel = Required DatabaseRequired). O comando recusa operações remotas enquanto a URL e o fingerprint não estiverem configurados e a chave não estiver no chaveiro Pacman.

Para ativar futuramente:
1. Criar hospedagem compatível com repositório Pacman.
2. Publicar pacotes próprios venom-* e bancos assinados.
3. Definir o servidor HTTPS no arquivo /etc/pacman.d/venom-mirrorlist.
4. Instalar a chave pública oficial no chaveiro Pacman e assiná-la localmente após conferir o fingerprint por canal confiável.
5. Registrar o fingerprint completo em /etc/venom/repository-key.

Não aceitar automaticamente chaves ou fingerprints. A chave oficial deve ser confirmada pelo responsável pelo projeto.

## Limitações atuais

- Sem servidor configurado.
- Sem chave oficial ou fingerprint.
- Sem pacotes VENOM publicados.
- Operações remotas permanecem bloqueadas até esses itens existirem.
- A implementação do menu ainda precisa de testes reais em Arch/VENOM antes de ser considerada pronta para uso.
