library(dplyr)
library(tidyr)
library(readr)

# ==========================================
# 1. NASTAVENÍ CEST A PARAMETRŮ
# ==========================================
burnin <- 0.1

# Nalezení všech CSV souborů ve složce output
run_csvs <- list.files(path = "output", pattern = "\\.csv$", full.names = TRUE)
run_prefixes <- gsub("\\.csv$", "", run_csvs)

# ==========================================
# 2. FUNKCE PRO ZPRACOVÁNÍ JEDNOHO BĚHU
# ==========================================
extract_phasing_from_run <- function(prefix, burnin = 0.1) {
  genecopyFn <- paste0(prefix, ".csv")
  if (!file.exists(genecopyFn)) {
    genecopyFn <- paste0(prefix, "_targets.csv")
  }
  if (!file.exists(genecopyFn)) {
    warning(paste("Nenalezen mapovací CSV pro:", prefix))
    return(NULL)
  }
  
  genecopymap <- read.csv(genecopyFn, header = TRUE, stringsAsFactors = FALSE)
  samples <- split(genecopymap$Subgenome, genecopymap$Sample)
  loci <- names(genecopymap)[3:length(genecopymap)]
  
  # Ošetření rozdílu v prefixu log souborů (přidání pojednom_)
  log_prefix <- prefix
  if (!any(file.exists(paste0(log_prefix, "_locus_1_phase.log")))) {
    log_prefix <- gsub("/h_", "/h_pojednom_", prefix)
  }
  
  run_results <- list()
  
  for (sample_name in names(samples)) {
    sample_tips <- as.character(samples[[sample_name]])
    
    for (i in seq_along(loci)) {
      locus_name <- loci[i]
      
      # Hledání log souboru (s původním i upraveným prefixem)
      f_in <- paste0(log_prefix, "_locus_", i, "_phase.log")
      if (!file.exists(f_in)) {
        f_in <- paste0(prefix, "_locus_", i, "_phase.log")
      }
      
      if (!file.exists(f_in)) {
        # Pokud soubor opravdu neexistuje, přeskočíme
        next
      }
      
      # Načtení MCMC logu
      d <- read.table(f_in, header = TRUE, sep = "\t", stringsAsFactors = FALSE, row.names = 1)
      start_row <- max(1, floor(nrow(d) * burnin))
      d <- d[start_row:nrow(d), , drop = FALSE]
      
      # Ověření přítomnosti tipů v logu
      valid_tips <- intersect(sample_tips, names(d))
      if (length(valid_tips) == 0) next
      
      d1 <- d[, valid_tips, drop = FALSE]
      joint_tbl <- as.data.frame(table(d1, dnn = valid_tips), stringsAsFactors = FALSE)
      
      if (nrow(joint_tbl) == 0 || sum(joint_tbl$Freq) == 0) next
      
      joint_tbl$joint_prob <- joint_tbl$Freq / sum(joint_tbl$Freq)
      map_idx <- which.max(joint_tbl$joint_prob)
      
      # Výpočet marginální pravděpodobnosti
      for (tip in valid_tips) {
        m_tbl <- as.data.frame(table(d[[tip]]), stringsAsFactors = FALSE)
        m_tbl$marginal_prob <- m_tbl$Freq / sum(m_tbl$Freq)
        
        map_phase_val <- as.character(joint_tbl[map_idx, tip])
        prob_row <- m_tbl[m_tbl$Var1 == map_phase_val, ]
        marginal_pp <- if (nrow(prob_row) > 0) prob_row$marginal_prob else 0.0
        
        run_results[[length(run_results) + 1]] <- data.frame(
          run_prefix = basename(prefix),
          sample = sample_name,
          tip_name = tip,
          locus = locus_name,
          locus_idx = i,
          map_phase = map_phase_val,
          posterior_prob = marginal_pp,
          joint_map_prob = joint_tbl$joint_prob[map_idx],
          stringsAsFactors = FALSE
        )
      }
    }
  }
  
  if (length(run_results) == 0) {
    warning(paste("Pro prefix", prefix, "nebyla nalezena žádná data (zkontrolovány soubory logů)."))
    return(NULL)
  }
  
  return(bind_rows(run_results))
}

# ==========================================
# 3. EXTRAKCE PŘES VŠECHNY BĚHY
# ==========================================
all_runs_list <- list()
for (pfx in run_prefixes) {
  message(paste("Zpracovávám:", pfx))
  res <- extract_phasing_from_run(pfx, burnin = burnin)
  if (!is.null(res)) {
    all_runs_list[[pfx]] <- res
  }
}

# Sloučení do jedné tabulky
all_data_long <- bind_rows(all_runs_list)

# ==========================================
# 4. FINÁLNÍ ŠIROKÉ TABULKY
# ==========================================
# A) Matice přiřazených fází (MAP phase)
map_phases_matrix <- all_data_long %>%
  distinct(tip_name, locus, .keep_all = TRUE) %>%
  select(tip_name, locus, map_phase) %>%
  pivot_wider(names_from = locus, values_from = map_phase, values_fill = "")

# B) Matice posteriorních pravděpodobností (PP)
posterior_probs_matrix <- all_data_long %>%
  distinct(tip_name, locus, .keep_all = TRUE) %>%
  select(tip_name, locus, posterior_prob) %>%
  pivot_wider(names_from = locus, values_from = posterior_prob, values_fill = NA)

# Zobrazení výsledků
print(head(map_phases_matrix))
print(head(posterior_probs_matrix))

# ==========================================
# 5. ULOŽENÍ VÝSLEDKŮ DO CSV
# ==========================================

# 1. Matice nejlepších fází (MAP)
write_csv(map_phases_matrix, "homologizer_map_phases.csv")

# 2. Matice marginálních posteriorních pravděpodobností
write_csv(posterior_probs_matrix, "homologizer_posterior_probs.csv")

# 3. Kompletní detailní tabulka (všechny sloupce: sample, tip, locus, phase, PP, joint_prob)
#write_csv(all_data_long, "homologizer_all_results_long.csv")
