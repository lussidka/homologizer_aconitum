## Rules for Dynamic RevBayes Script Generation (.Rev)

The Snakemake workflow must automatically generate a custom`.Rev` script for each target sample and each tested ploidy configuration. 

Use the provided scripts (`Aconitum_tip-test-fix-A-1.Rev` and `Aconitum_tip-test-fix-A-2.Rev`) as global templates. For each sample (after the core samples: n_VJJS2_011; lyc_HHA1_072; n_BHA6_068; n_DSO2_114; var_BOB2_057; deg_UMA2_112) in the metadata CSV, the script template must be modified programmatically according to the following rules.

### 1. Metadata Parameters Mapping
From the input table `vtupni_obsah_zkouska.csv`, extract the following variables for the currently processed sample:
* `SAMPLE_ID` = value from the `vzorek` column (e.g., `n_PPSK4_177`)
* `RPB2_COUNT` = integer from the `RPB2` column (number of copies for locus 1)
* `EIF3E_COUNT` = integer from the `Eif3E` column (number of copies for locus 2)
* `MAX_COPIES` = integer from the "polyploidie" column
* `TESTED_PLOIDY` = The current ploidy level being tested for the sample (the workflow will iterate over this based on your experiment setup).


### 2. Output File and Alignments Updates
* **Output Filename:** Modify the `output_file` variable dynamically:
    output_file = "output/stepping_stone_" + SAMPLE_ID + "_" + TESTED_PLOIDY
    
* **Alignments:** Replace the hardcoded data paths with the sample-specific NEXUS file paths:
    alignments = ["data/" + SAMPLE_ID + "_RPB2.nex", "data/" + SAMPLE_ID + "_EIF3E.nex"]


### 3. Logic for Balancing Loci (Missing Taxa / BLANKs)
To ensure both loci have the same number of copies (`MAX_COPIES`), the script must dynamically add missing taxa blocks right after reading character data. 

**Rule:** Compare `RPB2_COUNT` and `EIF3E_COUNT`. If one is smaller than `MAX_COPIES`, generate `addMissingTaxa` lines for the difference using the suffix `_BLANK`.

* **If `RPB2_COUNT < MAX_COPIES`:**
    Add to the script:

    data[1].addMissingTaxa("SAMPLE_ID_BLANK")
    
* **If `EIF3E_COUNT < MAX_COPIES`:**
    Add to the script:
    
    data[2].addMissingTaxa("SAMPLE_ID_BLANK")
    

*Example for `n_PPSK4_177` (where RPB2=1, EIF3E=1, Max=1): No blanks are needed for balancing. However, if a configuration requires a dummy/blank subgenome to test a specific ploidy hypothesis (as seen in the template), explicitly insert:*
```json
data[1].addMissingTaxa("n_PPSK4_177_BLANK")
data[2].addMissingTaxa("n_PPSK4_177_BLANK") 

4.3. Balancing Loci Copies (Dynamic BLANK insertion)
Both loci (data[1] for RPB2, data[2] for EIF3E) must have the exact same number of copies.

If RPB2_COUNT < MAX_COPIES, calculate the difference D = MAX_COPIES - RPB2_COUNT. Generate D lines of data[1].addMissingTaxa("{TARGET_SAMPLE}_BLANKX") (where X can be an increment if D > 1, or just _BLANK if D=1).

If EIF3E_COUNT < MAX_COPIES, do the same for data[2].

Note: Retain the static blank definitions for reference samples exactly as in the template (e.g., deg_UMA2_112_copy2, n_VJJS2_011_copy3).

4.4. Setting Initial Phase (Partially Fixed, Partially Dynamic)
The initial phase setup block (setHomeologPhase) must contain two parts:

A. The Fixed Reference Block:
These lines MUST be included identically in EVERY generated script, regardless of the target sample:

for (i in 1:num_loci) {
data[i].setHomeologPhase("deg_UMA2_112_copy1", "deg_UMA2_112_A")
data[i].setHomeologPhase("deg_UMA2_112_copy2", "deg_UMA2_112_B")
}

And the separate locus-specific loops for n_VJJS2_011:

# For Locus 1 (RPB2)
for (i in 1:1) {
    data[i].setHomeologPhase("n_VJJS2_011_copy1", "n_VJJS2_011_A")
    data[i].setHomeologPhase("n_VJJS2_011_copy2", "n_VJJS2_011_B")
    data[i].setHomeologPhase("n_VJJS2_011_copy3", "n_VJJS2_011_C")
}
# For Locus 2 (EIF3E)
for (i in 2:2) {
    data[i].setHomeologPhase("n_VJJS2_011_copy1", "n_VJJS2_011_A")
    data[i].setHomeologPhase("n_VJJS2_011_copy2", "n_VJJS2_011_B")
    data[i].setHomeologPhase("n_VJJS2_011_copy3", "n_VJJS2_011_C")
}

B. The Dynamic Target Sample Block:
Inside the for (i in 1:num_loci) loop, you must map the copies/blanks of the TARGET_SAMPLE to letters (A, B, C, D) based on the MAX_COPIES.
For example, if testing n_PPSK4_177 with 2 copies (one real, one BLANK):

data[i].setHomeologPhase("{TARGET_SAMPLE}_copy1", "{TARGET_SAMPLE}_A")
data[i].setHomeologPhase("{TARGET_SAMPLE}_BLANK", "{TARGET_SAMPLE}_B")


For example, if testing a sample with TARGET_PLOIDY = 4 having 2 real copies and 2 BLANKs:

data[i].setHomeologPhase("{TARGET_SAMPLE}_copy1", "{TARGET_SAMPLE}_A")
data[i].setHomeologPhase("{TARGET_SAMPLE}_copy2", "{TARGET_SAMPLE}_B")
data[i].setHomeologPhase("{TARGET_SAMPLE}_BLANK_1", "{TARGET_SAMPLE}_C")
data[i].setHomeologPhase("{TARGET_SAMPLE}_BLANK_2", "{TARGET_SAMPLE}_D")

4.5. Phasing Proposals / Moves (Crucial Difference for Ploidy Testing)
This section dictates the hypothesis testing and changes based on TESTED_TIPS.

Always include the fixed proposal for the reference:
moves[++mvi] = mvHomeologPhase(ctmc[i], "deg_UMA2_112_A", "deg_UMA2_112_B", weight=2)

Dynamic Condition for the Target Sample:

IF TESTED_TIPS == 1: Do NOT add any mvHomeologPhase lines for the TARGET_SAMPLE.

IF TESTED_TIPS == 2: Add the following line to allow phasing between two alleles:

moves[++mvi] = mvHomeologPhase(ctmc[i], "{TARGET_SAMPLE}_A", "{TARGET_SAMPLE}_B", weight=2)

IF TESTED_TIPS > 2: Generate combinatorial moves for all letters up to the tested tip count (e.g., A vs B, B vs C, A vs C, A vs D, B vs D, C vs D).
