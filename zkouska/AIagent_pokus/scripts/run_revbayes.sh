#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: run_revbayes.sh <rev_script> <output_text> [replicate_id]" >&2
  exit 1
fi

rev_script="$1"
output_text="$2"
replicate_id="${3:-1}"

if [ ! -f "$rev_script" ]; then
  echo "RevBayes script not found: $rev_script" >&2
  exit 1
fi

mkdir -p "$(dirname "$output_text")"

echo "Running RevBayes: $rev_script -> $output_text" >&2
revbayes "$rev_script" > "$output_text" 2>&1

if [ $? -ne 0 ]; then
  echo "RevBayes failed for script: $rev_script" >&2
  exit 1
fi

echo "Finished replicate $replicate_id for $(basename "$rev_script")" >&2
