
library(tidyverse)

# 1. Načtení dat (oddělovač je středník, -999999.99 se automaticky nahradí za NA)
df <- read_delim("results_ss.csv", delim = ";", na = c("-999999.99", "NA", ""))

# 2. Výpočet průměru, SD a rozpětí pro každý řádek
df_summary <- df %>%
  rowwise() %>%
  mutate(
    median_ML  = round(median(c_across(run1:run5), na.rm = TRUE), 3),
    sd_ML    = round(sd(c_across(run1:run5), na.rm = TRUE), 3),
    min_ML   = round(min(c_across(run1:run5), na.rm = TRUE), 3),
    max_ML   = round(max(c_across(run1:run5), na.rm = TRUE), 3),
    range_ML = round(max_ML - min_ML, 3)
  ) %>%
  ungroup()


# Zobrazení výsledku v konzoli
print(df_summary)

# 3. Uložení rozšířené tabulky do nového CSV
write_delim(df_summary, "results_ss_summary.csv", delim = ";")

# Převedení dat do dlouhého formátu (long format) pro ggplot
df_long <- df %>%
  pivot_longer(cols = starts_with("run"), names_to = "run", values_to = "ML") %>%
  filter(!is.na(ML))

# Graf: Bodový graf jednotlivých běhů s vyznačeným průměrem a chybovou úsečkou (±SD)
ggplot(df_summary, aes(x = factor(ploidy), y = median_ML, color = factor(ploidy))) +
  geom_pointrange(aes(ymin = median_ML - sd_ML, ymax = median_ML + sd_ML), size = 0.8) +
  geom_jitter(data = df_long, aes(y = ML), width = 0.1, alpha = 0.4) +
  facet_wrap(~ sample, scales = "free_y") +
  theme_minimal() +
  labs(
    title = "Marginal Likelihood stability across runs",
    x = "Tested Ploidy / Tips",
    y = "Marginal Likelihood (lnL)",
    color = "Ploidy"
  )

porovnej_vzorky <- function(vzorky, sloupcu = 2) {
  # Filtrování dat pro všechny zadané vzorky v seznamu
  sub_summary <- df_summary %>% filter(sample %in% vzorky)
  sub_long    <- df_long %>% filter(sample %in% vzorky)
  
  ggplot(sub_summary, aes(x = factor(ploidy), y = mean_ML, color = factor(ploidy))) +
    geom_pointrange(aes(ymin = mean_ML - sd_ML, ymax = mean_ML + sd_ML), size = 0.9) +
    geom_jitter(data = sub_long, aes(y = ML), width = 0.1, alpha = 0.4, size = 2) +
    facet_wrap(~ sample, ncol = sloupcu, scales = "free_y") +
    theme_minimal(base_size = 13) +
    labs(
      title = "Porovnání vybraných vzorků",
      x = "Tested Ploidy / Tips",
      y = "Marginal Likelihood (lnL)",
      color = "Ploidy"
    )
}
#mrizka 2*2
porovnej_vzorky(c(
  "c_MDKH8_075", 
  "c_MDKH8_075_60", 
  "c_MDKH8_075_70", 
  "c_MDKH8_075_80"
))

#sloupce
porovnej_vzorky(c("c_MDKH8_075", "c_MDKH8_075_100", "c_MDKH8_075_2k", "c_MDKH8_075_5k"), sloupcu = 4)

porovnej_vzorky(c("c_MDKH8_075", "c_RHSK1_182"))

porovnej_vzorky(c("c_MDKH8_075", 
                  "c_MDKH8_075_60", 
                  "c_MDKH8_075_70", 
                  "c_MDKH8_075_80",
                  "c_MDKH8_075_90"
                  "c_MDKH8_075_100"))

