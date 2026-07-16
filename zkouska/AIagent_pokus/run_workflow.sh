#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

input_csv="scripts/data/vtupni_obsah_zkouska.csv"
manifest="work/sample_manifest.csv"
output_dir="results"

mkdir -p "$output_dir/summary"
mkdir -p "work"

bash scripts/parse_metadata.sh "$input_csv" "$manifest"

bash run_phase2.sh

replicates="${REPLICATES:-1}"

bash scripts/run_revbayes_all.sh "$output_dir/rev_scripts" "$output_dir/steppingstone_output" "$replicates"

bash scripts/extract_likelihoods.sh "$output_dir/steppingstone_output" "$output_dir/summary/likelihoods.tsv"

Rscript scripts/compile_summary.R "$output_dir/summary/likelihoods.tsv" "$output_dir/summary/ploidy_summary.csv"

echo "Workflow complete. Summary at $output_dir/summary/ploidy_summary.csv" >&2
