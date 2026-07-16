#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "Usage: generate_sample_nex.sh <manifest> <sample> <gene> <master_nex> <out_nex>" >&2
  exit 1
fi

manifest="$1"
sample="$2"
gene="$3"
master_nex="$4"
out_nex="$5"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$(cd "$script_dir/.." && pwd)/config.yaml"

if [ ! -f "$config_file" ]; then
  echo "Missing config.yaml at $config_file" >&2
  exit 1
fi

core_samples=$(grep -A 10 '^core_samples:' "$config_file" | sed -n 's/^[[:space:]]*-[[:space:]]*//p' | paste -sd "," -)

mkdir -p "$(dirname "$out_nex")"

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

"$rscript_cmd" "$script_dir/generate_sample_nex.R" "$manifest" "$sample" "$gene" "$master_nex" "$out_nex" "$core_samples"
