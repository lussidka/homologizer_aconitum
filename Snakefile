import csv
import os

SAMPLES_FILE = "data/samples.csv"

def read_samples():
    if not os.path.exists(SAMPLES_FILE):
        return ["sample1"]
    samples = []
    with open(SAMPLES_FILE) as f:
        for row in csv.reader(f):
            if row and not str(row[0]).strip().startswith("#"):
                samples.append(str(row[0]).strip())
    return samples

SAMPLES = read_samples()

rule all:
    input:
        "results/likelihoods/likelihoods.tsv",
        "results/homologizer/homologizer_done.txt"

rule convert_samples:
    input:
        "data/samples.xlsx"
    output:
        "data/samples.csv"
    shell:
        "command -v xlsx2csv >/dev/null 2>&1 && xlsx2csv {input} {output} || (echo 'xlsx2csv not found; please convert samples.xlsx to samples.csv manually' >&2; false)"

rule generate_stepping_stone_inputs:
    input:
        samples_csv="data/samples.csv",
        input_nex="data/input.nex"
    output:
        "work/stepping_inputs/{sample}.nex"
    params:
        sample=lambda wildcards: wildcards.sample
    shell:
        "bash scripts/generate_stepping_stone_inputs.sh {input.samples_csv} {input.input_nex} {params.sample} {output}"

rule run_stepping_stone:
    input:
        stepping_in="work/stepping_inputs/{sample}.nex",
        script="scripts/stepping_stone_revbayes.R"
    output:
        "results/stepping_stone/{sample}.log"
    shell:
        "revbayes {input.script} < {input.stepping_in} > {output} 2>&1"

rule extract_likelihoods:
    input:
        expand("results/stepping_stone/{sample}.log", sample=SAMPLES)
    output:
        "results/likelihoods/likelihoods.tsv"
    shell:
        "bash scripts/extract_likelihoods.sh results/stepping_stone {output}"

rule generate_homologizer_inputs:
    input:
        likelihoods="results/likelihoods/likelihoods.tsv",
        input_nex="data/input.nex"
    output:
        "work/homologizer_inputs/homologizer_input.nex"
    shell:
        "bash scripts/generate_homologizer_inputs.sh {input.likelihoods} {input.input_nex} {output}"

rule run_homologizer:
    input:
        "work/homologizer_inputs/homologizer_input.nex",
        "scripts/homologizer_revbayes.R"
    output:
        "results/homologizer/homologizer_done.txt"
    shell:
        "revbayes scripts/homologizer_revbayes.R < {input[0]} > results/homologizer/homologizer.log 2>&1 && touch {output}"
