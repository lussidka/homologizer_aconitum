#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) {
  stop("Usage: generate_revbayes_script.R <manifest> <sample> <tested_ploidy> <out_rev>")
}
manifest <- args[1]
sample <- trimws(args[2])
tested_ploidy <- as.integer(args[3])
out_rev <- args[4]

if (!file.exists(manifest)) stop("Manifest not found: ", manifest)
metadata <- read.csv(manifest, sep = ";", stringsAsFactors = FALSE, strip.white = TRUE)
metadata$vzorek <- trimws(metadata$vzorek)
row <- metadata[metadata$vzorek == sample, ]
if (nrow(row) != 1) stop("Sample not found in manifest: ", sample)

rpb2_count <- as.integer(row$RPB2)
eif3e_count <- as.integer(row$Eif3E)
max_polyploidy <- as.integer(row$polyploidie)
if (is.na(rpb2_count) || is.na(eif3e_count) || is.na(max_polyploidy)) stop("Invalid numeric fields for sample: ", sample)
min_ploidy <- max(rpb2_count, eif3e_count)
if (tested_ploidy < min_ploidy) stop(sprintf("Tested ploidy %d is less than observed copy count for sample %s", tested_ploidy, sample))
if (tested_ploidy > max_polyploidy) stop(sprintf("Tested ploidy %d is greater than sample max ploidy %d for sample %s", tested_ploidy, max_polyploidy, sample))

alignment_rpb2 <- sprintf("results/sample_nex/%s/RPB2_%s.nex", sample, sample)
alignment_eif3e <- sprintf("results/sample_nex/%s/EIF3E_%s.nex", sample, sample)
output_file <- sprintf("results/steppingstone_output/%s/%d/stepping_stone_%s_%d", sample, tested_ploidy, sample, tested_ploidy)

max_observed <- max(rpb2_count, eif3e_count)
if (tested_ploidy < max_observed) {
  stop("Tested ploidy must be at least the maximum observed locus copy count")
}

make_blank_labels <- function(n) {
  if (n <= 0) return(character(0))
  if (n == 1) return(sprintf("%s_BLANK", sample))
  sprintf("%s_BLANK_%d", sample, seq_len(n))
}

blank_labels <- make_blank_labels(tested_ploidy - max_observed)
phase_labels <- c(sprintf("%s_copy%d", sample, seq_len(max_observed)), blank_labels)
phase_letters <- LETTERS[seq_along(phase_labels)]
if (length(phase_labels) != tested_ploidy) stop("Internal error: phase label count does not match tested ploidy")

make_move_lines <- function(letters) {
  if (length(letters) <= 1) return(character(0))
  combos <- combn(letters, 2)
  apply(combos, 2, function(pair) {
    sprintf('    moves[++mvi] = mvHomeologPhase(ctmc[i], "%s_%s", "%s_%s", weight=2)', sample, pair[1], sample, pair[2])
  })
}

move_lines <- if (tested_ploidy == 1) {
  character(0)
} else if (tested_ploidy == 2) {
  make_move_lines(c("A", "B"))
} else {
  make_move_lines(phase_letters)
}

static_lines <- c(
  '# add blank third RPB2 gene (= data[1], protoze RPB2 je prvni matice!) copy for deg_UMA2_112',
  'data[1].addMissingTaxa("deg_UMA2_112_copy2")',
  '# add blank third RPB2 gene (= data[1], protoze RPB2 je prvni matice!) copy for n_VJJS2_011',
  'data[1].addMissingTaxa("n_VJJS2_011_copy3")'
)

make_locus_lines <- function(locus, count, max_observed, blank_labels) {
  lines <- character(0)
  if (count < max_observed) {
    for (n in (count + 1):max_observed) {
      lines <- c(lines, sprintf('data[%d].addMissingTaxa("%s_copy%d")', locus, sample, n))
    }
  }
  if (length(blank_labels) > 0) {
    for (label in blank_labels) {
      lines <- c(lines, sprintf('data[%d].addMissingTaxa("%s")', locus, label))
    }
  }
  lines
}

add_missing_lines <- c(
  make_locus_lines(1, rpb2_count, max_observed, blank_labels),
  make_locus_lines(2, eif3e_count, max_observed, blank_labels)
)

