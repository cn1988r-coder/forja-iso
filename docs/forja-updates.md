# Atualizações próprias da Forja

## Decisão de arquitetura

As atualizações oficiais continuam sob responsabilidade dos repositórios Arch Linux e EndeavourOS configurados no `pacman.conf`. **Não adicionar um repositório de pacotes Forja ao `pacman.conf`**: a sincronização desse repositório poderia impedir um `pacman -Syu` quando o serviço da Forja estivesse indisponível.

As correções e os componentes exclusivos da Forja são distribuídos separadamente por versões estáveis (GitHub Releases) do repositório `cn1988r-coder/forja-iso`. O comando `sudo forja-update` consulta a versão estável mais recente e instala somente os arquivos de pacote cujo nome começa com `forja-`.

## Segurança obrigatória

- Cada pacote `.pkg.tar.zst` precisa ter seu arquivo de assinatura correspondente `.pkg.tar.zst.sig na mesma Release.
- O sistema precisa ter a chave pública oficial de assinatura da Forja importada e confiável no chaveiro do Pacman.
- `LocalFileSigLevel` precisa exigir assinatura. O atualizador verifica essa condição e aborta sem instalar nada se ela não estiver ativa.
- O Pacman valida as assinaturas durante `pacman -U`. O atualizador não desativa verificações, não usa `--nodeps` e não ignora erros.
- Releases sem pacotes Forja não fazem alterações.

## Limite do estado atual

Este mecanismo é a estrutura inicial do atualizador. Para habilitar atualizações reais, ainda é necessário definir e proteger a chave de assinatura da Forja, preparar o pacote de chaveiro/configuração que a instala, publicar Releases contendo pacotes Forja assinados e testar a atualização e a recuperação em uma instalação de teste. Até essa validação, o comando deve falhar de forma segura e não deve ser anunciado como funcional.

A indisponibilidade do GitHub/Forja pode impedir uma atualização própria da Forja naquele momento, mas não interfere no `pacman -Syu` dos repositórios oficiais.
