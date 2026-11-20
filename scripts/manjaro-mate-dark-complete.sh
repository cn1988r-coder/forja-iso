#!/usr/bin/env bash
#
# manjaro-mate-dark-complete.sh
# Configuração completa do MATE no Manjaro + wallpaper 4K da Lua
#

set -euo pipefail

VERDE='\033[0;32m'; AMARELO='\033[1;33m'; VERMELHO='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${VERDE}[INFO]${NC} $1"; }
aviso() { echo -e "${AMARELO}[AVISO]${NC} $1"; }
erro()  { echo -e "${VERMELHO}[ERRO]${NC} $1"; exit 1; }

# ---------------------------------------------------------
# 1. VERIFICAÇÃO
# ---------------------------------------------------------
command -v pacman &>/dev/null || erro "Exclusivo para Manjaro/Arch."
[[ $EUID -eq 0 ]] && erro "Rode como usuário normal."

# ---------------------------------------------------------
# 2. PACOTES
# ---------------------------------------------------------
info "Atualizando sistema e instalando pacotes..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed \
    mate mate-extra \
    materia-gtk-theme papirus-icon-theme dconf-editor blueman

# ---------------------------------------------------------
# 3. AUR (Brisk Menu + Bibata)
# ---------------------------------------------------------
AUR_HELPER=""
if command -v yay &>/dev/null; then AUR_HELPER="yay"
elif command -v paru &>/dev/null; then AUR_HELPER="paru"
else
    aviso "Instalando yay-bin..."
    cd /tmp && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin
    makepkg -si --noconfirm && cd - && AUR_HELPER="yay"
fi

info "Instalando Brisk Menu..."
$AUR_HELPER -S --noconfirm --needed brisk-menu-git || \
    sudo pacman -S --noconfirm --needed mate-applet-brisk-menu

info "Instalando cursor Bibata..."
$AUR_HELPER -S --noconfirm --needed bibata-cursor-theme-bin

# ---------------------------------------------------------
# 4. LAYOUT DO PAINEL (já inclui Brisk Menu e indicadores)
# ---------------------------------------------------------
info "Aplicando layout Manjaro..."
gsettings set org.mate.panel default-layout 'manjaro'
mate-panel --reset & sleep 2

# ---------------------------------------------------------
# 5. TEMA, ÍCONES, CURSOR
# ---------------------------------------------------------
info "Aplicando Materia Dark..."
gsettings set org.mate.interface gtk-theme 'Materia-dark'
gsettings set org.mate.Marco.general theme 'Materia-dark'
gsettings set org.mate.interface metacity-theme 'Materia-dark'

info "Aplicando Papirus-Dark..."
gsettings set org.mate.interface icon-theme 'Papirus-Dark'

info "Aplicando Bibata..."
gsettings set org.mate.peripherals-mouse cursor-theme 'Bibata-Modern-Classic'
gsettings set org.mate.peripherals-mouse cursor-size 24
gsettings set org.mate.interface gtk-application-prefer-dark-theme true

# ---------------------------------------------------------
# 6. WALLPAPER 4K DA LUA (vem no pacote)
# ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALL_SRC="$SCRIPT_DIR/wallpapers/moon-grey-4k.jpg"
WALL_DIR="$HOME/.local/share/wallpapers"
WALL_FILE="$WALL_DIR/moon-grey-4k.jpg"

mkdir -p "$WALL_DIR"

if [[ -f "$WALL_SRC" ]]; then
    cp "$WALL_SRC" "$WALL_FILE"
    info "Wallpaper copiado do pacote."
else
    aviso "Wallpaper não encontrado no pacote, baixando..."
    curl -L -o "$WALL_FILE" \
        "https://wallpapers.com/images/wallpapers/magnificavista-de-uma-lua-cheia-no-ceu-noturno-4q7f0ei1u5yvrwp0.jpg"
fi

info "Aplicando wallpaper..."
gsettings set org.mate.background picture-filename "$WALL_FILE" 2>/dev/null || \
    gsettings set org.mate.desktop.background picture-uri "file://$WALL_FILE" 2>/dev/null || \
    aviso "Não foi possível aplicar o wallpaper automaticamente."

# ---------------------------------------------------------
# 7. AJUSTE BRISK MENU
# ---------------------------------------------------------
if gsettings list-schemas 2>/dev/null | grep -q 'com.solus-project.brisk-menu'; then
    gsettings set com.solus-project.brisk-menu label-visible false 2>/dev/null || true
fi

# ---------------------------------------------------------
# 8. VERIFICAÇÃO FINAL
# ---------------------------------------------------------
echo ""
info "=== Configuração final ==="
echo "Tema:    $(gsettings get org.mate.interface gtk-theme)"
echo "Ícones:  $(gsettings get org.mate.interface icon-theme)"
echo "Cursor:  $(gsettings get org.mate.peripherals-mouse cursor-theme)"
echo "Layout:  $(gsettings get org.mate.panel default-layout)"
echo "Wallpaper: $WALL_FILE"
echo ""
info "Faça LOGOUT e LOGIN para aplicar tudo completamente."
