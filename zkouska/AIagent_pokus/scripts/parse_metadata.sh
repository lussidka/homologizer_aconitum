#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: parse_metadata.sh <input_csv> <output_manifest>" >&2
  exit 1
fi

input_csv="$1"
output_manifest="$2"

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

"$rscript_cmd" "$script_dir/parse_metadata.R" "$input_csv" "$output_manifest"
