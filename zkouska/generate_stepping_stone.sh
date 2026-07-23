#!/bin/bash

# ==============================================================================
# Generátor RevBayes skriptů pro Stepping Stone analýzu
# ==============================================================================

# Vstupní soubor s metadaty (očekáváme hlavičku a sloupce oddělené čárkou)
# Sloupce: vzorek, RPB2, Eif3E, polyploidie
INPUT_CSV="vtupni_obsah_zkouska.csv"
OUTPUT_DIR="output_scripts"

# Vytvoření výstupní složky
mkdir -p "$OUTPUT_DIR"

# Pole pro převod čísel na písmena (index 1 = A, 2 = B atd.)
LETTERS=(X A B C D E F G H I J)

# Přeskočení hlavičky a čtení CSV řádek po řádku
tail -n +2 "$INPUT_CSV" | while IFS=',' read -r SAMPLE_ID RPB2_COUNT EIF3E_COUNT MAX_COPIES rest; do
    
    # Odstranění případných bílých znaků (carriage returns z Windows)
    SAMPLE_ID=$(echo "$SAMPLE_ID" | tr -d '\r' | xargs)
    RPB2_COUNT=$(echo "$RPB2_COUNT" | tr -d '\r' | xargs)
    EIF3E_COUNT=$(echo "$EIF3E_COUNT" | tr -d '\r' | xargs)
    MAX_COPIES=$(echo "$MAX_COPIES" | tr -d '\r' | xargs)

    # Přeskočit prázdné řádky
    if [ -z "$SAMPLE_ID" ]; then continue; fi

    # Pro každý vzorek otestujeme ploidii od 1 až po jeho MAX_COPIES
    for (( TESTED_PLOIDY=1; TESTED_PLOIDY<=MAX_COPIES; TESTED_PLOIDY++ )); do
        
        OUTPUT_FILE_PATH="${OUTPUT_DIR}/ss_${SAMPLE_ID}_${TESTED_PLOIDY}tips.Rev"
        echo "Generuji skript pro: $SAMPLE_ID (Testovaná ploidie: $TESTED_PLOIDY) ->$OUTPUT_FILE_PATH"

        # ----------------------------------------------------------------------
        # 1. LOGIKA PRO DOPLNĚNÍ BLANK TAXA (Pravidlo 4.3)
        # ----------------------------------------------------------------------
        BLANK_LINES_RPB2=""
        if [ "$RPB2_COUNT" -lt "$MAX_COPIES" ]; then
            DIFF=$((MAX_COPIES - RPB2_COUNT))
            if [ "$DIFF" -eq 1 ]; then
                BLANK_LINES_RPB2="data[1].addMissingTaxa(\"${SAMPLE_ID}_BLANK\")"
            else
                for (( j=1; j<=DIFF; j++ )); do
                    BLANK_LINES_RPB2+="\n    data[1].addMissingTaxa(\"${SAMPLE_ID}_BLANK_${j}\")"
                done
            fi
        fi

        BLANK_LINES_EIF3E=""
        if [ "$EIF3E_COUNT" -lt "$MAX_COPIES" ]; then
            DIFF=$((MAX_COPIES - EIF3E_COUNT))
            if [ "$DIFF" -eq 1 ]; then
                BLANK_LINES_EIF3E="data[2].addMissingTaxa(\"${SAMPLE_ID}_BLANK\")"
            else
                for (( j=1; j<=DIFF; j++ )); do
                    BLANK_LINES_EIF3E+="\n    data[2].addMissingTaxa(\"${SAMPLE_ID}_BLANK_${j}\")"
                done
            fi
        fi

        # ----------------------------------------------------------------------
        # 2. LOGIKA PRO NASTAVENÍ FÁZÍ (Pravidlo 4.4 - Dynamic Block)
        # ----------------------------------------------------------------------
        DYNAMIC_PHASE_LINES=""
        CURRENT_LETTER_IDX=1
        
        # Zjištění maximálního počtu "reálných" kopií napříč oběma geny
        MAX_REAL=$(( RPB2_COUNT > EIF3E_COUNT ? RPB2_COUNT : EIF3E_COUNT ))
        
        # A. Přiřazení reálných kopií
        for (( c=1; c<=MAX_REAL; c++ )); do
            DYNAMIC_PHASE_LINES+="    data[i].setHomeologPhase(\"${SAMPLE_ID}_copy${c}\", \"${SAMPLE_ID}_${LETTERS[$CURRENT_LETTER_IDX]}\")\n"
            ((CURRENT_LETTER_IDX++))
        done

        # B. Přiřazení BLANK kopií (do celkového MAX_COPIES)
        BLANKS_NEEDED=$((MAX_COPIES - MAX_REAL))
        if [ "$BLANKS_NEEDED" -eq 1 ]; then
             DYNAMIC_PHASE_LINES+="    data[i].setHomeologPhase(\"${SAMPLE_ID}_BLANK\", \"${SAMPLE_ID}_${LETTERS[$CURRENT_LETTER_IDX]}\")\n"
        elif [ "$BLANKS_NEEDED" -gt 1 ]; then
             for (( b=1; b<=BLANKS_NEEDED; b++ )); do
                 DYNAMIC_PHASE_LINES+="    data[i].setHomeologPhase(\"${SAMPLE_ID}_BLANK_${b}\", \"${SAMPLE_ID}_${LETTERS[$CURRENT_LETTER_IDX]}\")\n"
                 ((CURRENT_LETTER_IDX++))
             done
        fi

        # ----------------------------------------------------------------------
        # 3. LOGIKA PRO KOMBINATORICKÉ MOVES (Pravidlo 4.5)
        # ----------------------------------------------------------------------
        DYNAMIC_MOVES=""
        if [ "$TESTED_PLOIDY" -eq 2 ]; then
            DYNAMIC_MOVES+="    moves[++mvi] = mvHomeologPhase(ctmc[i], \"${SAMPLE_ID}_A\", \"${SAMPLE_ID}_B\", weight=2)\n"
        elif [ "$TESTED_PLOIDY" -gt 2 ]; then
            for (( x=1; x<=TESTED_PLOIDY; x++ )); do
                for (( y=x+1; y<=TESTED_PLOIDY; y++ )); do
                    DYNAMIC_MOVES+="    moves[++mvi] = mvHomeologPhase(ctmc[i], \"${SAMPLE_ID}_${LETTERS[$x]}\", \"${SAMPLE_ID}_${LETTERS[$y]}\", weight=2)\n"
                done
            done
        fi

        # ======================================================================
        # GENERATE REV SCRIPT (Zápis do souboru)
        # ======================================================================
        # Vše mezi 'cat << EOF' a dalším 'EOF' se zapíše do souboru. Bash automaticky
        # nahradí naše nadefinované proměnné za skutečné hodnoty.
        cat << EOF > "$OUTPUT_FILE_PATH"
