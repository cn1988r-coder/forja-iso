#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

for file in \
  "$ROOT/scripts/build-forja-iso.sh" \
  "$ROOT/scripts/build-container.sh" \
  "$ROOT/Dockerfile" \
  "$ROOT/build/packages.mate" \
  "$ROOT/build/airootfs/etc/dconf/profile/user" \
  "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja" \
  "$ROOT/build/airootfs/etc/lightdm/lightdm.conf.d/10-forja-live.conf" \
  "$ROOT/build/airootfs/etc/skel/.config/gtk-3.0/settings.ini" \
  "$ROOT/build/airootfs/etc/skel/.config/gtk-4.0/settings.ini" \
  "$ROOT/build/airootfs/usr/bin/forja-installer" \
  "$ROOT/build/airootfs/usr/share/applications/forja-installer.desktop"; do
  [[ -f "$file" ]] || fail "arquivo necessário ausente: $file"
done

bash -n "$ROOT/scripts/build-forja-iso.sh" || fail "erro de sintaxe no script de compilação"
bash -n "$ROOT/build/airootfs/usr/bin/forja-installer" || fail "erro de sintaxe no launcher Calamares"
bash -n "$ROOT/scripts/build-container.sh" || fail "erro de sintaxe no wrapper Docker/Podman"
python - "$ROOT/scripts/build-forja-iso.sh" <<'PY'
import pathlib, re, sys
source = pathlib.Path(sys.argv[1]).read_text()
blocks = re.findall(r"<<'PY'\n(.*?)\nPY", source, re.S)
if not blocks:
    raise SystemExit("Nenhum bloco Python foi encontrado no script de build.")
for index, block in enumerate(blocks, 1):
    compile(block, f"build-forja-iso.sh:python-block-{index}", "exec")
print(f"OK: {len(blocks)} blocos Python embutidos válidos")
PY

grep -Fq 'EOS_COMMIT="90376d8f52ab19e19073eed33d6f36c46ec7c409"' "$ROOT/scripts/build-forja-iso.sh" || fail "framework EndeavourOS sem revisão fixada"
grep -Fq 'PKGBUILDS_COMMIT="474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd"' "$ROOT/scripts/build-forja-iso.sh" || fail "receita Calamares sem revisão fixada"
grep -Fq 'SHELLY_COMMIT="6840658b19d72205c38bd320c1cef6ff3076bc7c"' "$ROOT/scripts/build-forja-iso.sh" || fail "Shelly sem revisão fixada"
grep -Fq '90376d8f52ab19e19073eed33d6f36c46ec7c409/pacman.conf' "$ROOT/Dockerfile" || fail "container sem pacman.conf fixado do EndeavourOS"
grep -Fq '474a51d4c7cb6f82bfbb2e78a7ce9a321aa5eabd/endeavouros-mirrorlist' "$ROOT/Dockerfile" || fail "container sem mirrorlist fixada do EndeavourOS"

grep -Fxq 'mate-session-manager' "$ROOT/build/packages.mate" || fail "pacote MATE ausente"
grep -Fxq 'lightdm' "$ROOT/build/packages.mate" || fail "LightDM ausente"
grep -Fxq 'mate-polkit' "$ROOT/build/packages.mate" || fail "agente Polkit do MATE ausente"
grep -Fq 'settings_offline.conf' "$ROOT/build/airootfs/usr/bin/forja-installer" || fail "launcher Calamares offline ausente"
grep -Fq 'systemctl enable lightdm.service' "$ROOT/scripts/build-forja-iso.sh" || fail "LightDM não será habilitado"
grep -Fq 'dconf update' "$ROOT/scripts/build-forja-iso.sh" || fail "banco dconf não será compilado"
grep -Fq 'branding.desc' "$ROOT/scripts/build-forja-iso.sh" || fail "rebranding do Calamares ausente"
grep -Fq 'welcome|xdg-desktop-portal-kde' "$ROOT/scripts/build-forja-iso.sh" || fail "filtro de Welcome KDE/XFCE não está configurado"
if grep -Fxq 'welcome' "$ROOT/build/packages.mate" || grep -Fxq 'partitionmanager' "$ROOT/build/packages.mate"; then
  fail "aplicativo Welcome/Partition Manager não deve entrar no perfil MATE"
fi
grep -Fq 'Forja OS' "$ROOT/build/airootfs/usr/share/applications/forja-installer.desktop" || fail "launcher Forja OS sem identificação"
grep -Fxq 'materia-gtk-theme' "$ROOT/build/packages.mate" || fail "Materia ausente"
grep -Fxq 'papirus-icon-theme' "$ROOT/build/packages.mate" || fail "Papirus ausente"
grep -Fq "picture-filename=''" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja" || fail "configuração de fundo vazio ausente"
grep -Fq "primary-color='#000000'" "$ROOT/build/airootfs/etc/dconf/db/local.d/00-forja" || fail "fundo preto não configurado"

if grep -Eiq '^(plasma|kde|sddm|dolphin|konsole)(-|$)' "$ROOT/build/packages.mate"; then
  fail "pacotes KDE encontrados na lista MATE"
fi

pass "arquivos e escopo do build presentes"
pass "sintaxe Bash do compilador válida"
printf 'AVISO: esta validação estática não executa makepkg, mkarchiso ou testes de VM.\n'
