# Integração de pacotes do AUR

## Ferdium

- Pacote: `ferdium-bin`
- Origem: AUR (Arch User Repository)
- Edição: XFCE
- Formato escolhido: pacote binário pré-compilado publicado no AUR.
- Flatpak: não utilizar.

O pacote está registrado em `Packages-AUR`, separado de `Packages-Desktop`, porque o resolvedor de pacotes do perfil Manjaro instala pacotes dos repositórios configurados e não trata nomes do AUR como pacotes oficiais.

## Requisito para a integração final

Para que o Ferdium esteja efetivamente instalado na VENOM OS final, o pacote `ferdium-bin` deverá ser obtido do AUR e disponibilizado como pacote instalável no processo de composição da edição XFCE. Essa etapa precisa ser integrada ao fluxo de preparação de pacotes do projeto antes da construção da ISO.

Este registro não instala o Ferdium, não executa `makepkg`, não compila, não constrói pacote ou ISO e não inicia testes ou workflows. A integração no sistema final ainda depende da etapa própria de disponibilização do pacote AUR.
