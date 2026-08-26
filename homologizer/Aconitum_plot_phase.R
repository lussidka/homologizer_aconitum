
genecopyFn='output/h_20_targets.csv'
tree_file = 'output/h_20_targets_20kgen_map_rooted.tree'
input_dir = 'output/'
output_dir = 'output/'
prefix = 'output/h_20_targets'

library(ggplot2)
library(plyr)
library(magrittr)
library(tidyr)
library(dplyr)
library(ggtree)
library(ape)


genecopymap = read.csv(genecopyFn,header=T,stringsAsFactors=TRUE)
samples = split(genecopymap$Subgenome,genecopymap$Sample)

# names of the loci in the log file
loci = names(genecopymap)[3:length(genecopymap)]

# what percentage of MCMC samples to exclude?
burnin = 0.1

# modified from ggtree gheatmap
homologized = function (p, data, data_labels, offset = 0, width = 1, low = "green", mid, high = "red",
                        color = "white", colnames = TRUE, colnames_position = "bottom",
                        colnames_angle = 0, colnames_level = NULL, colnames_offset_x = 0,
                        colnames_offset_y = 0, font.size = 4, family = "", hjust = 0.5,
                        legend_title = "value")
{
  colnames_position %<>% match.arg(c("bottom", "top"))
  variable <- value <- lab <- y <- NULL
  width <- width * (p$data$x %>% range(na.rm = TRUE) %>% diff)/ncol(data)
  isTip <- x <- y <- variable <- value <- from <- to <- NULL
  df <- p$data
  nodeCo <- intersect(df %>% filter(is.na(x)) %>% select(.data$parent,
                                                         .data$node) %>% unlist(), df %>% filter(!is.na(x)) %>%
                        select(.data$parent, .data$node) %>% unlist())
  labCo <- df %>% filter(.data$node %in% nodeCo) %>% select(.data$label) %>%
    unlist()
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
  }
  else {
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
    p2 <- p + geom_tile(data = dd, aes(x, y, fill = value),
                        width = width, inherit.aes = FALSE)
  }
  else {
    p2 <- p + geom_tile(data = dd, aes(x, y, fill = value),
                        width = width, color = color, inherit.aes = FALSE)
    p2 <- p2 + geom_text(data = dd2, aes(x, y, label=value), size=1, inherit.aes = FALSE)
    
    # TODO
    #print(dd)
    dd3 = data.frame()
    start_x = max(dd$x)
    height = max(dd$y)
    margin = 0.015
    for (y in unique(dd$y)) {
      pp = mean(dd[dd$y == y, 'value'], na.rm=TRUE)
      dd4 = data.frame(pp = pp, x = pp/200 + margin + start_x, y=y)
      dd3 = rbind(dd3, dd4)
    }
    #print(dd3)
    p2 <- p2 + geom_segment(aes(x=start_x+margin, xend=1/200 + start_x + margin, y=0.2, yend=0.2), size=0.5, inherit.aes = FALSE)
    p2 <- p2 + geom_segment(aes(x=1/200+start_x+margin, xend=1/200+start_x+margin, y=0.5, yend=height), color='grey85', linetype='dotted', size=0.35, inherit.aes = FALSE)
    p2 <- p2 + geom_segment(aes(x=start_x+margin, xend=start_x+margin, y=0.5, yend=height), color='grey85', linetype='dotted', size=0.35, inherit.aes = FALSE)
    p2 <- p2 + geom_point(data = dd3, aes(x, y, color=pp), size=1.25, inherit.aes = FALSE, show.legend=FALSE)
    p2 <- p2 + geom_text(label='0.0', x=start_x+margin, y=-0.2, size=1.25, color='grey50')
    p2 <- p2 + geom_text(label='1.0', x=start_x+margin+1/200, y=-0.2, size=1.25, color='grey50')
  }
  if (methods::is(dd$value, "numeric")) {
    midpoint = max(dd$value, na.rm=TRUE) - min(dd$value, na.rm=TRUE)
    midpoint = midpoint/2 + min(dd$value, na.rm=TRUE) 
    midpoint = 0.25
    p2 <- p2 + scale_fill_gradient2(low = low, mid=mid, high = high, midpoint=midpoint,
                                    na.value = "white", name = legend_title, limits=c(0,1))
    p2 <- p2 + scale_color_gradient2(low = low, mid=mid, high = high, midpoint=midpoint,
                                     na.value = "white", name = legend_title, limits=c(0,1))
    #na.value = NA, name = legend_title)
  }
  else {
    p2 <- p2 + scale_fill_discrete(na.value = NA, name = legend_title)
  }
  if (colnames) {
    if (colnames_position == "bottom") {
      y <- 0
    }
    else {
      y <- max(p$data$y) + 1
    }
    mapping$y <- y
    mapping[[".panel"]] <- factor("Tree")
    p2 <- p2 + geom_text(data = mapping, aes(x = to, y = y,
                                             label = from), size = font.size, family = family,
                         inherit.aes = FALSE, angle = colnames_angle, nudge_x = colnames_offset_x,
                         nudge_y = colnames_offset_y, hjust = hjust)
  }
  p2 <- p2 + theme(legend.position = "right")
  if (!colnames) {
    p2 <- p2 + scale_y_continuous(expand = c(0, 0))
  }
  attr(p2, "heatmap_mapping") <- mapping
  return(p2)
}

