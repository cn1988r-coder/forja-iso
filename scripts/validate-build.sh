#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

required_files=(
  "$ROOT/scripts/build-venom-iso.sh"
  "$ROOT/scripts/build-container.sh"
  "$ROOT/scripts/patch-calamares.py"
  "$ROOT/build/calamares/branding/venom/branding.desc"
  "$ROOT/build/calamares/branding/venom/stylesheet.qss"
  "$ROOT/build/airootfs/etc/polkit-1/rules.d/49-venom-calamares.rules"
  "$ROOT/build/calamares/branding/venom/venom-logo.svg"
  "$ROOT/Dockerfile"
  "$ROOT/.dockerignore"
  "$ROOT/build/packages.mate"
  "$ROOT/build/packages.arch"
  "$ROOT/build/airootfs/etc/dconf/profile/user"
  "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom"
  "$ROOT/build/airootfs/etc/lightdm/lightdm.conf.d/10-venom-live.conf"
  "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf"
  "$ROOT/build/airootfs/etc/skel/.config/gtk-3.0/settings.ini"
  "$ROOT/build/airootfs/etc/skel/.config/gtk-4.0/settings.ini"
  "$ROOT/build/airootfs/etc/skel/.icons/default/index.theme"
  "$ROOT/build/airootfs/usr/share/icons/default/index.theme"
)
for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "arquivo necessário ausente: $file"
done
[[ -x "$ROOT/build/airootfs/usr/bin/venom-calamares" ]] || fail "wrapper gráfico do Calamares não tem permissão de execução no repositório"
grep -Fq 'chmod 0755 "$EOS_DIR/airootfs/usr/bin/venom-calamares"' "$ROOT/scripts/build-venom-iso.sh" || fail "wrapper do Calamares não tem permissão de execução garantida no ambiente Live"

bash -n "$ROOT/scripts/build-venom-iso.sh" || fail "erro de sintaxe no script de compilação"
bash -n "$ROOT/scripts/build-container.sh" || fail "erro de sintaxe no wrapper Docker/Podman"

python - "$ROOT/scripts/build-venom-iso.sh" <<'PY'
import ast, pathlib, re, sys
source = pathlib.Path(sys.argv[1]).read_text()
separator = chr(10)
blocks = re.findall("<<'PY'" + separator + "(.*?)" + separator + "PY", source, re.S)
if not blocks:
    raise SystemExit("Nenhum bloco Python foi encontrado no script de build.")
for index, block in enumerate(blocks, 1):
    compile(block, f"build-venom-iso.sh:python-block-{index}", "exec")
print(f"OK: {len(blocks)} blocos Python embutidos válidos")
lightdm_marker = 'python - "$EOS_DIR/run_before_squashfs.sh" <<' + chr(39) + 'PY' + chr(39) + chr(10)
if lightdm_marker not in source:
    raise SystemExit("Bloco LightDM não foi encontrado no script de build.")
lightdm = source.split(lightdm_marker, 1)[1].split(chr(10) + "PY", 1)[0]
if "import pathlib, re, sys" not in lightdm:
    raise SystemExit("Bloco LightDM usa re sem importar o módulo.")

tree = ast.parse(lightdm)
pattern_text = None
for node in ast.walk(tree):
    if not isinstance(node, ast.Assign):
        continue
    if not any(isinstance(target, ast.Name) and target.id == "calamares_install_pattern"
               for target in node.targets):
        continue
    call = node.value
    if (isinstance(call, ast.Call) and isinstance(call.func, ast.Attribute)
            and call.func.attr == "compile" and call.args
            and isinstance(call.args[0], ast.Constant)
            and isinstance(call.args[0].value, str)):
        pattern_text = call.args[0].value
        break
if pattern_text is None:
    raise SystemExit("Regex de pacotes locais do Calamares não foi encontrada como literal Python.")
pattern = re.compile(pattern_text, re.MULTILINE)
fixture = '  pacman -U --noconfirm --needed -- "/root/packages/"*".pkg.tar.zst"' + chr(10)
if len(list(pattern.finditer(fixture))) != 1:
    raise SystemExit("Regex de pacotes locais não reconhece o comando upstream fixado.")
