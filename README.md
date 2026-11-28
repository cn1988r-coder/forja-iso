# BuildMaker XFCE Dark

Perfil de desktop **XFCE** com aparência escura moderna, detalhes azul elétrico e LightDM GTK Greeter. Não usa KDE, MATE ou SDDM.

## Interface XFCE

- Um único painel inferior, largura total e 46 px de altura.
- Menu Whisker personalizado com o ícone V azul do BuildMaker.
- Docklike Taskbar imediatamente à direita do menu. Agrupa janelas do mesmo aplicativo em um botão.
- Área de notificação, volume, energia, monitor CPU/RAM, relógio e mostrar área de trabalho.
- Tema Orchis-Dark azul/preto, ícones Papirus-Dark, cursor Bibata-Modern-Ice tamanho 24 e fonte Noto Sans.
- Compositor e efeitos visuais desativados. Sem transparências ou animações chamativas.
- Painel continua editável pelo menu de contexto do XFCE.

## Instalação da configuração

Em uma instalação Arch/Manjaro com `pacman`:

```bash
sudo bash scripts/install-xfce-dark.sh
```

O script instala os componentes do desktop, prepara o tema e configura o LightDM. O perfil de pacotes está em `Packages-Desktop`.

## Estrutura

- `profile.conf`: metadados do perfil XFCE.
- `Packages-Desktop`: seleção de pacotes.
- `scripts/install-xfce-dark.sh`: instalação e configuração.
- `desktop-overlay/etc/skel/`: preferências padrão de novos usuários.
- `desktop-overlay/usr/share/icons/`: ícone V do menu.

**Estado:** configuração do desktop versionada. A ISO e o instalador Calamares ainda exigem perfil Archiso próprio, configuração do Calamares e testes de inicialização/instalação. Não considerar uma ISO pronta até esses testes passarem.
