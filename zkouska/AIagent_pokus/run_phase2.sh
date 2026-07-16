#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

manifest="work/sample_manifest.csv"
if [ ! -f "$manifest" ]; then
  manifest="scripts/data/vtupni_obsah_zkouska.csv"
fi

output_dir="results"
mkdir -p "$output_dir/sample_nex"
mkdir -p "$output_dir/rev_scripts"
mkdir -p "$output_dir/steppingstone_output"

while IFS=';' read -r sample rpb2 eif3e pocet_fazi polyploidie; do
  sample="$(echo "$sample" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\r$//')"
  rpb2="$(echo "$rpb2" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\r$//')"
  eif3e="$(echo "$eif3e" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\r$//')"
  polyploidie="$(echo "$polyploidie" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\r$//')"

  if [ -z "$sample" ] || [ "$sample" = "vzorek" ]; then
    continue
  fi
  if [ -z "$rpb2" ] || [ -z "$eif3e" ] || [ -z "$polyploidie" ]; then
    echo "Skipping sample with missing numeric values: $sample" >&2
    continue
  fi

  for gene in RPB2 EIF3E; do
    master_nex="scripts/data/${gene}_test.nex"
    out_nex="$output_dir/sample_nex/${sample}/${gene}_${sample}.nex"
    mkdir -p "$(dirname "$out_nex")"
    bash scripts/generate_sample_nex.sh "$manifest" "$sample" "$gene" "$master_nex" "$out_nex"
  done

  min_ploidy=$(( rpb2 > eif3e ? rpb2 : eif3e ))
  max_ploidy=$(( polyploidie ))
  if [ "$min_ploidy" -gt "$max_ploidy" ]; then
    echo "Skipping sample $sample: observed copy count is greater than max ploidy" >&2
    continue
  fi
  for ploidy in $(seq "$min_ploidy" "$max_ploidy"); do
    out_rev="$output_dir/rev_scripts/stepping_stone_${sample}_${ploidy}.Rev"
    mkdir -p "$(dirname "$out_rev")"
    bash scripts/generate_revbayes_script.sh "$manifest" "$sample" "$ploidy" "$out_rev"
  done

done < <(tail -n +2 "$manifest")

echo "Phase 2 generation complete. Sample NEXUS files and RevBayes scripts are in results/" >&2