print("OK: import re e regex de pacotes locais do Calamares")
PY
grep -Fq 'EOS_COMMIT="90376d8f52ab19e19073eed33d6f36c46ec7c409"' "$ROOT/scripts/build-venom-iso.sh" || fail "framework EndeavourOS sem revisão fixada"
grep -Fq 'PKGBUILDS_COMMIT="474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd"' "$ROOT/scripts/build-venom-iso.sh" || fail "receita Calamares sem revisão fixada"
grep -Fq 'SHELLY_COMMIT="6840658b19d72205c38bd320c1cef6ff3076bc7c"' "$ROOT/scripts/build-venom-iso.sh" || fail "Shelly sem revisão fixada"
grep -Fq 'raw.githubusercontent.com/endeavouros-team/PKGBUILDS/' "$ROOT/scripts/build-venom-iso.sh" || fail "PKGBUILD original do Calamares não está sendo obtido na revisão fixada"
grep -Fq 'raw.githubusercontent.com/Seafoam-Labs/Shelly-ALPM/' "$ROOT/scripts/build-venom-iso.sh" || fail "PKGBUILD Shelly não está sendo obtido na revisão fixada"
grep -Fq 'makepkg --syncdeps --noconfirm' "$ROOT/scripts/build-venom-iso.sh" || fail "PKGBUILD original do Calamares não é compilado"
grep -Fq 'install -m 0644 /etc/calamares/settings_online.conf /etc/calamares/settings.conf' "$ROOT/scripts/build-venom-iso.sh" || fail "configuração online não é o padrão do instalador"
grep -Fq 'pkexec /usr/bin/venom-calamares -c /etc/calamares-online' "$ROOT/scripts/build-venom-iso.sh" || fail "atalho principal não inicia o wrapper VENOM online"
grep -Fq 'Name=Install VENOM OS (online)' "$ROOT/scripts/build-venom-iso.sh" || fail "atalho online não identifica a VENOM OS"
grep -Fq 'Name[pt_BR]=Instalar VENOM OS (online)' "$ROOT/scripts/build-venom-iso.sh" || fail "atalho online não está identificado em português"
grep -Fq 'pkexec /usr/bin/venom-calamares -c /etc/calamares-offline' "$ROOT/scripts/build-venom-iso.sh" || fail "atalho offline não inicia o wrapper VENOM"
grep -Fq 'Exec=sh -c "pkexec /usr/bin/venom-calamares -c /etc/calamares-online"' "$ROOT/scripts/build-venom-iso.sh" || fail "atalho gráfico não inicia o wrapper VENOM do Calamares"
grep -Fq 'action.id === "com.github.calamares.calamares.pkexec.run"' "$ROOT/build/airootfs/etc/polkit-1/rules.d/49-venom-calamares.rules" || fail "regra Polkit não autoriza a ação pkexec do Calamares"
grep -Fq 'subject.user === "liveuser"' "$ROOT/build/airootfs/etc/polkit-1/rules.d/49-venom-calamares.rules" || fail "regra Polkit não está restrita ao usuário Live"
grep -Fq 'subject.isInGroup("wheel")' "$ROOT/build/airootfs/etc/polkit-1/rules.d/49-venom-calamares.rules" || fail "regra Polkit não exige o grupo wheel"
grep -Fq 'subject.active' "$ROOT/build/airootfs/etc/polkit-1/rules.d/49-venom-calamares.rules" || fail "regra Polkit não exige sessão ativa"
grep -Fq 'subject.local' "$ROOT/build/airootfs/etc/polkit-1/rules.d/49-venom-calamares.rules" || fail "regra Polkit não exige sessão local"
grep -Fq 'TryExec=/usr/bin/calamares' "$ROOT/scripts/build-venom-iso.sh" || fail "atalho gráfico não verifica o executável Calamares"
grep -Fq 'rm -f "$EOS_DIR/airootfs/etc/skel/.config/gtk-3.0/settings.ini"' "$ROOT/scripts/build-venom-iso.sh" || fail "configuração GTK3 duplicada pode conflitar com endeavouros-skel-liveuser"
grep -Fq 'rm -f "$EOS_DIR/airootfs/etc/skel/.config/gtk-4.0/settings.ini"' "$ROOT/scripts/build-venom-iso.sh" || fail "configuração GTK4 duplicada pode conflitar com endeavouros-skel-liveuser"
grep -Fq '/home/liveuser/.local/share/applications/calamares.desktop' "$ROOT/scripts/build-venom-iso.sh" || fail "atalho Calamares não usa o caminho real do perfil liveuser"
if grep -Fq '/usr/share/applications/calamares.desktop' "$ROOT/scripts/build-venom-iso.sh"; then
  fail "atalho Calamares aponta para um caminho não fornecido pelo perfil EndeavourOS"
