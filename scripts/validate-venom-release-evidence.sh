#!/usr/bin/env bash
set -Eeuo pipefail
stage="${1:?Informe a etapa (10 a 15)}"
evidence_dir="${2:-validation-evidence}"
iso_sha="${3:?Informe SHA256 da ISO candidata}"
[[ "$stage" =~ ^(10|11|12|13|14|15)$ ]] || { echo "Etapa invalida" >&2; exit 64; }
file="$evidence_dir/etapa-$stage.json"
[[ -s "$file" ]] || { echo "Evidencia obrigatoria ausente: $file" >&2; exit 1; }
python3 - "$file" "$iso_sha" "$stage" <<'PY'
import json, pathlib, sys
p=pathlib.Path(sys.argv[1])
try:
    d=json.loads(p.read_text())
except Exception as e:
    raise SystemExit(f"JSON invalido em {p}: {e}")
if d.get("status") != "PASS":
    raise SystemExit(f"Etapa {sys.argv[3]} nao aprovada: status deve ser PASS")
if d.get("iso_sha256") != sys.argv[2]:
    raise SystemExit(f"Etapa {sys.argv[3]} refere-se a outra ISO")
if not d.get("tested_at") or not d.get("tester") or not d.get("evidence_file"):
    raise SystemExit(f"Etapa {sys.argv[3]} precisa de tested_at, tester e evidence_file")
proof=(p.parent / d["evidence_file"]).resolve()
if p.parent.resolve() not in proof.parents or not proof.is_file() or proof.stat().st_size == 0:
    raise SystemExit(f"Arquivo comprobatório ausente ou invalido: {proof}")
print(f"ETAPA {sys.argv[3]}: EVIDENCIA APROVADA")
PY
