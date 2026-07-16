#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: run_revbayes_all.sh <rev_scripts_dir> <output_dir> [replicates]" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rev_scripts_dir="$1"
output_dir="$2"
replicates="${3:-1}"

find "$rev_scripts_dir" -maxdepth 1 -name 'stepping_stone_*.Rev' | sort | while read -r rev_script; do
  name="$(basename "$rev_script" .Rev)"
  sample="$(echo "$name" | sed -E 's/^stepping_stone_(.*)_([0-9]+)$/\1/')"
  ploidy="$(echo "$name" | sed -E 's/^stepping_stone_(.*)_([0-9]+)$/\2/')"
  if [ -z "$sample" ] || [ -z "$ploidy" ]; then
    echo "Skipping invalid rev script name: $rev_script" >&2
    continue
  fi
  for replicate in $(seq 1 "$replicates"); do
    output_text="$output_dir/$sample/$ploidy/replicate_${replicate}.txt"
    mkdir -p "$(dirname "$output_text")"
    bash "$script_dir/run_revbayes.sh" "$rev_script" "$output_text" "$replicate"
  done
done
