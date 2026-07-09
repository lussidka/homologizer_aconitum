# Proteome Composition and Thermal Adaptation in Prokaryotes

## Background

Prokaryotes inhabit an extraordinary range of thermal environments. Antarctic sea ice harbors species like *Colwellia psychrerythraea* growing optimally near 8 °C. *Escherichia coli* thrives at human body temperature. *Thermus thermophilus* prefers 65 °C. The hyperthermophile *Methanopyrus kandleri* grows at 122 °C, near the upper boundary of known life. Across the prokaryotic tree of life, optimal growth temperature spans more than 100 °C — and at every point in that range, proteins must remain folded, stable, and functional.

Protein stability at high temperature is governed by familiar physical chemistry:

- Hydrogen bonds and hydrophobic interactions weaken as temperature rises.
- Backbone flexibility increases, raising the entropic cost of the folded state.
- Some side chains become chemically labile — Asn and Gln deamidate, Cys oxidizes, Met is heat-sensitive.
- Electrostatic interactions become relatively more important for stabilization.

At low temperatures the constraints invert: proteins must avoid excessive rigidity, must catalyze reactions when thermal motion is reduced, and must resist cold-induced denaturation.

These physical pressures act on every protein in every cell. If they leave a fingerprint, that fingerprint should be visible in the **amino acid composition** of an organism's proteome — the average frequency with which each of the 20 standard residues appears across all its proteins. A planet-wide biophysical signal, encoded in genome content, detectable by simple counting, without alignment, structure, or function annotation.

Prior work (e.g. Zeldovich et al. 2007) has shown that a small set of residues — collectively abbreviated IVYWREL — correlates with optimal growth temperature across sequenced prokaryotes. The present project revisits this question on a curated, taxonomically balanced sample, and asks how strong and how clean the signal really is.

## Problem statement

Determine whether bulk proteome amino-acid composition — a signal computable from sequence alone, without alignment, structure, or functional annotation — carries enough information about an organism's thermal lifestyle to:

1. statistically separate thermal categories (psychrophile / mesophile / thermophile / hyperthermophile);
2. predict optimal growth temperature (*Topt*) as a continuous variable;
3. remain detectable after controlling for phylogenetic relatedness.

The unit of analysis is the proteome: one organism contributes one observation. The intended working set is small (~30 organisms), which constrains the statistical methods that are appropriate and motivates careful sampling.

## Working hypothesis

> Proteome amino acid composition reflects an organism's optimal growth temperature, and this signal is sufficient to distinguish thermal lifestyles even on a small, phylogenetically balanced sample.

## Data sources

Two complementary public sources:

- **TEMPURA database** (Sauer & Wang, *Microbes Environ.* 2019, doi:10.1264/jsme2.ME19073) — a curated CSV listing ~9,000 prokaryotic species with NCBI taxonomy ID, full lineage, optimal growth temperature, minimum and maximum growth temperatures, and a discrete temperature category. Provided locally as `data/200617_TEMPURA.csv`.
- **UniProt reference proteomes** — source of the proteome sequences themselves, retrieved per species selected from TEMPURA. Retrieval, caching, and provenance documentation are part of the project's scope.

## Research questions

1. **Per-organism composition.** What is the fraction of each of the 20 standard amino acids in each selected proteome, and how variable are these fractions across organisms?
2. **Category comparison.** Does mean composition differ between thermal categories? Which residues differ most, and which least, under appropriate statistical tests for small-N comparisons?
3. **Continuous relationship.** Treating *Topt* as continuous, which residue fractions correlate with it, in which direction, with what strength, and with what shape (linear vs. monotonic vs. non-monotonic)?
4. **Multivariate signal.** Considering all 20 residues jointly, do organisms separate by thermal category in a low-dimensional projection (e.g. PCA)?
5. **Phylogenetic confounding.** Closely related organisms share composition for reasons unrelated to temperature. Does the signal hold across distant lineages, or is it driven by a few clades? Does it survive when taxonomy is controlled for?
6. 

## Scope and sampling strategy

A clean comparative analysis requires a deliberate organism selection. The working set targets:

- **~30 species** drawn from TEMPURA;
- **balanced across the four thermal categories**, to the extent UniProt coverage allows;
- **spanning at least three phyla**, with no single genus over-represented (e.g. avoid stacking the set with multiple *Bacillus*), so that any apparent thermal signal is not an artifact of phylogeny.

Species lacking a UniProt reference proteome are excluded; the exclusion set is recorded as part of the data provenance. Selection criteria and the resulting organism list are documented in the report.

## Outputs

The project produces:

1. **A reproducible pipeline** that, starting from the TEMPURA file, generates every result and figure end-to-end without manual intervention.
2. **A Quarto/RMarkdown report** containing:
    - predictions registered before analysis,
    - the sample design and its justification,
    - figures covering per-organism composition, residue-level relationship to *Topt*, and a multivariate view,
    - a statistical summary of the strongest effects,
    - a comparison of predictions to results,
    - a discussion of limitations and alternative explanations for any signal observed.
3. **Intermediate data products** — per-organism composition table, summary statistics — saved as TSV/CSV so that the report's claims can be checked without rerunning the pipeline.
4. **A README** describing the project, how to reproduce it, and how to interpret its outputs.