#
# Specifies a homologizer model that jointly infer the phase and phylogeny.
# Auto-generated script for sample: $SAMPLE_ID (Tested tips:$TESTED_PLOIDY)
#

bayes_factors = FALSE
output_file = "output/stepping_stone_${SAMPLE_ID}_${TESTED_PLOIDY}"

# input sequence alignments (Dynamic according to Rule 2)
alignments = ["data/${SAMPLE_ID}_RPB2.nex",
              "data/${SAMPLE_ID}_EIF3E.nex"]
num_loci = alignments.size()

for (i in 1:num_loci) {
    data[i] = readDiscreteCharacterData(alignments[i])
}

# --- STATIC MISSING TAXA FOR REFERENCES ---
data[1].addMissingTaxa("deg_UMA2_112_copy2")
data[1].addMissingTaxa("n_VJJS2_011_copy3")

# --- DYNAMIC MISSING TAXA (BLANKS) FOR TARGET SAMPLE ---
$BLANK_LINES_RPB2$BLANK_LINES_EIF3E

# --- INITIAL PHASE SETUP ---
for (i in 1:num_loci) {
    # Fixed Reference Block
    data[i].setHomeologPhase("deg_UMA2_112_copy1", "deg_UMA2_112_A")
    data[i].setHomeologPhase("deg_UMA2_112_copy2", "deg_UMA2_112_B")
    
    # Dynamic Target Sample Block
$(echo -e "$DYNAMIC_PHASE_LINES")
}

# Fixed loops for n_VJJS2_011
for (i in 1:1) {
    data[i].setHomeologPhase("n_VJJS2_011_copy1", "n_VJJS2_011_A")
    data[i].setHomeologPhase("n_VJJS2_011_copy2", "n_VJJS2_011_B")
    data[i].setHomeologPhase("n_VJJS2_011_copy3", "n_VJJS2_011_C")
}
for (i in 2:2) {
    data[i].setHomeologPhase("n_VJJS2_011_copy1", "n_VJJS2_011_A")
    data[i].setHomeologPhase("n_VJJS2_011_copy2", "n_VJJS2_011_B")
    data[i].setHomeologPhase("n_VJJS2_011_copy3", "n_VJJS2_011_C")
}

