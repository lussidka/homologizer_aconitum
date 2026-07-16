#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 4 ]; then
  echo "Usage: generate_revbayes_script.sh <manifest> <sample> <tested_ploidy> <out_rev>" >&2
  exit 1
fi
manifest="$1"
sample="$2"
tested_ploidy="$3"
out_rev="$4"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rscript_cmd="${RSCRIPT:-}"
if [ -z "$rscript_cmd" ]; then
  if command -v Rscript >/dev/null 2>&1; then
    rscript_cmd="Rscript"
  elif command -v Rscript.exe >/dev/null 2>&1; then
    rscript_cmd="Rscript.exe"
  else
    for candidate in \
      "C:/Program Files/R/R-*/bin/x64/Rscript.exe" \
      "C:/Program Files/R/R-*/bin/i386/Rscript.exe" \
      "C:/Program Files (x86)/R/R-*/bin/x64/Rscript.exe" \
      "C:/Program Files (x86)/R/R-*/bin/i386/Rscript.exe"; do
      matched=$(compgen -G "$candidate" | head -n 1 || true)
      if [ -n "$matched" ]; then
        rscript_cmd="$matched"
        break
      fi
    done
  fi
fi

if [ -z "$rscript_cmd" ]; then
  echo "Rscript not found. Install R or add it to PATH." >&2
  exit 1
fi

"$rscript_cmd" "$script_dir/generate_revbayes_script.R" "$manifest" "$sample" "$tested_ploidy" "$out_rev"
