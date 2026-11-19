# Forja OS

## Definições do projeto

- **Base:** EndeavourOS Linux.
- **Instalador:** manter o Calamares da distribuição EndeavourOS, incluindo a variante/fork e os módulos necessários. Não criar instalador próprio.
- **Ambiente gráfico:** MATE como único ambiente gráfico.
- **Aparência:** interface escura, tema GTK Materia Dark, ícones Papirus e cursor Bibata.
- **Área de trabalho:** fundo preto puro (#000000), sem wallpapers do EndeavourOS ou de terceiros.
- **Aplicativos:** Firefox, Ferdium e Shelly (gerenciador gráfico de pacotes para Arch Linux).

## Regras

- Trabalhar somente neste repositório.
- Não incluir outro ambiente gráfico nem aplicativos fora da lista definida.
- Preservar os componentes necessários do EndeavourOS, especialmente o instalador.
- Não declarar validação ou compilação concluída sem evidência reproduzível.

## Estado técnico

O repositório está em preparação. A estrutura de compilação da Forja OS ainda não foi criada e nenhuma ISO foi compilada.

O framework oficial do EndeavourOS usa uma versão modificada do Archiso. O perfil upstream atualmente contém uma sessão KDE e etapas específicas para o esqueleto de usuário, tema e wallpaper do KDE/EndeavourOS. Portanto, não basta trocar a lista de pacotes por MATE: é necessário adaptar essas etapas e preservar a integração do Calamares do EndeavourOS.

A lista upstream consultada não instala Calamares diretamente: ela documenta que o pacote não está mais no repositório e que deve ser construído separadamente. A preparação da Forja precisa localizar e integrar a receita oficial/fork compatível antes de qualquer ISO ser considerada instalável.

A validação automatizada inicial verifica o escopo e os arquivos do projeto. Ela não substitui a validação de dependências, o teste do instalador em máquina virtual ou a compilação real da ISO.