phase_assignment_lines <- c(
  'for (i in 1:num_loci) {',
  sprintf('    data[i].setHomeologPhase("%s_copy1", "%s_A")', sample, sample),
  vapply(if (max_observed >= 2) seq(2, max_observed) else integer(0), function(n) {
    sprintf('    data[i].setHomeologPhase("%s_copy%d", "%s_%s")', sample, n, sample, LETTERS[n])
  }, character(max(0, max_observed - 1))),
  if (length(blank_labels) > 0) {
    vapply(seq_along(blank_labels), function(i) {
      letter <- LETTERS[max_observed + i]
      sprintf('    data[i].setHomeologPhase("%s", "%s_%s")', blank_labels[i], sample, letter)
    }, character(length(blank_labels)))
  } else character(0),
  '    data[i].setHomeologPhase("deg_UMA2_112_copy1", "deg_UMA2_112_A")',
  '    data[i].setHomeologPhase("deg_UMA2_112_copy2", "deg_UMA2_112_B")',
  '}'
)

phase_assignment_lines <- unname(unlist(phase_assignment_lines))

fixed_ref_block <- c(
  '# For Locus 1 (RPB2)',
  'for (i in 1:1) {',
  '    data[i].setHomeologPhase("n_VJJS2_011_copy1", "n_VJJS2_011_A")',
  '    data[i].setHomeologPhase("n_VJJS2_011_copy2", "n_VJJS2_011_B")',
  '    data[i].setHomeologPhase("n_VJJS2_011_copy3", "n_VJJS2_011_C")',
  '}',
  '# For Locus 2 (EIF3E)',
  'for (i in 2:2) {',
  '    data[i].setHomeologPhase("n_VJJS2_011_copy1", "n_VJJS2_011_A")',
  '    data[i].setHomeologPhase("n_VJJS2_011_copy2", "n_VJJS2_011_B")',
  '    data[i].setHomeologPhase("n_VJJS2_011_copy3", "n_VJJS2_011_C")',
  '    # for the 3-tip phasing model uncomment these lines:',
  '    #data[i].addMissingTaxa("e_OLS17_013_BLANK3")',
  '    #data[i].setHomeologPhase("e_OLS17_013_BLANK3", "e_OLS17_013_C")',
  '}'
)

move_block <- c(
  '# make phasing proposals - reference sample deg_UMA2_112 always gets a move',
  'for (i in 1:num_loci) {',
  '    moves[++mvi] = mvHomeologPhase(ctmc[i], "deg_UMA2_112_A", "deg_UMA2_112_B", weight=2)' ,
  if (length(move_lines) > 0) move_lines else character(0),
  '}'
)
move_block <- unname(unlist(move_block))