fi
grep -Fq 'MAKEFLAGS="-j$(nproc)"' "$ROOT/scripts/build-venom-iso.sh" || fail "compilação paralela de pacotes não está habilitada"
grep -Fq '90376d8f52ab19e19073eed33d6f36c46ec7c409/pacman.conf' "$ROOT/Dockerfile" || fail "container sem pacman.conf fixado do EndeavourOS"
grep -Fq '474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd/endeavouros-mirrorlist' "$ROOT/Dockerfile" || fail "container sem mirrorlist fixada do EndeavourOS"
grep -Fxq '**' "$ROOT/.dockerignore" || fail "contexto Docker não exclui artefatos do build"
grep -Fxq '!Dockerfile' "$ROOT/.dockerignore" || fail "Dockerfile não foi preservado no contexto"

grep -Fxq 'mate-session-manager' "$ROOT/build/packages.mate" || fail "pacote MATE ausente"
grep -Fxq 'lightdm' "$ROOT/build/packages.mate" || fail "LightDM ausente"
grep -Fxq 'mate-polkit' "$ROOT/build/packages.mate" || fail "agente Polkit do MATE ausente"
grep -Fxq 'network-manager-applet' "$ROOT/build/packages.mate" || fail "ícone de rede do NetworkManager ausente no perfil Live"
grep -Fxq 'mate-media' "$ROOT/build/packages.mate" || fail "indicador de volume do MATE ausente no perfil Live"
grep -Fxq 'blueman' "$ROOT/build/packages.mate" || fail "applet Bluetooth Blueman ausente no perfil Live"
grep -Fxq 'bluez' "$ROOT/build/packages.mate" || fail "serviço Bluetooth BlueZ ausente no perfil Live"
grep -Fxq 'bluez-utils' "$ROOT/build/packages.mate" || fail "utilitários Bluetooth BlueZ ausentes no perfil Live"
grep -Fxq 'pipewire-pulse' "$ROOT/build/packages.mate" || fail "backend PulseAudio do PipeWire ausente no perfil Live"
grep -Fxq 'wireplumber' "$ROOT/build/packages.mate" || fail "gerenciador de áudio WirePlumber ausente no perfil Live"
grep -Fq 'systemctl enable bluetooth.service' "$ROOT/scripts/build-venom-iso.sh" || fail "serviço Bluetooth não será habilitado no Live"
grep -Fq 'check_session_applet /etc/xdg/autostart/nm-applet.desktop nm-applet' "$ROOT/scripts/build-venom-iso.sh" || fail "autostart real do applet de rede não é validado"
grep -Fq 'check_session_applet /etc/xdg/autostart/blueman.desktop blueman-applet' "$ROOT/scripts/build-venom-iso.sh" || fail "autostart real do applet Bluetooth não é validado"
grep -Fq 'check_session_applet /etc/xdg/autostart/mate-volume-control-status-icon.desktop mate-volume-control-status-icon' "$ROOT/scripts/build-venom-iso.sh" || fail "autostart real do ícone de volume não é validado"
grep -Fq 'NotificationAreaAppletFactory::NotificationArea' "$ROOT/scripts/build-venom-iso.sh" || fail "área de notificação do painel MATE não é validada"
grep -Fq "default-layout='default'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom" || fail "layout padrão do painel MATE não é definido explicitamente"
grep -Fq 'background=#000000' "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" || fail "fundo preto do greeter LightDM ausente"
grep -Fq 'theme-name=Materia-dark' "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" || fail "tema do greeter LightDM ausente"
grep -Fq 'icon-theme-name=Papirus' "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" || fail "ícones do greeter LightDM ausentes"
grep -Fq 'cursor-theme-name=Bibata-Modern-Classic' "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" || fail "cursor do greeter LightDM ausente"
grep -Fq "cursor-theme='Bibata-Modern-Classic'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom" || fail "cursor padrão do MATE ausente no dconf"
grep -Fq 'gtk-cursor-theme-name=Bibata-Modern-Classic' "$ROOT/build/airootfs/etc/skel/.config/gtk-3.0/settings.ini" || fail "cursor padrão GTK3 ausente"
grep -Fq 'gtk-cursor-theme-name=Bibata-Modern-Classic' "$ROOT/build/airootfs/etc/skel/.config/gtk-4.0/settings.ini" || fail "cursor padrão GTK4 ausente"
grep -Fq 'Inherits=Bibata-Modern-Classic' "$ROOT/build/airootfs/etc/skel/.icons/default/index.theme" || fail "cursor Xcursor padrão do novo usuário ausente"
grep -Fq 'Inherits=Bibata-Modern-Classic' "$ROOT/build/airootfs/usr/share/icons/default/index.theme" || fail "cursor Xcursor padrão do sistema ausente"
grep -Fq 'cp "$ROOT/build/airootfs/etc/skel/.icons/default/index.theme" "$SKEL/.icons/default/index.theme"' "$ROOT/scripts/build-venom-iso.sh" || fail "cursor Bibata não é incorporado ao perfil inicial do usuário"
grep -Fq 'systemctl enable lightdm.service' "$ROOT/scripts/build-venom-iso.sh" || fail "LightDM não será habilitado"
grep -Fq 'dconf update' "$ROOT/scripts/build-venom-iso.sh" || fail "banco dconf não será compilado"
grep -Fq 'MENU TITLE VENOM OS' "$ROOT/scripts/build-venom-iso.sh" || fail "menu de boot sem identidade VENOM OS"
grep -Fq 'MENU COLOR title        1;37;40 #ffffffff #00000000 std' "$ROOT/scripts/build-venom-iso.sh" || fail "menu de boot não está em preto e branco"
grep -Fq 'splash.unlink()' "$ROOT/scripts/build-venom-iso.sh" || fail "splash gráfico upstream não será removido"
grep -Fq 'auto-entries no' "$ROOT/scripts/build-venom-iso.sh" || fail "systemd-boot sem configuração neutra"
grep -Fq 'quiet loglevel=3 vt.global_cursor_default=0' "$ROOT/scripts/build-venom-iso.sh" || fail "inicialização sem modo visual discreto"
grep -Fq "'-comp' 'xz' '-Xbcj' 'x86' '-Xdict-size' '100%' '-b' '1M'" "$ROOT/scripts/build-venom-iso.sh" || fail "SquashFS não usa XZ com filtro x86 e dicionário de 100% configurado para compressão da ISO"

