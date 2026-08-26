library(ggplot2)
library(ggtree)
library(treeio)
library(ape)
library(dplyr)
library(tidyr)
library(magrittr)

# ==========================================
# 1. NASTAVENÍ CEST K SOUBORŮM
# ==========================================
tree_file       <- "output/h_19_targets_map_rooted.tree"  # Cesta k vašemu stromu z h_19
probs_csv_file  <- "homologizer_posterior_probs.csv"             # Vaše CSV s PP (tip_name, RPB, EIF3E, ...)
phases_csv_file <- "homologizer_map_phases.csv"                  # CSV s fázemi (pokud máte; pokud ne, buňky zůstanou bez textu)
output_pdf      <- "homologizer_h19_plot.pdf"

# ==========================================
# 2. FUNKCE PRO VYKRESLENÍ (HOMOLOGIZED)
# ==========================================
homologized <- function(p, data, data_labels, offset = 0, width = 1, low = "green", mid, high = "red",
                        color = "white", colnames = TRUE, colnames_position = "bottom",
                        colnames_angle = 0, colnames_level = NULL, colnames_offset_x = 0,
                        colnames_offset_y = 0, font.size = 4, family = "", hjust = 0.5,
                        legend_title = "value") {
  colnames_position %<>% match.arg(c("bottom", "top"))
  variable <- value <- lab <- y <- NULL
  width <- width * (p$data$x %>% range(na.rm = TRUE) %>% diff) / ncol(data)
  isTip <- x <- y <- variable <- value <- from <- to <- NULL
  df <- p$data
  nodeCo <- intersect(df %>% filter(is.na(x)) %>% select(.data$parent, .data$node) %>% unlist(),
                      df %>% filter(!is.na(x)) %>% select(.data$parent, .data$node) %>% unlist())
  labCo <- df %>% filter(.data$node %in% nodeCo) %>% select(.data$label) %>% unlist()
  selCo <- intersect(labCo, rownames(data))
  isSel <- df$label %in% selCo
  df <- df[df$isTip | isSel, ]
  start <- max(df$x, na.rm = TRUE) + offset
  
  dd <- as.data.frame(data)
  dd2 <- as.data.frame(data_labels)
  i <- order(df$y)
  i <- i[!is.na(df$y[i])]
  lab <- df$label[i]
  
  dd <- dd[match(lab, rownames(dd)), , drop = FALSE]
  dd2 <- dd2[match(lab, rownames(dd2)), , drop = FALSE]
  dd$y <- sort(df$y)
  dd2$y <- sort(df$y)
  dd$lab <- lab
  dd2$lab <- lab
  
  dd <- gather(dd, variable, value, -c(lab, y))
  dd2 <- gather(dd2, variable, value, -c(lab, y))
  
  i <- which(dd$value == "")
  if (length(i) > 0) {
    dd$value[i] <- NA
    dd2$value[i] <- NA
  }
  
  if (is.null(colnames_level)) {
    dd$variable <- factor(dd$variable, levels = colnames(data))
  } else {
    dd$variable <- factor(dd$variable, levels = colnames_level)
  }
  
  V2 <- start + as.numeric(dd$variable) * width
  mapping <- data.frame(from = dd$variable, to = V2)
  mapping <- unique(mapping)
  dd$x <- V2
  dd2$x <- V2
  dd$width <- width
  dd2$width <- width
  dd[[".panel"]] <- factor("Tree")
  dd2[[".panel"]] <- factor("Tree")
  
  if (is.null(color)) {
    p2 <- p + geom_tile(data = dd, aes(x, y, fill = value), width = width, inherit.aes = FALSE)
  } else {
    p2 <- p + geom_tile(data = dd, aes(x, y, fill = value), width = width, color = color, inherit.aes = FALSE)
    p2 <- p2 + geom_text(data = dd2, aes(x, y, label = value), size = 1, inherit.aes = FALSE)
    
    dd3 <- data.frame()
    start_x <- max(dd$x)
    height <- max(dd$y)
    margin <- 0.015
    for (y_val in unique(dd$y)) {
      pp <- mean(dd[dd$y == y_val, "value"], na.rm = TRUE)
      dd4 <- data.frame(pp = pp, x = pp / 200 + margin + start_x, y = y_val)
      dd3 <- rbind(dd3, dd4)
    }
    
    p2 <- p2 + geom_segment(aes(x = start_x + margin, xend = 1 / 200 + start_x + margin, y = 0.2, yend = 0.2), size = 0.5, inherit.aes = FALSE)
    p2 <- p2 + geom_segment(aes(x = 1 / 200 + start_x + margin, xend = 1 / 200 + start_x + margin, y = 0.5, yend = height), color = "grey85", linetype = "dotted", size = 0.35, inherit.aes = FALSE)
    p2 <- p2 + geom_segment(aes(x = start_x + margin, xend = start_x + margin, y = 0.5, yend = height), color = "grey85", linetype = "dotted", size = 0.35, inherit.aes = FALSE)
    p2 <- p2 + geom_point(data = dd3, aes(x, y, color = pp), size = 1.25, inherit.aes = FALSE, show.legend = FALSE)
    p2 <- p2 + geom_text(label = "0.0", x = start_x + margin, y = -0.2, size = 1.25, color = "grey50")
    p2 <- p2 + geom_text(label = "1.0", x = start_x + margin + 1 / 200, y = -0.2, size = 1.25, color = "grey50")
  }
  
  if (methods::is(dd$value, "numeric")) {
    midpoint <- 0.5
    p2 <- p2 + scale_fill_gradient2(low = low, mid = mid, high = high, midpoint = midpoint,
                                    na.value = "white", name = legend_title, limits = c(0, 1))
    p2 <- p2 + scale_color_gradient2(low = low, mid = mid, high = high, midpoint = midpoint,
                                     na.value = "white", name = legend_title, limits = c(0, 1))
  } else {
    p2 <- p2 + scale_fill_discrete(na.value = NA, name = legend_title)
  }
  
  if (colnames) {
    y_pos <- if (colnames_position == "bottom") 0 else max(p$data$y) + 1
    mapping$y <- y_pos
    mapping[[".panel"]] <- factor("Tree")
    p2 <- p2 + geom_text(data = mapping, aes(x = to, y = y, label = from),
                         size = font.size, family = family, inherit.aes = FALSE,
                         angle = colnames_angle, nudge_x = colnames_offset_x,
                         nudge_y = colnames_offset_y, hjust = hjust)
  }
  
  p2 <- p2 + theme(legend.position = "right")
  if (!colnames) {
    p2 <- p2 + scale_y_continuous(expand = c(0, 0))
  }
  attr(p2, "heatmap_mapping") <- mapping
  return(p2)
}