script_lines <- c(
  '#',
  '# RevBayes stepping-stone script generated by generate_revbayes_script.R',
  '#',
  'bayes_factors = TRUE',
  sprintf('output_file = "%s"', output_file),
  '',
  '# input sequence alignments',
  sprintf('alignments = ["%s",', alignment_rpb2),
  sprintf('              "%s"]', alignment_eif3e),
  'num_loci = alignments.size()',
  '',
  'for (i in 1:num_loci) {',
  '    data[i] = readDiscreteCharacterData(alignments[i])',
  '}',
  '',
  static_lines,
  '',
  add_missing_lines,
  '',
  '# set initial phase',
  phase_assignment_lines,
  '',
  fixed_ref_block,
  '',
  '# add missing taxa',
  'for (i in 1:num_loci) {',
  '    for (j in 1:num_loci) {',
  '        data[i].addMissingTaxa(data[j].taxa())',
  '    }',
  '}',
  '',
  'num_tips = data[1].ntaxa()',
  'n_branches = 2 * num_tips - 3',
  '',
  '# set up branches',
  'mvi = 0',
  'for (i in 1:n_branches) {',
  '    branch_lengths[i] ~ dnExponential(100)',
  '    moves[++mvi] = mvScale(branch_lengths[i], weight=1.0)',
  '}',
  '',
  '# set up tree topology',
  'topology ~ dnUniformTopology(data[1].taxa())',
  'moves[++mvi] = mvNNI(topology, weight=40.0)',
  'moves[++mvi] = mvSPR(topology, weight=40.0)',
  '',
  '# combine branches and topology into tree',
  'tree := treeAssembly(topology, branch_lengths)',
  '',
  '# substitution models - GTR pro 1. matici, tj. RPB2:',
  'for (i in 1:1) {',
  '    er_prior <- v(1,1,1,1,1,1)',
  '    er[i] ~ dnDirichlet(er_prior)',
  '    er[i].setValue(simplex(v(1,1,1,1,1,1)))',
  '    moves[++mvi] = mvSimplexElementScale(er[i], weight=5)',
  '',
  '    pi_prior <- v(1,1,1,1)',
  '    pi[i] ~ dnDirichlet(pi_prior)',
  '    pi[i].setValue(simplex(v(1,1,1,1)))',
  '    moves[++mvi] = mvSimplexElementScale(pi[i], weight=5)',
  '',
  '    Q[i] := fnGTR(er[i], pi[i])',
  '',
  '    alpha ~ dnUniform(0.0, 10)',
  '    sr := fnDiscretizeGamma(alpha, alpha, 4)',
  '    moves.append(mvScale(alpha, weight=2.0))',
  '',
  '    if (i == 1) {',
  '        rate_multiplier[i] <- 1.0',
  '    } else {',
  '        rate_multiplier[i] ~ dnExponential(1)',
  '        moves[++mvi] = mvScale(rate_multiplier[i], weight=5)',
  '    }',
  '}',
  '',
  '# phylogenetic CTMC distributions for each locus',
  'for (i in 1:1) {',
  '    ctmc[i] ~ dnPhyloCTMC(tree=tree, Q=Q[i], siteRates=sr, branchRates=rate_multiplier[i], type="DNA")',
  '}',
  '',
  '# substitution models - HKY pro 2. matici, tj. EIF3E:',
  'for (i in 2:2) {',
  '    kappa ~ dnLognormal(0.0, 1.0)',
  '    moves.append(mvScale(kappa))',
  '',
  '    pi_prior <- v(1,1,1,1)',
  '    pi[i] ~ dnDirichlet(pi_prior)',
  '    pi[i].setValue(simplex(v(1,1,1,1)))',
  '    moves[++mvi] = mvSimplexElementScale(pi[i], weight=5)',
  '',
  '    Q[i] := fnHKY(kappa, pi[i])',
  '',
  '    alpha ~ dnUniform(0.0, 10)',
  '    sr := fnDiscretizeGamma(alpha, alpha, 4)',
  '    moves.append(mvScale(alpha, weight=2.0))',
  '',
  '    if (i == 1) {',
  '        rate_multiplier[i] <- 1.0',
  '    } else {',
  '        rate_multiplier[i] ~ dnExponential(1)',
  '        moves[++mvi] = mvScale(rate_multiplier[i], weight=5)',
  '    }',
  '}',
  '',
  '# phylogenetic CTMC distributions for each locus',
  'for (i in 2:2) {',
  '    ctmc[i] ~ dnPhyloCTMC(tree=tree, Q=Q[i], siteRates=sr, branchRates=rate_multiplier[i], type="DNA")',
  '}',
  '',
  move_block,
  '',
  '# clamp the observed data to the CTMC for each locus',
  'for (i in 1:num_loci) {',
  '    ctmc[i].clamp(data[i])',
  '}',
  '',
  'mymodel = model(Q)',
  '',
  '# set up monitors',
  'mni = 0',
  'monitors[++mni] = mnModel(filename=output_file + ".log", printgen=1)',
  'monitors[++mni] = mnFile(filename=output_file + ".trees", printgen=1, tree)',
  'monitors[++mni] = mnScreen(printgen=1)',
  'for (i in 1:num_loci){',
  '    monitors[++mni] = mnHomeologPhase(filename=output_file + "_locus_" + i + "_phase.log", printgen=1, ctmc[i])',
  '}',
  '',
  'if (bayes_factors) {',
  '    pow_p = powerPosterior(mymodel, moves, monitors, output_file + ".out", cats=50, sampleFreq=1)',
  '    pow_p.burnin(generations=200, tuningInterval=50)',
  '    pow_p.run(generations=1000)',
  '    ss = steppingStoneSampler(file=output_file + ".out", powerColumnName="power", likelihoodColumnName="likelihood")',
  '    print(ss.marginal())',
  '} else {',
  '    mymcmc = mcmc(mymodel, monitors, moves)',
  '    mymcmc.run(generations=10000)',
  '    treetrace = readTreeTrace(output_file + ".trees", treetype="non-clock", burnin=0.25)',
  '    map_tree = mapTree(treetrace, output_file + "_map.tree")',
  '    mcc_tree = mccTree(treetrace, output_file + "_mcc.tree")',
  '}',
  ''
)

out_dir <- dirname(out_rev)
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
writeLines(script_lines, out_rev)
cat("Generated", out_rev, "\n")