if grep -Eq 'requiredStorage|requiredRam|chrooted_cleaner_script[.]sh|python - PKGBUILD' "$ROOT/scripts/build-venom-iso.sh"; then
  fail "o script contém alterações não autorizadas no fluxo do Calamares"
fi
grep -Fq 'CMAKE_BUILD_TYPE=Release' "$ROOT/scripts/build-venom-iso.sh" || fail "Calamares não está configurado para build Release"
grep -Fq 'patch-calamares.py' "$ROOT/scripts/build-venom-iso.sh" || fail "patch de branding e validação do Calamares não será aplicado"
grep -Fq 'branding: venom' "$ROOT/scripts/patch-calamares.py" || fail "configuração offline não aponta para o branding VENOM"
python - "$ROOT/scripts/patch-calamares.py" <<'PY'
import pathlib, sys
source = pathlib.Path(sys.argv[1]).read_text()
sequence = chr(10).join(["  - usersq", "  - partition", "  - summary"])
if sequence not in source:
    raise SystemExit("Telas do Calamares não seguem usuário, disco e resumo.")
print("OK: fluxo visual usuário -> disco -> resumo")
PY
if grep -Fq '  - packagechooser' "$ROOT/scripts/patch-calamares.py" || grep -Fq '  - netinstall' "$ROOT/scripts/patch-calamares.py"; then
  fail "telas de seleção de pacotes ou Netinstall ainda aparecem no fluxo"
