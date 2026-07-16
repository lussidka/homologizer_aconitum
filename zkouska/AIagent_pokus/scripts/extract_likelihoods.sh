#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: extract_likelihoods.sh <revbayes_text_dir> <output_tsv>" >&2
  exit 1
fi

input_dir="$1"
output_tsv="$2"

mkdir -p "$(dirname "$output_tsv")"

echo -e "sample\tploidy\treplicate\tlikelihood" > "$output_tsv"

find "$input_dir" -type f -name '*.txt' | sort | while read -r f; do
  relpath="${f#$input_dir/}"
  sample="$(echo "$relpath" | cut -d'/' -f1)"
  ploidy="$(echo "$relpath" | cut -d'/' -f2)"
  replicate="$(basename "$f" .txt)"
  lik="$(grep -E '^-?[0-9]+(\.[0-9]+)?$' "$f" | tail -n 1 || true)"
  if [ -z "$lik" ]; then
    lik="NA"
  fi
  echo -e "${sample}\t${ploidy}\t${replicate}\t${lik}" >> "$output_tsv"
done

echo "Wrote likelihood summary to $output_tsv" >&2