# ==========================================
# 3. NAČTENÍ A PŘÍPRAVA DAT Z CSV
# ==========================================
# Načtení posteriorních pravděpodobností
probs_raw <- read.csv(probs_csv_file, header = TRUE, stringsAsFactors = FALSE)
rownames(probs_raw) <- probs_raw$tip_name
map_prob_results <- probs_raw %>% 
  select(-tip_name) %>% 
  mutate(across(everything(), as.numeric))

# Načtení popisků (přiřazených fází)
if (file.exists(phases_csv_file)) {
  phases_raw <- read.csv(phases_csv_file, header = TRUE, stringsAsFactors = FALSE)
  rownames(phases_raw) <- phases_raw$tip_name
  joint_map_phase_results <- phases_raw %>% 
    select(-tip_name) %>% 
    mutate(across(everything(), as.character))
} else {
  # Pokud soubor s fázemi nemáte, vytvoří se prázdná matice stejných rozměrů
  joint_map_phase_results <- as.data.frame(
    matrix("", nrow = nrow(map_prob_results), ncol = ncol(map_prob_results),
           dimnames = dimnames(map_prob_results)),
    stringsAsFactors = FALSE
  )
}

# ==========================================
# 4. NAČTENÍ STROMU A VYKRESLENÍ
# ==========================================
tree <- treeio::read.beast(tree_file)

p <- ggtree(tree)
p = p + geom_tiplab(size=1.5, align=T, linesize=0.25, offset=0.0008)  

p <- homologized(
  p = p, 
  data = map_prob_results, 
  data_labels = joint_map_phase_results, 
  offset = 0.015,
  low = "#EE0000", 
  mid = "#FF0099", 
  high = "#DDDDFF", 
  colnames_position = "top", 
  font.size = 1,
  width = 0.4,
  legend_title = "Posterior\nProbability"
)

p <- p + theme(
  legend.text = element_text(size = 7),
  legend.title = element_text(size = 9),
  plot.margin = margin(t = 10, r = 20, b = 10, l = 40, unit = "pt")
)

p

# Automatický výpočet výšky PDF podle počtu taxonů
pocet_taxonu <- ape::Ntip(tree)
vyska_grafu <- max(12, pocet_taxonu * 0.35)

# ==========================================
# 5. ULOŽENÍ DO PDF
# ==========================================
ggsave(
  filename = output_pdf,
  plot = p,
  width = 16,
  height = vyska_grafu,
  limitsize = FALSE
)