fi
grep -Fq 'regularExpression: /^[a-z_][a-z0-9_-]*[$]?$/' "$ROOT/scripts/patch-calamares.py" || fail "validação integral de usuário não está prevista"
grep -Fq 'regularExpression: /^[a-zA-Z0-9][-a-zA-Z0-9_]+$/' "$ROOT/scripts/patch-calamares.py" || fail "validação integral de hostname não está prevista"
grep -Fq 'maximumLength: 31' "$ROOT/scripts/patch-calamares.py" || fail "limite de usuário não está alinhado ao Calamares"
grep -Fq 'maximumLength: 63' "$ROOT/scripts/patch-calamares.py" || fail "limite de hostname não está alinhado ao Calamares"
grep -Fq 'nobody' "$ROOT/scripts/patch-calamares.py" || fail "nomes reservados do sistema não estão bloqueados na interface"
grep -Fq 're.subn(r"(?m)^    - wheel\n' "$ROOT/scripts/patch-calamares.py" || fail "duplicidade do grupo wheel não será removida"
grep -Fq 'background-color: #101010' "$ROOT/build/calamares/branding/venom/stylesheet.qss" || fail "tema monocromático VENOM ausente"
python - "$ROOT/scripts/patch-calamares.py" <<'PY'
import pathlib, sys
compile(pathlib.Path(sys.argv[1]).read_text(), sys.argv[1], "exec")
print("OK: patch Python do Calamares sintaticamente válido")
PY
if [[ -e "$ROOT/build/airootfs/usr/bin/venom-installer" || -e "$ROOT/build/airootfs/usr/share/applications/venom-installer.desktop" ]]; then
  fail "instalador próprio antigo ainda está presente"
fi
if grep -Fxq 'welcome' "$ROOT/build/packages.mate" || grep -Fxq 'partitionmanager' "$ROOT/build/packages.mate"; then
  fail "aplicativo Welcome/Partition Manager não deve entrar no perfil MATE"
fi

grep -Fxq 'firefox' "$ROOT/build/packages.mate" || fail "Firefox não está no perfil VENOM"
grep -Fxq 'grub' "$ROOT/build/packages.mate" || fail "GRUB fixo não está no perfil VENOM"
grep -Fxq 'os-prober' "$ROOT/build/packages.mate" || fail "os-prober não está no perfil VENOM"
grep -Fq 'iptvnator-bin-aur' "$ROOT/scripts/build-venom-iso.sh" || fail "IPTVnator não é preparado para a imagem"
grep -Fq 'pacman-key --populate archlinux' "$ROOT/scripts/build-venom-iso.sh" || fail "chaveiro do sistema final não está limitado ao Arch"
grep -Fq 'VENOM OS uses the complete ISO filesystem' "$ROOT/scripts/build-venom-iso.sh" || fail "a preparação ainda não declara a instalação pela imagem completa"
grep -Fq 'cp "$ROOT/build/packages.arch" "$CALAMARES_SRC/branding/packages.arch"' "$ROOT/scripts/build-venom-iso.sh" || fail "manifesto Arch não chega ao patcher do Calamares"
grep -Fq 'systemctl enable NetworkManager.service' "$ROOT/scripts/build-venom-iso.sh" || fail "NetworkManager não é ativado no Live para rede cabeada"

