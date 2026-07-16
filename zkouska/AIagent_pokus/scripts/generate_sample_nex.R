#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 6) {
  stop("Usage: generate_sample_nex.R <manifest> <sample> <gene> <master_nex> <out_nex> <core_samples_csv>")
}
manifest <- args[1]
sample <- trimws(args[2])
gene <- args[3]
master_nex <- args[4]
out_nex <- args[5]
core_samples_csv <- args[6]

core_samples <- if (nzchar(core_samples_csv)) {
  trimws(unlist(strsplit(core_samples_csv, ",", fixed = TRUE)))
} else {
  character(0)
}

if (!file.exists(manifest)) stop("Manifest not found: ", manifest)
if (!file.exists(master_nex)) stop("Master NEXUS not found: ", master_nex)

manifest_data <- read.csv(manifest, sep = ";", stringsAsFactors = FALSE, strip.white = TRUE)
if (!"vzorek" %in% names(manifest_data)) stop("Manifest missing 'vzorek' column")

manifest_data$vzorek <- trimws(manifest_data$vzorek)
if (!sample %in% manifest_data$vzorek) stop("Sample not found in manifest: ", sample)

lines <- readLines(master_nex, warn = FALSE)

begin_taxa <- which(grepl("^(?i)\\s*BEGIN[[:space:]]+TAXA;", lines, perl = TRUE))
if (length(begin_taxa) != 1) stop("Expected exactly one BEGIN TAXA block")
end_taxa_candidates <- which(grepl("^(?i)\\s*END;", lines, perl = TRUE))
end_taxa <- end_taxa_candidates[end_taxa_candidates > begin_taxa][1]
if (is.na(end_taxa)) stop("Could not locate END; for TAXA block")

taxa_block <- lines[begin_taxa:end_taxa]

taxlabel_line <- which(grepl("(?i)TAXLABELS", taxa_block, perl = TRUE))
if (length(taxlabel_line) != 1) stop("Could not locate TAXLABELS line in TAXA block")
taxlabel_start <- taxlabel_line

terminator <- which(grepl(";", taxa_block[taxlabel_start:length(taxa_block)], fixed = TRUE))[1]
if (is.na(terminator)) stop("Could not locate terminating semicolon after TAXLABELS")
taxlabel_end <- taxlabel_start + terminator - 1

taxlabels_text <- taxa_block[taxlabel_start]
if (taxlabel_end > taxlabel_start) {
  taxlabels_text <- paste(taxlabels_text, taxa_block[(taxlabel_start + 1):taxlabel_end], collapse = " ")
}
taxlabels_text <- gsub("(?i)TAXLABELS", "", taxlabels_text, perl = TRUE)
taxlabels_text <- gsub(";", "", taxlabels_text, fixed = TRUE)
labels <- unlist(strsplit(taxlabels_text, "[[:space:]]+"))
labels <- labels[nzchar(labels)]

keep_label <- function(label) {
  if (grepl(paste0("^", sample, "(_|$)"), label, perl = TRUE)) return(TRUE)
  any(vapply(core_samples, function(core) grepl(paste0("^", core, "(_|$)"), label, perl = TRUE), logical(1)))
}
keep <- vapply(labels, keep_label, logical(1))
selected <- labels[keep]
if (length(selected) == 0) stop("No taxa selected for sample ", sample)

new_taxa_block <- c(
  taxa_block[1:(taxlabel_start - 1)],
  paste0("    TAXLABELS ", paste(selected, collapse = " "), ";"),
  taxa_block[(taxlabel_end + 1):length(taxa_block)]
)
new_taxa_block <- gsub("(?i)(DIMENSIONS[[:space:]]+ntax=)[0-9]+", paste0("\\1", length(selected)), new_taxa_block, perl = TRUE)

begin_char <- which(grepl("^(?i)\\s*BEGIN[[:space:]]+CHARACTERS;", lines, perl = TRUE))
if (length(begin_char) != 1) stop("Expected exactly one BEGIN CHARACTERS block")

matrix_offset <- which(grepl("^(?i)\\s*MATRIX", lines[(begin_char + 1):length(lines)], perl = TRUE))[1]
if (is.na(matrix_offset)) stop("Could not locate MATRIX in CHARACTERS block")
matrix_start <- begin_char + matrix_offset
matrix_terminator <- which(grepl("^(?i)\\s*END;", lines[(matrix_start + 1):length(lines)], perl = TRUE))[1]
if (is.na(matrix_terminator)) stop("Could not locate terminating END; after MATRIX")
matrix_end <- matrix_start + matrix_terminator

matrix_rows <- lines[(matrix_start + 1):(matrix_end - 1)]
matrix_rows <- matrix_rows[grepl("\\S", matrix_rows)]
row_names <- vapply(strsplit(matrix_rows, "[[:space:]]+"), function(parts) parts[1], character(1))
keep_rows <- matrix_rows[row_names %in% selected]

output_lines <- c(
  if (begin_taxa > 1) lines[1:(begin_taxa - 1)] else character(0),
  new_taxa_block,
  lines[begin_char:(matrix_start)],
  keep_rows,
  lines[matrix_end:length(lines)]
)

out_dir <- dirname(out_nex)
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
writeLines(output_lines, out_nex)
cat("Generated", out_nex, "\n")
