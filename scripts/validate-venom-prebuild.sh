#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/manjaro/venom-xfce"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
mode="${1:-}"
case "$mode" in
  packages)
    for f in Packages-Desktop Packages-Live Packages-Root Packages-Mhwd; do
      [[ -s "$PROFILE/$f" ]] || fail "manifesto ausente: $f"
      awk '
        {
          line=$0
          sub(/^[[:space:]]+/, "", line)
          if (line == "" || line ~ /^#/) next
          count=split(line, fields, /[[:space:]]+/)
          package=(fields[1] ~ /^>/ ? fields[2] : fields[1])
          if (package == "") next
          if (seen[package]++) {
            print "duplicado: " package > "/dev/stderr"
            bad=1
          }
        }
        END { exit bad }
      ' "$PROFILE/$f" || fail "duplicatas em $f"
    done
    grep -Fxq calamares "$PROFILE/Packages-Live" || fail "Calamares ausente"
    ! grep -Eiq 'calamares-(git|bin)' "$PROFILE/Packages-Live" || fail "Calamares alternativo detectado"
    ! grep -Eiq 'mate-panel|mate-session|marco|caja|brisk-menu|venom-mate' "$PROFILE/Packages-Desktop" "$PROFILE/profile.conf" || fail "componentes MATE no perfil XFCE"
    echo "ETAPA 02: APROVADA"
    ;;
  package-build)
    mapfile -t files < <(find "$ROOT" -name PKGBUILD -not -path '*/.git/*' -print)
    if (("${#files[@]}" == 0)); then
      echo "ETAPA 04: NAO APLICAVEL: nenhum PKGBUILD proprio no repositorio."
      exit 0
    fi
    command -v makepkg >/dev/null || fail "makepkg indisponivel"
    for f in "${files[@]}"; do (cd "$(dirname "$f")" && makepkg --nodeps --noconfirm); done
    echo "ETAPA 04: APROVADA"
    ;;
  channels)
    command -v pacman >/dev/null || fail "pacman ausente"
    command -v pacman-mirrors >/dev/null || fail "pacman-mirrors ausente"
    branch="$(pacman-mirrors -G)"
    [[ "$branch" == stable ]] || fail "runner nao esta no branch stable do Manjaro: $branch"
    pacman -Si calamares >/dev/null || fail "Calamares nao esta nos repositorios oficiais configurados"
    pacman -Q manjaro-release manjaro-system manjaro-tools-iso >/dev/null || fail "ferramentas oficiais Manjaro ausentes"
    echo "ETAPA 05: APROVADA: ambiente stable; nenhuma promocao automatica de pacotes."
    ;;
  kernel)
    pacman -Q linux618 >/dev/null || fail "linux618 ausente no runner"
    grep -Fxq KERNEL "$PROFILE/Packages-Root" || fail "marcador KERNEL ausente"
    grep -Fxq KERNEL-headers "$PROFILE/Packages-Mhwd" || fail "KERNEL-headers ausente"
    grep -Fxq mhwd "$PROFILE/Packages-Root" || fail "MHWD ausente"
    grep -Fxq linux-firmware "$PROFILE/Packages-Root" || fail "linux-firmware ausente"
    echo "ETAPA 06: APROVADA: manifestos e ambiente de build conferidos."
    ;;
  ci)
    bash -n "$ROOT"/scripts/*.sh
    echo "ETAPA 07: APROVADA"
    ;;
  *) echo "Uso: $0 {packages|package-build|channels|kernel|ci}" >&2; exit 64 ;;
esac
