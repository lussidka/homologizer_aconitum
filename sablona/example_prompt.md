This is a workspace which data analysis based on the @project_description.md document. Inspect the document and create a plan for the analysis.


The main step of analysis will include

1. Loading tempura dataset and do basic characterizations:
  - range of optimal temperatures (Topt),
  - making histogram of Topt
  - summarize species, genera, and phylum included in dataset
  - Summarize the number of species in each category (psychrophile, mesophile, thermophile, hyperthermophile)

2. Selection of set of organisms for analysis. We need to pick a whole range of temperatures, ideally not to introduce confusion with phylogenetic signal. At simplest we can use  species names (not to pick more than two or three species from a single genus). Selected dataset must be a little bit bigger than 30 in case we have some drop outs.     
  - Report selected species and genera.
  - Distribution of species in each category (psychrophile, mesophile, thermophile, hyperthermophile)
  - Distribution of selected species as histogram

3. Download selected proteomes
   - Proteomes should be downloaded from uniprot database
   - Download proteomes as gzipped fasta files
   - Proteomes whould be downloaded to separate folder, for file name use proteome ID and species name
   - If more than one proteome for a species, preferably use reference proteomes
   - Include basing QC - number of sequences in proteomes, length of sequences

4. calculate mean AA composition of protein in proteom for each species
   - calculate mean AA composition, standard deviation,
   - per AA compositon per thermal category, boxplot or stripchart 
   - heatmap of AA composition, use mean value for each AA/species, normalize to mean AA in all species.
   - Identify highly variable AA (by CV)

5. Statistical analysis.
  - per-residue mean vs Topt plot
  - one-way ANOVA for Topt vs AA composition
  - Multiple testing correction for ANOVA (BH)
  - linear fit of Topt vs AA composition
  - correlation
  - PCA of AA composition
  - IVYWREL combine index - validation of the previously published index


First to write the big picture plan with some necessary implementation details.
Divided the analysis smaller controllable phases, each phase we include cvs output files and report using quarto. 
Write the plan to "analysis_plan.md"  

All necessary R packages are installed.
 - quarto, Biostrings, tidyverse, httr2