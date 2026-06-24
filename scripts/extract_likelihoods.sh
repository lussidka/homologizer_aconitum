#!/usr/bin/env bash
set -euo pipefail

logs_dir="$1"     # directory containing per-sample RevBayes log files
output_tsv="$2"   # aggregated likelihoods.tsv to produce

# This script scans RevBayes log files and extracts a single likelihood value per sample.
# Adjust the grep/awk patterns below to match how your RevBayes script writes likelihoods.

echo -e "sample\tlikelihood" > "${output_tsv}"

for f in "${logs_dir}"/*.log; do
  [ -e "$f" ] || continue
  sample=$(basename "$f" .log)
  # Try several common patterns; adapt as needed.
  lik=$(grep -E "log[ _-]?likelihood|lnL|logLikelihood|Log Likelihood" "$f" | head -n1 | awk '{print $NF}' || true)
  if [ -z "$lik" ]; then
    # If no match, you might need to change the pattern above.
    lik="NA"
  fi
  echo -e "${sample}\t${lik}" >> "${output_tsv}"
done

echo "Wrote likelihood summary to ${output_tsv}" >&2
