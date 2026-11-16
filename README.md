# Forja OS

Distribuição derivada do **EndeavourOS**, baseada em Arch Linux e desenvolvida com identidade, configurações e ferramentas próprias.

## Edição em desenvolvimento: XFCE

- XFCE personalizado com painel inferior e menu Whisker.
- Tema escuro e identidade visual Forja.
- Ícones Papirus em tons neutros e cursor Bibata.
- LightDM como gerenciador de login.
- Rede, Bluetooth, áudio PipeWire, Firefox e suporte a Flatpak.
- Perfil de instalação em desenvolvimento, com Btrfs como opção prioritária.

## Base e arquitetura

- **Base oficial:** EndeavourOS / Arch Linux.
- **Perfil ativo:** `profiles/forja-xfce`.
- **Framework de imagem:** projeto oficial EndeavourOS-ISO, baseado em Archiso e `mkarchiso`.
- **Preparação:** `profiles/forja-xfce/prepare-forja.sh` cria uma cópia de trabalho separada, sem modificar o checkout original do EndeavourOS.
- **Manjaro:** código legado preservado no repositório, fora do desenvolvimento ativo da Forja OS. Não usar seus construtores, pacotes, repositórios ou ferramentas na edição EndeavourOS.

## Edições futuras

- **XFCE:** edição prioritária em preparação.
- **i3:** possibilidade futura, a ser planejada depois da consolidação do XFCE.
- **MATE ou Window Maker:** ainda não decidido. Nenhum deles faz parte do escopo de implementação atual.

Cada edição futura deverá ter perfil, lista de pacotes, configuração visual e validação próprios. Não adicionar componentes de outra edição ao perfil XFCE.

## Atualizações da Forja

As atualizações do sistema-base permanecem nos repositórios oficiais configurados pelo EndeavourOS e Arch Linux, usando o Pacman. Componentes exclusivos da Forja serão distribuídos separadamente por versões do projeto, sem adicionar um repositório Forja ao `pacman.conf`.

O atualizador próprio já possui uma estrutura inicial, mas ainda depende da implementação e validação da chave oficial de assinatura, do keyring e de releases assinadas. Até isso ser concluído, não deve ser considerado funcional.

## Estado atual

O perfil EndeavourOS XFCE está em preparação e validação estática. Ainda faltam etapas de integração do ambiente Live, Calamares, dracut/Plymouth, dependências e testes reais de instalação e inicialização.

**Não anunciar a ISO como pronta antes de concluir essas verificações.** As validações estáticas não compilam a ISO.