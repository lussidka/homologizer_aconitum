# Snakefile creation

## Background

Each name represents a single sample, following a naming convention like this example: n_PPSK4_177, where "n" denotes the family, "ppsk4" is the assigned location code, and "177" is the sample number. Each sample has its own aligned sequence stored within the master NEXUS files "EIF3E_test.nex" for the EIF3E gene and "RPB2_test.nex" for the RPB2 gene.

For every sample, we want to perform a Stepping Stone analysis, the results of which will determine the exact ploidy level of that sample. To eliminate errors, this analysis must be run in three replicates. The mean likelihood values of those replicates will then be used to statistically select the model that best fits reality. This determined ploidy level will be used for all subsequent steps such as homologizer analysis involving that specific sample.

Next, the samples will be processed one by one through a Homologizer analysis. In this step, a fixed core of reference samples will be set, and a single tested sample will be added to it iteratively. After the Homologizer run, the results will be evaluated using an R script. The ideal phasing for each tested sample will then be recorded into a summary table via this script.

In the future, this final table will be used to supply the completed phasing information back into the Homologizer analysis to generate a single, final comprehensive output.

## Outputs

The project produces:

1. **A reproducible pipeline** that, starting from the nex files, generates every result end-to-end without manual intervention.
2. **A Quarto/RMarkdown report** containing:
    - how the analysis went, and what phases are succesfully completed
3. **A README** describing the project, how to reproduce it
4. **Results, scripts and tables** that are described in the popis jednotlivych kroku


## the goal of the project
The goal of this project is to generate an independent Snakemake workflow for my bioinformatics analysis. The first Snakefile covers stepping several stone analysis for each sample and their final summary. In future I will create the second Snakefile which will performs homologizer analyses and than through RStudio extracts the phasing results. 


## Workflow description

### Snakefile_part1

The workflow starts from a user-provided metadata table:

"scripts/data/vstupni_obsah_zkouska.csv"

This table contains:

* sample name
* number of recovered RPB2 sequences
* number of recovered EIF3E sequences
* total number of phases for each gene
* maximum ploidy that should be tested for the sample

The first rows of the table always contain the fixed core samples used in every analysis:

* n_VJJS2_011
* lyc_HHA1_072
* n_BHA6_068
* n_DSO2_114
* var_BOB2_057
* deg_UMA2_112

After the core samples, the table contains one or more samples that should be analysed. In future applications, the table may contain up to approximately 170 samples.

### Step 1 – Generate sample-specific NEXUS files

For every analysed sample:

1. Read the sample name from the metadata table.
2. Create a sample-specific NEXUS file for each gene by extracting the sequences of:

   * the fixed core samples
   * the currently analysed sample

Use the following files as templates:

Master NEXUS files:

"scripts/data/EIF3E_test.nex"
"scripts/data/RPB2_test.nex"

Example outputs:

"scripts/data/EIF3E_tip-test-A.nex"
"scripts/data/RPB2_tip-test-A.nex"

The generated NEXUS files should preserve exactly the same structure and formatting as the example files.

### Step 2 – Generate RevBayes scripts

Using the sample-specific NEXUS files and the metadata table:

1. Read the maximum ploidy assigned to the analysed sample.
2. Generate one RevBayes script for every tested ploidy from 1 up to the maximum ploidy.

Examples:

* maximum ploidy = 2 → generate scripts for ploidy 1 and 2
* maximum ploidy = 3 → generate scripts for ploidy 1, 2 and 3

Generated script names should follow this convention:

"stepping_stone_{sample}_{tested_ploidy}.Rev"

For example:

"stepping_stone_n_PPSK4_177_1.Rev"

Generate these scripts by modifying the provided template files according to the instructions in:

"homologizer_navod.md"

and by following these examples:

"scripts/Aconitum_tip-test-fix-A-1.Rev"
"scripts/Aconitum_tip-test-fix-A-2.Rev"

Only replace the sample-specific values and tested ploidy. The remaining script structure should remain unchanged.

### Step 3 – Run the Stepping Stone analyses