# add missing taxa globally
for (i in 1:num_loci) {
    for (j in 1:num_loci) {
        data[i].addMissingTaxa(data[j].taxa())
    }
}

num_tips = data[1].ntaxa()
n_branches = 2 * num_tips - 3

mvi = 0
for (i in 1:n_branches) {
    branch_lengths[i] ~ dnExponential(100)
    moves[++mvi] = mvScale(branch_lengths[i], weight=1.0)
}

topology ~ dnUniformTopology(data[1].taxa())
moves[++mvi] = mvNNI(topology, weight=40.0)
moves[++mvi] = mvSPR(topology, weight=40.0)

tree := treeAssembly(topology, branch_lengths)

# --- SUBSTITUTION MODELS ---
# RPB2 (GTR + G)
for (i in 1:1) {
    er_prior <- v(1,1,1,1,1,1)
    er[i] ~ dnDirichlet(er_prior)
    er[i].setValue(simplex(v(1,1,1,1,1,1)))
    moves[++mvi] = mvSimplexElementScale(er[i], weight=5)

    pi_prior <- v(1,1,1,1)
    pi[i] ~ dnDirichlet(pi_prior)
    pi[i].setValue(simplex(v(1,1,1,1)))
    moves[++mvi] = mvSimplexElementScale(pi[i], weight=5)
    Q[i] := fnGTR(er[i], pi[i])

    alpha ~ dnUniform( 0.0, 10 )
    sr := fnDiscretizeGamma( alpha, alpha, 4 )
    moves.append( mvScale(alpha, weight=2.0) )

    if (i == 1) {
        rate_multiplier[i] <- 1.0
    } else {
        rate_multiplier[i] ~ dnExponential(1)
        moves[++mvi] = mvScale(rate_multiplier[i], weight=5)
    }
}
for (i in 1:1) {
    ctmc[i] ~ dnPhyloCTMC(tree=tree, Q=Q[i], siteRates=sr, branchRates=rate_multiplier[i], type="DNA")
}

# EIF3E (HKY + G)
for (i in 2:2) {
    kappa ~ dnLognormal(0.0, 1.0)
    moves.append( mvScale(kappa) )

    pi_prior <- v(1,1,1,1)
    pi[i] ~ dnDirichlet(pi_prior)
    pi[i].setValue(simplex(v(1,1,1,1)))
    moves[++mvi] = mvSimplexElementScale(pi[i], weight=5)
    Q[i] := fnHKY(kappa, pi[i])

    alpha ~ dnUniform( 0.0, 10 )
    sr := fnDiscretizeGamma( alpha, alpha, 4 )
    moves.append( mvScale(alpha, weight=2.0) )

    if (i == 1) {
        rate_multiplier[i] <- 1.0
    } else {
        rate_multiplier[i] ~ dnExponential(1)
        moves[++mvi] = mvScale(rate_multiplier[i], weight=5)
    }
}
for (i in 2:2) {
    ctmc[i] ~ dnPhyloCTMC(tree=tree, Q=Q[i], siteRates=sr, branchRates=rate_multiplier[i], type="DNA")
}

# --- PHASING PROPOSALS (MOVES) ---
for (i in 1:num_loci) {
    # Fixed for Reference
    moves[++mvi] = mvHomeologPhase(ctmc[i], "deg_UMA2_112_A", "deg_UMA2_112_B", weight=2)
    
    # Dynamic Moves for Target Sample based on TESTED_TIPS ($TESTED_PLOIDY)
$(echo -e "$DYNAMIC_MOVES")
}

for (i in 1:num_loci) {
    ctmc[i].clamp(data[i])
}
mymodel = model(Q)

# --- MONITORS & RUN ---
mni = 0
monitors[++mni] = mnModel(filename=output_file + ".log", printgen=1)
monitors[++mni] = mnFile(filename=output_file + ".trees", printgen=1, tree)
monitors[++mni] = mnScreen(printgen=1)
for (i in 1:num_loci){
    monitors[++mni] = mnHomeologPhase(filename=output_file + "_locus_" + i + "_phase.log", printgen=1, ctmc[i])
}

if (bayes_factors) {
    pow_p = powerPosterior(mymodel, moves, monitors, output_file + ".out", cats=50, sampleFreq=1) 
    pow_p.burnin(generations=200, tuningInterval=50)
    pow_p.run(generations=1000)  
    ss = steppingStoneSampler(file=output_file + ".out", powerColumnName="power", likelihoodColumnName="likelihood")
    print(ss.marginal())
} else {
    pow_p = powerPosterior(mymodel, moves, monitors, output_file + ".out", cats=50, sampleFreq=1) 
    pow