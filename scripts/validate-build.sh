#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

required_files=(
  "$ROOT/scripts/build-forja-iso.sh"
  "$ROOT/scripts/build-container.sh"
  "$ROOT/scripts/patch-calamares.py"
  "$ROOT/build/calamares/branding/forja/branding.desc"
  "$ROOT/build/calamares/branding/forja/stylesheet.qss"
  "$ROOT/build/calamares/branding/forja/forja-logo.svg"
  "$ROOT/Dockerfile"
  "$ROOT/.dockerignore"
  "$ROOT/build/packages.mate"
  "$ROOT/build/airootfs/etc/dconf/profile/user"
  "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja"
  "$ROOT/build/airootfs/etc/lightdm/lightdm.conf.d/10-forja-live.conf"
  "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf"
  "$ROOT/build/airootfs/etc/skel/.config/gtk-3.0/settings.ini"
  "$ROOT/build/airootfs/etc/skel/.config/gtk-4.0/settings.ini"
)
for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "arquivo necessário ausente: $file"
done

bash -n "$ROOT/scripts/build-forja-iso.sh" || fail "erro de sintaxe no script de compilação"
bash -n "$ROOT/scripts/build-container.sh" || fail "erro de sintaxe no wrapper Docker/Podman"

python - "$ROOT/scripts/build-forja-iso.sh" <<'PY'
import pathlib, re, sys
source = pathlib.Path(sys.argv[1]).read_text()
separator = chr(10)
blocks = re.findall("<<'PY'" + separator + "(.*?)" + separator + "PY", source, re.S)
if not blocks:
    raise SystemExit("Nenhum bloco Python foi encontrado no script de build.")
for index, block in enumerate(blocks, 1):
    compile(block, f"build-forja-iso.sh:python-block-{index}", "exec")
print(f"OK: {len(blocks)} blocos Python embutidos válidos")
PY

grep -Fq 'EOS_COMMIT="90376d8f52ab19e19073eed33d6f36c46ec7c409"' "$ROOT/scripts/build-forja-iso.sh" || fail "framework EndeavourOS sem revisão fixada"
grep -Fq 'PKGBUILDS_COMMIT="474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd"' "$ROOT/scripts/build-forja-iso.sh" || fail "receita Calamares sem revisão fixada"
grep -Fq 'SHELLY_COMMIT="6840658b19d72205c38bd320c1cef6ff3076bc7c"' "$ROOT/scripts/build-forja-iso.sh" || fail "Shelly sem revisão fixada"
grep -Fq 'raw.githubusercontent.com/endeavouros-team/PKGBUILDS/' "$ROOT/scripts/build-forja-iso.sh" || fail "PKGBUILD original do Calamares não está sendo obtido na revisão fixada"
grep -Fq 'raw.githubusercontent.com/Seafoam-Labs/Shelly-ALPM/' "$ROOT/scripts/build-forja-iso.sh" || fail "PKGBUILD Shelly não está sendo obtido na revisão fixada"
grep -Fq 'makepkg --syncdeps --noconfirm' "$ROOT/scripts/build-forja-iso.sh" || fail "PKGBUILD original do Calamares não é compilado"
grep -Fq 'install -m 0644 /etc/calamares/settings_offline.conf /etc/calamares/settings.conf' "$ROOT/scripts/build-forja-iso.sh" || fail "configuração offline original não é ativada"
grep -Fq 'Exec=pkexec calamares' "$ROOT/scripts/build-forja-iso.sh" || fail "atalho gráfico não inicia o Calamares diretamente"
grep -Fq 'TryExec=calamares' "$ROOT/scripts/build-forja-iso.sh" || fail "atalho gráfico não verifica o Calamares"
grep -Fq 'rm -f "$EOS_DIR/airootfs/etc/skel/.config/gtk-3.0/settings.ini"' "$ROOT/scripts/build-forja-iso.sh" || fail "configuração GTK3 duplicada pode conflitar com endeavouros-skel-liveuser"
grep -Fq 'rm -f "$EOS_DIR/airootfs/etc/skel/.config/gtk-4.0/settings.ini"' "$ROOT/scripts/build-forja-iso.sh" || fail "configuração GTK4 duplicada pode conflitar com endeavouros-skel-liveuser"
grep -Fq '/home/liveuser/.local/share/applications/calamares.desktop' "$ROOT/scripts/build-forja-iso.sh" || fail "atalho Calamares não usa o caminho real do perfil liveuser"
if grep -Fq '/usr/share/applications/calamares.desktop' "$ROOT/scripts/build-forja-iso.sh"; then
  fail "atalho Calamares aponta para um caminho não fornecido pelo perfil EndeavourOS"
fi
grep -Fq 'MAKEFLAGS="-j$(nproc)"' "$ROOT/scripts/build-forja-iso.sh" || fail "compilação paralela de pacotes não está habilitada"
grep -Fq '90376d8f52ab19e19073eed33d6f36c46ec7c409/pacman.conf' "$ROOT/Dockerfile" || fail "container sem pacman.conf fixado do EndeavourOS"
grep -Fq '474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd/endeavouros-mirrorlist' "$ROOT/Dockerfile" || fail "container sem mirrorlist fixada do EndeavourOS"
grep -Fxq '**' "$ROOT/.dockerignore" || fail "contexto Docker não exclui artefatos do build"
grep -Fxq '!Dockerfile' "$ROOT/.dockerignore" || fail "Dockerfile não foi preservado no contexto"

