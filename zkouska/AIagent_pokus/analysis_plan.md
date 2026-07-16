# Phase 1: Analysis Plan for Bash/R workflow

## Overview

This project will create a pure Bash/R workflow in the `zkouska` workspace that:

- reads a metadata table of core and target samples
- generates sample-specific NEXUS input files for both genes (`EIF3E` and `RPB2`)
- generates RevBayes stepping-stone scripts for each tested ploidy per sample
- executes RevBayes replicates, capturing full terminal output
- parses marginal likelihood values from output files
- computes mean likelihoods and selects the optimal ploidy per sample
- writes a single final summary table suitable for future homologizer analysis

The workflow will be developed as standalone Bash and R scripts first. A Snakemake wrapper will be created at the end to connect all previously created scripts after the whole analysis is complete.

## Existing Files and Their Roles

### Required inputs

- `zkouska/scripts/data/vstupni_obsah_zkouska.csv`
  - metadata table with sample names and maximum ploidy
- `zkouska/scripts/data/EIF3E_test.nex`
  - master NEXUS alignment for EIF3E
- `zkouska/scripts/data/RPB2_test.nex`
  - master NEXUS alignment for RPB2
- `zkouska/scripts/Aconitum_tip-test-fix-A-1.Rev`
- `zkouska/scripts/Aconitum_tip-test-fix-A-2.Rev`
  - example RevBayes script templates
- `zkouska/homologizer_navod.md`
  - documentation for RevBayes/homologizer-specific modifications
- `zkouska/RevBayes_script_generation.md`
  - authoritative rules for generating sample-specific RevBayes stepping-stone scripts, including output naming, sample-specific alignments, missing taxa insertion, fixed and dynamic homeolog phase setup, and phase move generation

### Example data and outputs

- `zkouska/scripts/data/EIF3E_tip-test-A.nex`
- `zkouska/scripts/data/RPB2_tip-test-A.nex`
  - sample-specific example NEXUS files
- `zkouska/scripts/output/stepping_stone_n_PPSK4_177_1.txt`
- `zkouska/scripts/output/stepping_stone_n_PPSK4_177_2.txt`
  - example RevBayes execution logs showing marginal likelihood output

### Existing pipeline artifacts

- `zkouska/Snakefile_part1`
  - removed because the workflow is now handled by Bash/R scripts
- root `Snakefile`
  - unrelated legacy file and left untouched

## Proposed Output Structure

```
zkouska/
  config.yaml
  run_workflow.sh
  analysis_plan.md
  results/
    sample_nex/
      {sample}/
        RPB2_{sample}.nex
        EIF3E_{sample}.nex
    rev_scripts/
      stepping_stone_{sample}_{ploidy}.Rev
    steppingstone_output/
      {sample}/{ploidy}/replicate_{replicate}.txt
    summary/
      ploidy_summary.csv
```

## Input Files

- `zkouska/scripts/data/vstupni_obsah_zkouska.csv`
- `zkouska/scripts/data/EIF3E_test.nex`
- `zkouska/scripts/data/RPB2_test.nex`
- `zkouska/scripts/Aconitum_tip-test-fix-A-1.Rev`
- `zkouska/scripts/Aconitum_tip-test-fix-A-2.Rev`
- `zkouska/homologizer_navod.md`

## Intermediate Files

- sample-specific NEXUS files per gene: `results/sample_nex/{sample}/EIF3E_{sample}.nex`, `results/sample_nex/{sample}/RPB2_{sample}.nex`
- generated RevBayes scripts: `results/rev_scripts/stepping_stone_{sample}_{ploidy}.Rev`
- RevBayes run outputs: `results/steppingstone_output/{sample}/{ploidy}/replicate_{replicate}.txt`
- extracted likelihood table: `results/summary/likelihoods.tsv`

## Final Outputs

- `results/summary/ploidy_summary.csv`
  - one row per tested sample
  - tested ploidies
  - replicate likelihoods
  - mean likelihood per ploidy
  - selected optimal ploidy
  - warning status

## Workflow Steps and Dependency Graph

### Step 1: Parse metadata and create manifest

Input:
- metadata table

Output:
- `work/sample_manifest.csv`

### Step 2: Generate sample-specific NEXUS files for both genes

Input:
- master NEXUS files
- sample manifest

Output:
- `results/sample_nex/{sample}/RPB2_{sample}.nex`
- `results/sample_nex/{sample}/EIF3E_{sample}.nex`

### Step 3: Generate RevBayes stepping-stone scripts

Input:
- sample manifest
- sample-specific NEXUS files
- example RevBayes templates
- max ploidy values

Output:
- `results/rev_scripts/stepping_stone_{sample}_{ploidy}.Rev`

### Step 4: Execute RevBayes for each replicate

Input:
- generated RevBayes scripts
- RevBayes binary

Output:
- `results/steppingstone_output/{sample}/{ploidy}/replicate_{replicate}.txt`

### Step 5: Extract marginal likelihoods

Input:
- RevBayes output `.txt` files

Output:
- `results/summary/likelihoods.tsv`

### Step 6: Compute mean likelihood and select optimal ploidy