grep -Fq 'settings_online.write_text(settings_online_text)' "$ROOT/scripts/patch-calamares.py" || fail "instalador online próprio ausente"
grep -Fq 'settings_offline.write_text(settings_offline_text)' "$ROOT/scripts/patch-calamares.py" || fail "instalador offline próprio ausente"
grep -Fq 'efiBootLoader: "grub"' "$ROOT/scripts/patch-calamares.py" || fail "GRUB não está fixado no fluxo sem seletor de bootloader"
grep -Fq 'partition.conf ainda depende do seletor de bootloader removido.' "$ROOT/scripts/patch-calamares.py" || fail "seletor antigo de bootloader não é removido"
grep -Fq 'availableFileSystemTypes:  ["ext4"]' "$ROOT/scripts/patch-calamares.py" || fail "ext4 não é o único sistema de arquivos selecionável"
grep -Fq 'recommendedSize:    512MiB' "$ROOT/scripts/patch-calamares.py" || fail "tamanho recomendado da partição EFI não foi ajustado"
grep -Fq '  - machineid' "$ROOT/scripts/patch-calamares.py" || fail "machine-id não será regenerado"
grep -Fq 'Idioma e teclado offline devem ser herdados da imagem Live' "$ROOT/scripts/patch-calamares.py" || fail "configuração offline de idioma/teclado não está protegida"
grep -Fq 'efiBootloaderId: "VENOM OS"' "$ROOT/scripts/patch-calamares.py" || fail "identificação do GRUB/EFI não é VENOM OS"
grep -Fq 'displaymanagers:' "$ROOT/scripts/patch-calamares.py" || fail "gerenciador de sessão fixo não foi configurado"
grep -Fq 'O instalador online deve copiar a imagem VENOM OS da própria ISO.' "$ROOT/scripts/patch-calamares.py" || fail "o instalador online não copia a imagem VENOM"
grep -Fq '  - packages@online' "$ROOT/scripts/patch-calamares.py" || fail "o instalador online não atualiza a VENOM pelos repositórios Arch"
grep -Fq 'shellprocess_venom_grub_defaults.conf' "$ROOT/scripts/patch-calamares.py" || fail "padrões GRUB VENOM ausentes"
grep -Fq 'GRUB_DISTRIBUTOR="VENOM OS"' "$ROOT/scripts/patch-calamares.py" || fail "GRUB não identifica VENOM OS"
grep -Fq '  - shellprocess@venom_grub_defaults' "$ROOT/scripts/patch-calamares.py" || fail "padrões GRUB não são aplicados antes da instalação do bootloader"
grep -Fq '  - internet' "$ROOT/scripts/patch-calamares.py" || fail "o instalador online não exige internet"
grep -Fq 'update_db: true' "$ROOT/scripts/patch-calamares.py" || fail "o instalador online não atualiza a base do Pacman"
grep -Fq 'networkmanager' "$ROOT/build/packages.arch" || fail "NetworkManager ausente do sistema Arch da VENOM"
grep -Fxq 'pacman-mirrorlist' "$ROOT/build/packages.arch" || fail "mirrorlist oficial Arch ausente do instalador online"
for package in linux linux-headers linux-lts linux-lts-headers; do
  grep -Fxq "$package" "$ROOT/build/packages.arch" || fail "pacote de kernel ausente do manifesto online: $package"
  grep -Fxq "$package" "$ROOT/build/packages.mate" || fail "pacote de kernel ausente do manifesto Live: $package"