grep -Fxq 'mate-session-manager' "$ROOT/build/packages.mate" || fail "pacote MATE ausente"
grep -Fxq 'lightdm' "$ROOT/build/packages.mate" || fail "LightDM ausente"
grep -Fxq 'mate-polkit' "$ROOT/build/packages.mate" || fail "agente Polkit do MATE ausente"
grep -Fq 'background=#000000' "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" || fail "fundo preto do greeter LightDM ausente"
grep -Fq 'theme-name=Materia-dark' "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" || fail "tema do greeter LightDM ausente"
grep -Fq 'icon-theme-name=Papirus' "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" || fail "ícones do greeter LightDM ausentes"
grep -Fq 'cursor-theme-name=Bibata-Modern-Classic' "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" || fail "cursor do greeter LightDM ausente"
grep -Fq 'systemctl enable lightdm.service' "$ROOT/scripts/build-forja-iso.sh" || fail "LightDM não será habilitado"
grep -Fq 'dconf update' "$ROOT/scripts/build-forja-iso.sh" || fail "banco dconf não será compilado"
grep -Fq 'MENU TITLE Forja OS' "$ROOT/scripts/build-forja-iso.sh" || fail "menu de boot sem identidade Forja OS"
grep -Fq 'MENU COLOR title        1;37;40 #ffffffff #00000000 std' "$ROOT/scripts/build-forja-iso.sh" || fail "menu de boot não está em preto e branco"
grep -Fq 'splash.unlink()' "$ROOT/scripts/build-forja-iso.sh" || fail "splash gráfico upstream não será removido"
grep -Fq 'auto-entries no' "$ROOT/scripts/build-forja-iso.sh" || fail "systemd-boot sem configuração neutra"
grep -Fq 'quiet loglevel=3 vt.global_cursor_default=0' "$ROOT/scripts/build-forja-iso.sh" || fail "inicialização sem modo visual discreto"

if grep -Eq 'requiredStorage|requiredRam|chrooted_cleaner_script[.]sh|forja-installer|python - PKGBUILD' "$ROOT/scripts/build-forja-iso.sh"; then
  fail "o script contém alterações não autorizadas no fluxo do Calamares"
fi
grep -Fq 'CMAKE_BUILD_TYPE=Release' "$ROOT/scripts/build-forja-iso.sh" || fail "Calamares não está configurado para build Release"
grep -Fq 'patch-calamares.py' "$ROOT/scripts/build-forja-iso.sh" || fail "patch de branding e validação do Calamares não será aplicado"
grep -Fq 'branding: forja' "$ROOT/scripts/patch-calamares.py" || fail "configuração offline não aponta para o branding Forja"
grep -Fq 'regularExpression: /^[a-z_][a-z0-9_-]*[$]?$/' "$ROOT/scripts/patch-calamares.py" || fail "validação integral de usuário não está prevista"
grep -Fq 'regularExpression: /^[a-zA-Z0-9][-a-zA-Z0-9_]+$/' "$ROOT/scripts/patch-calamares.py" || fail "validação integral de hostname não está prevista"
grep -Fq 'maximumLength: 31' "$ROOT/scripts/patch-calamares.py" || fail "limite de usuário não está alinhado ao Calamares"
grep -Fq 'maximumLength: 63' "$ROOT/scripts/patch-calamares.py" || fail "limite de hostname não está alinhado ao Calamares"
grep -Fq 'nobody' "$ROOT/scripts/patch-calamares.py" || fail "nomes reservados do sistema não estão bloqueados na interface"
grep -Fq 're.subn(r"(?m)^    - wheel\\n' "$ROOT/scripts/patch-calamares.py" || fail "duplicidade do grupo wheel não será removida"
grep -Fq 'background-color: #11151b' "$ROOT/build/calamares/branding/forja/stylesheet.qss" || fail "tema escuro Forja ausente"
python - "$ROOT/scripts/patch-calamares.py" <<'PY'
import pathlib, sys
compile(pathlib.Path(sys.argv[1]).read_text(), sys.argv[1], "exec")
print("OK: patch Python do Calamares sintaticamente válido")
PY
if [[ -e "$ROOT/build/airootfs/usr/bin/forja-installer" || -e "$ROOT/build/airootfs/usr/share/applications/forja-installer.desktop" ]]; then
  fail "instalador próprio antigo ainda está presente"
fi
if grep -Fxq 'welcome' "$ROOT/build/packages.mate" || grep -Fxq 'partitionmanager' "$ROOT/build/packages.mate"; then
  fail "aplicativo Welcome/Partition Manager não deve entrar no perfil MATE"
fi

grep -Fxq 'materia-gtk-theme' "$ROOT/build/packages.mate" || fail "Materia ausente"
grep -Fxq 'papirus-icon-theme' "$ROOT/build/packages.mate" || fail "Papirus ausente"
grep -Fq "picture-filename=''" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja" || fail "configuração de fundo vazio ausente"
grep -Fq "primary-color='#000000'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja" || fail "fundo preto não configurado"

if grep -Eiq '^(plasma|kde|sddm|dolphin|konsole)(-|$)' "$ROOT/build/packages.mate"; then
  fail "pacotes KDE encontrados na lista MATE"
fi

pass "arquivos e escopo do build presentes"
pass "sintaxe Bash e blocos Python do compilador válidos"
printf 'AVISO: esta validação estática não executa makepkg, mkarchiso ou testes de VM.\n'