Input:
- likelihood summary table

Output:
- `results/summary/ploidy_summary.csv`

### Step 7: Orchestrate with Bash/R

- `run_workflow.sh` ties all phases together
- `config.yaml` stores paths and settings

## Helper Scripts

The workflow uses Bash wrappers and R helpers in `zkouska/scripts`:

- `scripts/parse_metadata.sh`
  - reads the metadata CSV and writes `work/sample_manifest.csv`
- `scripts/generate_sample_nex.sh`
  - generates sample-specific NEXUS files from master alignments and core sample metadata
- `scripts/generate_revbayes_script.sh`
  - generates RevBayes stepping-stone scripts per sample and ploidy
- `scripts/run_revbayes.sh`
  - executes RevBayes and captures output
- `scripts/run_revbayes_all.sh`
  - runs all generated RevBayes scripts for the configured replicates
- `scripts/extract_likelihoods.sh`
  - extracts likelihood records into `results/summary/likelihoods.tsv`
- `scripts/compile_summary.R`
  - aggregates likelihoods and writes the final ploidy summary CSV

## Phase Breakdown

### Phase 1: Analysis plan

Objective:
- inspect templates and examples
- infer the full workflow
- document assumptions, input/output relationships, and the implementation roadmap

Deliverable:
- `analysis_plan.md`

### Phase 2: Generate sample-specific NEXUS files

Objective:
- build sample-specific `EIF3E` and `RPB2` NEXUS files from the master alignments

Inputs:
- `zkouska/scripts/data/EIF3E_test.nex`
- `zkouska/scripts/data/RPB2_test.nex`
- `zkouska/scripts/data/vstupni_obsah_zkouska.csv`

Outputs:
- `results/sample_nex/{sample}/EIF3E_{sample}.nex`
- `results/sample_nex/{sample}/RPB2_{sample}.nex`

Helper scripts:
- `scripts/generate_sample_nex.sh`

### Phase 3: Generate RevBayes scripts for tested ploidies

Objective:
- create one RevBayes script for each sample and each ploidy value up to `max_ploidy`

Inputs:
- sample metadata
- sample-specific NEXUS files
- RevBayes template scripts

Outputs:
- `results/rev_scripts/stepping_stone_{sample}_{ploidy}.Rev`

Helper scripts:
- `scripts/generate_revbayes_script.sh`

### Phase 4: Run RevBayes and capture output

Objective:
- execute RevBayes for each generated script and replicate

Inputs:
- generated `.Rev` scripts
- RevBayes binary

Outputs:
- `results/steppingstone_output/{sample}/{ploidy}/replicate_{replicate}.txt`

Helper scripts:
- `scripts/run_revbayes.sh`
- `scripts/run_revbayes_all.sh`

### Phase 5: Extract outputs and collect likelihoods

Objective:
- extract marginal likelihoods from RevBayes run outputs into a single table

Inputs:
- output `.txt` files

Outputs:
- `results/summary/likelihoods.tsv`

Helper scripts:
- `scripts/extract_likelihoods.sh`

### Phase 6: Determine optimal ploidy and warnings

Objective:
- compute mean likelihoods, select best ploidy, and generate a summary table

Inputs:
- extracted likelihood table

Outputs:
- `results/summary/ploidy_summary.csv`

Helper scripts:
- `scripts/compile_summary.R`

### Phase 7: Orchestrate with `run_workflow.sh`

Objective:
- combine all phases in a pure Bash/R driver
- ensure restartability and reproducibility

Deliverable:
- `run_workflow.sh`
- `config.yaml`
- Bash/R helper scripts

## Assumptions and Ambiguities

1. `zkouska/1stsnakefile_promt.md` asked for a plan review before implementation. That phase is complete.
2. The actual workflow now uses Bash/R only, with no Python dependency in `zkouska`.
3. The required dynamic RevBayes logic is defined in `zkouska/RevBayes_script_generation.md` and must drive sample script generation.
4. `run_workflow.sh` is the workflow orchestrator, not a Snakefile.
5. The metadata table provides copy counts and maximum ploidy, which supports automated blank taxa generation and phase mapping.
6. The `config.yaml` file should centralize paths, replicates, and RevBayes settings.
7. The root `Snakefile` remains a legacy artifact and is not part of this new pipeline.

## Potential Risks

- RevBayes script generation could require additional sample-specific metadata not currently available.
- The NEXUS extraction must preserve formatting and taxa ordering exactly.
- Running many RevBayes analyses in parallel may overload available compute resources.
- The likelihood extraction code must tolerate different output formats from RevBayes.

## Recommended Next Phase

Proceed to Phase 2 after approval:

- implement sample-specific NEXUS generation in R
- validate generated files against existing example NEXUS templates
- run a small test sample through the Bash/R pipeline

After review, move to Phase 3:

- generate RevBayes scripts using Bash/R wrappers
- run additional test samples through the pipeline
- prepare the final Snakemake wrapper for the completed workflow

## Notes

- `analysis_plan.md` is now aligned to the Bash/R-only workflow.
- `zkouska/Snakefile_part1` has been removed.
- `run_workflow.sh` is the central workflow entrypoint.