Execute every generated RevBayes script.

The complete terminal output of each run should be saved into a separate text file.

Use the following output files as references how does the output look:

"scripts/output/stepping_stone_n_PPSK4_177_1.txt"
"scripts/output/stepping_stone_n_PPSK4_177_2.txt"


### Step 4 – Perform three replicates

Each tested ploidy must be analysed three independent times.

For every replicate:

* execute the corresponding RevBayes script
* save the complete terminal output into a separate `.txt` file
* extract the marginal likelihood value on the line 64 of the .txt files
* append the extracted likelihood to the summary table without overwriting previous results

### Step 5 – Determine the optimal ploidy

For each sample:

1. Calculate the mean likelihood across the three replicates for every tested ploidy.
2. Compare the mean likelihoods of all tested ploidies.
3. Select the ploidy with the highest mean likelihood.
4. Store this ploidy as the optimal ploidy for the sample.

Then compare the best mean likelihood with all remaining mean likelihoods.

* Difference ≥ 15 → accepted automatically.
* Difference between 10 and 15 → report a warning.
* Difference < 10 → report a stronger warning.

Finally, append a new column to the summary table containing the selected optimal ploidy for every analysed sample.


### Final output of Snakefile_part1

The final output should be a single summary table containing one row per sample with:

* sample name
* tested ploidies
* likelihood values of all replicates
* mean likelihood for every tested ploidy
* selected optimal ploidy
* warning status

This summary table will serve as the input for the future `Snakefile_part2`.


## Requirements for future scalability

The workflow should be designed to process approximately 170 samples.

Independent Stepping Stone analyses should run in parallel whenever possible.

The summary table must support concurrent updates without overwriting existing results.

All generated filenames should clearly identify:

* sample name
* tested ploidy
* replicate number (when applicable)

to ensure that all intermediate and final files remain easy to identify.

## Deliverables

Generate:

- Snakefile_part1
- all missing Bash helper scripts
- all missing parsing scripts
- a README explaining how to execute the workflow

The generated workflow should be immediately executable after installing the required software.

If a workflow step cannot be implemented directly in Snakemake, create a separate Bash helper script and call it from the Snakefile.

## Coding conventions

- Keep the workflow modular.
- Each logical step should correspond to one Snakemake rule.
- Use descriptive rule names.
- Use meaningful filenames.
- Avoid duplicated code.
- Use functions or helper scripts whenever appropriate.
- Use wildcards whenever possible.

## Output structure

The pipeline should create a clear directory structure.

Suggested organization:

results/
    sample_nex/
    rev_scripts/
    steppingstone_output/
    logs/
    summary/

The final output of Snakefile_part1 should be:

results/summary/ploidy_summary.csv

containing one row per sample with:
- sample name
- tested ploidies
- likelihood values of all replicates
- mean likelihood for each tested ploidy
- selected ploidy
- warning status

Create "config.yaml" with paths for 
master_nex
output_directory
revbayes_binary
threads
replicates

## Technical requirements

- Use **Snakemake** for the workflow definition.
- Use **Bash** for all helper scripts that need to be generated.
- Use **RevBayes** syntax for all generated `.Rev` scripts, following the provided template files as closely as possible.
- Reuse the existing template scripts whenever possible instead of rewriting them from scratch.
- The Snakefile should use **wildcards** wherever possible instead of generating explicit rules for every sample.
- The workflow should be scalable and able to process approximately 170 samples without requiring modifications to the Snakefile.
- Avoid duplicating code. Keep the workflow modular and easy to maintain.
- Generate clear and informative filenames that include both the sample name and the tested ploidy.
- Do not hardcode sample names. The workflow should automatically process all samples listed in the input table.

## Important constraints

- Do not merge the two genes into one file.
- Do not modify the master NEX files.
- Always create temporary sample-specific NEX files.
- Never overwrite existing results.
- Every output filename must contain both the sample name and tested ploidy.
- The pipeline must be restartable.


## If any part is unclear

If any part of the workflow is ambiguous, stop and ask questions instead of making assumptions.
Never invent filenames or outputs.