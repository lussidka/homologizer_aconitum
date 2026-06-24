#!/usr/bin/env bash
set -euo pipefail

samples_csv="$1"   # path to samples.csv
input_nex="$2"     # path to original input.nex
sample_name="$3"   # sample identifier (wildcard)
output_file="$4"   # output stepping stone input file for this sample

# This script should extract the relevant taxa/partitions for $sample_name
# from $input_nex and/or $samples_csv and emit a RevBayes/NEXUS input
# tailored for Stepping Stone analyses.

# TODO: Replace the placeholder logic below with your custom parsing rules.
# Example ideas:
# - Use grep/awk/sed to extract taxa blocks from $input_nex
# - Use samples listed in $samples_csv to select sequences
# - Modify RevBayes input variables (e.g., model settings) per-sample

# Placeholder implementation: prepend a header and copy the input NEXUS
{
  echo "# Stepping Stone input generated for sample: ${sample_name}"
  echo "# Source: ${input_nex}"
  echo
  cat "${input_nex}"
} > "${output_file}"

echo "Generated stepping stone input for ${sample_name}: ${output_file}" >&2
