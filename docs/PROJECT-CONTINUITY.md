# Continuidade técnica da VENOM OS

Atualizado em 20/11/2026.

## Repositório e branch
- Repositório: cn1988r-coder/forja-iso.
- Branch autorizada: optimize/venom-iso-size.
- HEAD de referência antes desta limpeza: 3f3fb1b447de4cbd04e3a361ac48009d4b53211c.

## Decisões permanentes
- VENOM OS é uma distribuição independente baseada no Arch Linux oficial.
- MATE + LightDM são o único desktop e gerenciador de login.
- Idioma exclusivo: Português do Brasil.
- Teclado padrão: Brasil ABNT2.
- Instalador próprio em C + GTK4, totalmente gráfico e com instalação offline.
- Pacman administra atualizações normais com sudo pacman -Syu.
- VENON é independente do Pacman e só funciona por comandos manuais após confirmação.
- Nenhuma compilação de ISO sem autorização expressa do usuário.

## Limpeza executada nesta revisão
- Removidos os arquivos do instalador legado e suas regras de autorização.
- Removidos os diretórios de branding e configuração do instalador de terceiros.
- Removidos scripts de patch e validadores que dependiam da arquitetura anterior.
- Reescritos Dockerfile e scripts de validação para usar somente a base Arch Linux oficial.
- Reorientada a configuração de mídia para o perfil Archiso mantido pelo projeto.
- Configurados locale pt_BR.UTF-8 e teclado br-abnt2.
- Corrigido o workflow de validação para a branch autorizada.
- Mantido o workflow de ISO intencionalmente bloqueado.

## Estado real após a limpeza
### Feito
- Arquivos de configuração e documentação operacional reescritos.
- Perfil inicial Archiso e manifesto x86_64 adicionados.
- Scripts estáticos reescritos para não gerar ISO.
- Indicadores MATE permanecem listados nos pacotes necessários.

### Pendente
1. Completar a estrutura de boot do perfil Archiso e validar o perfil sem gerar ISO.
2. Implementar o instalador próprio C + GTK4 e seu backend seguro.
3. Corrigir e testar individualmente os indicadores de rede, Bluetooth e volume/áudio numa sessão MATE real.
4. Criar testes unitários e de integração para particionamento, instalação offline, usuário e GRUB.
5. Validar o sistema live e a instalação numa VM descartável, somente depois da implementação.

### Não testado
- Nenhuma ISO foi compilada.
- Nenhuma instalação foi executada.
- Nenhuma sessão gráfica MATE foi iniciada nesta revisão.
- Os indicadores não foram comprovados após login/reinicialização.
- O perfil Archiso ainda não está pronto para compilação.

## Próximo passo
Completar o perfil Archiso e iniciar o esqueleto do instalador C + GTK4 sem disparar qualquer build de ISO.
