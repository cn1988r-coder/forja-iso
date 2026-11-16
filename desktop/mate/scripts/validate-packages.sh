#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="$ROOT/packages.x86_64"

command -v pacman >/dev/null 2>&1 || {
    echo "ERRO: pacman não encontrado. Execute em Arch Linux ou EndeavourOS." >&2
    exit 2
}

missing=0
while IFS= read -r package; do
    [[ -z "$package" || "$package" == \#* ]] && continue
    if pacman -Si "$package" >/dev/null 2>&1 || pacman -Sgq "$package" >/dev/null 2>&1; then
        printf 'OK      %s\n' "$package"
    else
        printf 'AUSENTE %s\n' "$package"
        missing=1
    fi
done < "$LIST"

if (( missing )); then
    echo "Falha: há pacotes/grupos ausentes nos repositórios atualmente configurados." >&2
    exit 1
fi

echo "Todos os nomes de pacote/grupo foram encontrados. Isso não substitui a instalação nem o teste de build."