done
grep -Fq 'GRUB_DEFAULT="VENOM OS, with Linux linux-lts"' "$ROOT/scripts/patch-calamares.py" || fail "kernel LTS não está definido como padrão do GRUB"
grep -Fq 'shellprocess_venom_sudoers.conf' "$ROOT/scripts/patch-calamares.py" || fail "usuário VENOM não recebe sudo"
grep -Fq "wheel ALL=(ALL:ALL) ALL" "$ROOT/scripts/patch-calamares.py" || fail "grupo wheel não é habilitado no sudoers"
grep -Fq '  - unpackfs' "$ROOT/scripts/patch-calamares.py" || fail "o instalador online não copia a imagem VENOM"
grep -Fq 'update_system: true' "$ROOT/scripts/patch-calamares.py" || fail "o instalador online não atualiza o sistema VENOM copiado"
grep -Fq 'package_archive_copy =' "$ROOT/scripts/build-venom-iso.sh" || fail "pacotes AUR não são preservados antes da limpeza da imagem Live"
if grep -Eiq '^(endeavouros-|eos-)' "$ROOT/build/packages.arch"; then fail "manifesto online contém pacotes EndeavourOS"; fi
grep -Fq "find . -maxdepth 1 -name 'shelly-git-*.pkg.tar.zst' -exec cp -v {} \"\$PKG_DIR/\" \\;" "$ROOT/scripts/build-venom-iso.sh" || fail "pacote Shelly não é incorporado à imagem Live da VENOM"
grep -Fq 'shellprocess@venom_cleanup' "$ROOT/scripts/patch-calamares.py" || fail "limpeza final da instalação VENOM ausente"
grep -Fq 'pacman -Q calamares' "$ROOT/scripts/patch-calamares.py" || fail "remoção de Calamares não é condicional no sistema instalado"
grep -Fq 'rate-mirrors$|reflector-simple$|welcome$|iso-create-ml$' "$ROOT/scripts/patch-calamares.py" || fail "ferramentas EndeavourOS não são removidas do destino offline"
grep -Fq '/etc/polkit-1/rules.d/49-venom-calamares.rules' "$ROOT/scripts/patch-calamares.py" || fail "regra temporária Polkit não será removida do sistema instalado"
grep -Fq 'rm -f /etc/pacman.d/endeavouros-mirrorlist' "$ROOT/scripts/patch-calamares.py" || fail "mirrorlist EndeavourOS não será removida do sistema instalado"

if grep -Eq 'endeavouros|eos-' "$ROOT/build/packages.mate"; then
  fail "pacotes EndeavourOS encontrados no perfil final"
fi
grep -Fxq 'materia-gtk-theme' "$ROOT/build/packages.mate" || fail "Materia ausente"
grep -Fxq 'papirus-icon-theme' "$ROOT/build/packages.mate" || fail "Papirus ausente"
grep -Fq "picture-filename='/usr/share/backgrounds/venom/venom-wallpaper.png'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom" || fail "wallpaper padrão VENOM ausente"
grep -Fq "picture-options='zoom'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom" || fail "ajuste do wallpaper MATE ausente"
grep -Fq "magick -size 1920x1080 xc:" "$ROOT/scripts/build-venom-iso.sh" || fail "geração do wallpaper preto VENOM ausente"
grep -Fq 'install -Dm644 /etc/pacman.d/mirrorlist "$EOS_DIR/airootfs/etc/pacman.d/mirrorlist"' "$ROOT/scripts/build-venom-iso.sh" || fail "mirrorlist Arch não é incorporada à ISO"
grep -Fq "grep -Eiq 'endeavouros' /etc/pacman.d/mirrorlist" "$ROOT/scripts/build-venom-iso.sh" || fail "mirrorlist final não é protegida contra servidores EndeavourOS"
grep -Fq 'cp "$VENOM_WALLPAPER" "$EOS_DIR/airootfs/root/livewall.png"' "$ROOT/scripts/build-venom-iso.sh" || fail "wallpaper não substitui o fundo gerado pelo prepare.sh"

if grep -Eiq '^(plasma|kde|sddm|dolphin|konsole)(-|$)' "$ROOT/build/packages.mate"; then
  fail "pacotes KDE encontrados na lista MATE"
fi