all_tips = unname(unlist(samples))

map_prob_results = as.data.frame(matrix(0.0, nrow = length(all_tips), ncol = length(loci),
                                        dimnames = list(all_tips, loci)))
joint_map_phase_results = as.data.frame(matrix("", nrow = length(all_tips), ncol = length(loci),
                                               dimnames = list(all_tips, loci)), stringsAsFactors = FALSE)

marginal_results = data.frame()

for (sample in names(samples)) {
  sample_tips = as.character(samples[[sample]])
  joint_results = data.frame()
  
  for (i in 1:length(loci)) {
    f_in = paste0(prefix, '_locus_', i, '_phase.log')
    
    if (!file.exists(f_in)) next
    
    d = read.csv(f_in, sep = '\t', stringsAsFactors = TRUE, row.names = 1)
    d = d[floor(nrow(d) * burnin):nrow(d), , drop = FALSE]
    
    d1 = d[, sample_tips, drop = FALSE]
    joint_results_locus = as.data.frame(table(d1))
    
    if (length(sample_tips) == 1) {
      names(joint_results_locus)[1] = sample_tips
    }
    
    joint_results_locus$joint_prob = joint_results_locus$Freq / sum(joint_results_locus$Freq)
    joint_results_locus$locus = loci[i]
    joint_results = rbind(joint_results, joint_results_locus)
    
    map_idx = which.max(joint_results_locus$joint_prob)
    for (tip in sample_tips) {
      if (tip %in% names(joint_results_locus)) {
        val = as.character(joint_results_locus[map_idx, tip])
        if (length(val) > 0) {
          joint_map_phase_results[tip, loci[i]] = val
        }
      }
    }
    
    for (tip in sample_tips) {
      if (tip %in% names(d)) {
        m = as.data.frame(table(d[[tip]]))
        m$marginal_prob = m$Freq / sum(m$Freq)
        m$phase = m$Var1
        m$Freq = NULL
        m$Var1 = NULL
        m$locus = loci[i]
        m$tip_name = tip
        marginal_results = rbind(marginal_results, m)
      }
    }
  }
  
  if ("Freq" %in% names(joint_results)) {
    joint_results = within(joint_results, rm(Freq))
  }
}

#out_file = paste0(prefix, '_marginal_phase_probs.csv')
#write.csv(marginal_results, out_file, row.names=FALSE)

# get marginal probs for the joint MAP phase
for (sample in names(samples)) {
  for (tip in samples[[sample]]) {
    for (i in 1:length(loci)) {
      m = marginal_results[marginal_results$phase == joint_map_phase_results[tip,loci[i]] &
                             marginal_results$locus == loci[i] &
                             marginal_results$tip == tip, 'marginal_prob']
      map_prob_results[tip,loci[i]] = m
    }
  }
}

tree = treeio::read.beast(tree_file)
#tree@phylo = drop.tip(tree@phylo, '6379_BLANK2')

p = ggtree(tree) 
p = p + geom_tiplab(size=2, align=T, linesize=0.25, offset=0.0008)  
p = homologized(p, map_prob_results, joint_map_phase_results, 
                offset=0.015, low="#EE0000", mid="#FF0099", high="#DDDDFF", 
                colnames_position="top", font.size=1, width=0.4,
                legend_title="Posterior\nProbability") 
p = p + theme(legend.text=element_text(size=6),
              legend.title=element_text(size=8))
p
#p = p + scale_fill_viridis_c(option="D", name="Posterior\nProbability", na.value="white")
#p = p + scale_color_viridis_c(option="D", name="Posterior\nProbability", na.value="white")
ggsave('homologized_prezentace_joint_MAP.pdf', height=3, width=7)




library(ggplot2)
library(ggtree)
library(ape)

# 1. Vytvoření stromu
p <- ggtree(tree)
p <- p + geom_tiplab(size = 2, align = TRUE, linesize = 0.25, offset = 0.0005)

# 2. Vykreslení Homologizer dat
p <- homologized(
  p, 
  map_prob_results, 
  joint_map_phase_results, 
  offset = 0.018,
  low = "#EE0000", 
  mid = "#FF0099", 
  high = "#DDDDFF", 
  colnames_position = "top", 
  font.size = 1.3,
  width = 1,                   # šířka sloupců
  legend_title = "Posterior\nProbability"
)

p <- p + theme(
  legend.text = element_text(size = 7),
  legend.title = element_text(size = 9),
  plot.margin = margin(t = 10, r = 20, b = 10, l = 40, unit = "pt")
)

# 3. Zjištění počtu taxonů (funguje pro S3 phylo i S4 treedata)
pocet_taxonu <- ape::Ntip(tree)
vyska_grafu <- max(12, pocet_taxonu * 0.35)
p
# 4. Uložení do PDF
ggsave(
  filename = "homologizer_vsechny_vzorky.pdf",
  plot = p,
  width = 16,
  height = vyska_grafu,
  limitsize = FALSE
)