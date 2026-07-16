#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: parse_metadata.R <input_csv> <output_manifest>")
}
input_csv <- args[1]
output_manifest <- args[2]

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv)

metadata <- read.csv(input_csv, sep = ";", header = TRUE, stringsAsFactors = FALSE, strip.white = TRUE)
required <- c("vzorek", "RPB2", "Eif3E", "pocet_fazi", "polyploidie")
missing <- setdiff(required, names(metadata))
if (length(missing) > 0) stop("Missing required columns: ", paste(missing, collapse = ", "))

metadata$vzorek <- trimws(metadata$vzorek)
metadata <- metadata[metadata$vzorek != "" & !is.na(metadata$vzorek), ]
metadata$RPB2 <- as.integer(trimws(metadata$RPB2))
metadata$Eif3E <- as.integer(trimws(metadata$Eif3E))
metadata$pocet_fazi <- trimws(metadata$pocet_fazi)
metadata$polyploidie <- as.integer(trimws(metadata$polyploidie))

if (any(is.na(metadata$RPB2) | is.na(metadata$Eif3E) | is.na(metadata$polyploidie))) {
  stop("Numeric metadata columns must contain integer values for all non-empty samples")
}

output_dir <- dirname(output_manifest)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
write.table(metadata[required], file = output_manifest, sep = ";", row.names = FALSE, quote = FALSE)
cat("Wrote sample manifest to", output_manifest, "\n")
