Snakemake + RevBayes pipeline scaffolding

Structure:
- data/: samples.xlsx (or samples.csv) and input.nex
- scripts/: Bash helpers + placeholder RevBayes scripts
- work/: intermediate inputs
- results/: stepping stone logs, likelihoods, homologizer outputs

Usage:
- Install dependencies: `snakemake`, `revbayes`, `xlsx2csv` (optional)
- Populate `data/samples.xlsx` or `data/samples.csv` and `data/input.nex`
- Run: `snakemake -j <cores>`
