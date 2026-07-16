#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: compile_summary.R <likelihoods_tsv> <summary_csv>")
}
likelihoods_tsv <- args[1]
summary_csv <- args[2]

if (!file.exists(likelihoods_tsv)) stop("Likelihoods file not found: ", likelihoods_tsv)

lik <- read.table(likelihoods_tsv, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
if (!all(c("sample", "ploidy", "replicate", "likelihood") %in% names(lik))) {
  stop("Expected columns sample, ploidy, replicate, likelihood")
}

lik$likelihood <- as.numeric(lik$likelihood)

summary <- aggregate(likelihood ~ sample + ploidy, data = lik, FUN = function(x) c(mean = mean(x, na.rm = TRUE), n = length(x)))
summary <- do.call(data.frame, summary)
summary$mean_likelihood <- summary$likelihood.mean
summary$replicate_count <- summary$likelihood.n
summary$likelihood <- NULL

summary <- summary[order(summary$sample, summary$ploidy), ]

best <- do.call(rbind, lapply(split(summary, summary$sample), function(df) {
  df$rank <- rank(-df$mean_likelihood, ties.method = "first")
  df$optimal <- ifelse(df$rank == 1, "yes", "no")
  df
}))

write.csv(best[c("sample", "ploidy", "replicate_count", "mean_likelihood", "rank", "optimal")], summary_csv, row.names = FALSE, quote = FALSE)
cat("Generated summary: ", summary_csv, "\n", sep = "")