# Pacman is the sole system updater; VENON must remain a separate, manual mechanism.
[[ -x "$ROOT/build/airootfs/usr/bin/venon-update" ]] || fail "comando venon-update ausente"
[[ -x "$ROOT/build/airootfs/usr/bin/venon-upgrade" ]] || fail "comando venon-upgrade ausente"
[[ ! -e "$ROOT/build/airootfs/usr/bin/venom" ]] || fail "cliente VENOM legado ainda existe"
[[ ! -e "$ROOT/build/airootfs/etc/venom/pacman.conf" ]] || fail "configuração isolada de Pacman legada ainda existe"
[[ ! -e "$ROOT/build/airootfs/etc/pacman.d/venom-mirrorlist" ]] || fail "mirrorlist VENOM legada ainda existe"
if grep -Eiq 'pacman|pacman-key|/etc/pacman' "$ROOT/build/airootfs/usr/bin/venon-update" "$ROOT/build/airootfs/usr/bin/venon-upgrade"; then
  fail "cliente VENON contém dependência ou chamada ao Pacman"
fi
grep -Fq 'venon-update' "$ROOT/scripts/build-venom-iso.sh" || fail "comando venon-update não é preparado para a imagem"
grep -Fq 'venon-upgrade' "$ROOT/scripts/build-venom-iso.sh" || fail "comando venon-upgrade não é preparado para a imagem"

pass "arquivos e escopo do build presentes"
pass "sintaxe Bash e blocos Python do compilador válidos"
printf 'AVISO: esta validação estática não executa makepkg, mkarchiso ou testes de VM.\n'
grep -Fq 'rate-mirrors$|reflector-simple$|welcome$|iso-create-ml$' "$ROOT/scripts/patch-calamares.py" || fail "ferramentas EndeavourOS não são removidas do destino offline"
grep -Fq '/etc/polkit-1/rules.d/49-venom-calamares.rules' "$ROOT/scripts/patch-calamares.py" || fail "regra temporária Polkit não será removida do sistema instalado"
grep -Fq 'rm -f /etc/pacman.d/endeavouros-mirrorlist' "$ROOT/scripts/patch-calamares.py" || fail "mirrorlist EndeavourOS não será removida do sistema instalado"

if grep -Eq 'endeavouros|eos-' "$ROOT/build/packages.mate"; then
  fail "pacotes EndeavourOS encontrados no perfil final"
fi
grep -Fxq 'materia-gtk-theme' "$ROOT/build/packages.mate" || fail "Materia ausente"
grep -Fxq 'papirus-icon-theme' "$ROOT/build/packages.mate" || fail "Papirus ausente"
grep -Fq "picture-filename='/usr/share/backgrounds/venom/venom-wallpaper.png'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom" || fail "wallpaper padrão VENOM ausente"
grep -Fq "picture-options='zoom'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom" || fail "ajuste do wallpaper MATE ausente"
grep -Fq 'magick -size 1920x1080 xc:'"'"'#101010'"'"' "$VENOM_WALLPAPER"' "$ROOT/scripts/build-venom-iso.sh" || fail "geração do wallpaper preto VENOM ausente"
grep -Fq 'install -Dm644 /etc/pacman.d/mirrorlist "$EOS_DIR/airootfs/etc/pacman.d/mirrorlist"' "$ROOT/scripts/build-venom-iso.sh" || fail "mirrorlist Arch não é incorporada à ISO"
grep -Fq 'grep -Eiq '\''endeavouros'\'' /etc/pacman.d/mirrorlist' "$ROOT/scripts/build-venom-iso.sh" || fail "mirrorlist final não é protegida contra servidores EndeavourOS"
grep -Fq 'cp "$VENOM_WALLPAPER" "$EOS_DIR/airootfs/root/livewall.png"' "$ROOT/scripts/build-venom-iso.sh" || fail "wallpaper não substitui o fundo gerado pelo prepare.sh"

if grep -Eiq '^(plasma|kde|sddm|dolphin|konsole)(-|$)' "$ROOT/build/packages.mate"; then
  fail "pacotes KDE encontrados na lista MATE"
fi

pass "arquivos e escopo do build presentes"
pass "sintaxe Bash e blocos Python do compilador válidos"
printf 'AVISO: esta validação estática não executa makepkg, mkarchiso ou testes de VM.\n'
