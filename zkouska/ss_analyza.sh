#!/bin/bash

# ==============================================================================
# Generátor RevBayes skriptů pro Stepping Stone analýzu
# ==============================================================================

# Vstupní soubory s metadaty (očekáváme hlavičku a sloupce oddělené středníkem)
# Sloupce: vzorek;RPB2;Eif3E;pocet_fazi;polyploidie
CORE_CSV="scripts/data/core_vzorky.csv"
TARGET_CSV="scripts/data/dalsi_vzorky.csv"
OUTPUT_DIR="scripts/data/ss_scripty"

# Vytvoření výstupní složky
mkdir -p "$OUTPUT_DIR"

# Pole pro převod čísel na písmena (index 1 = A,..)
LETTERS=(X A B C D E F G H I J)

# ==============================================================================
# 0. PŘEDZPRACOVÁNÍ CORE VZORKŮ (generování sdílených bloků)
# ==============================================================================
CORE_BLANK_RPB2=""
CORE_BLANK_EIF3E=""
CORE_PHASE=""
CORE_MOVES=""

while IFS=';' read -r C_SAMPLE_ID C_RPB2_COUNT C_EIF3E_COUNT C_PHASE_COUNT C_MAX_COPIES rest; do
    # Odstranění bílých znaků
    C_SAMPLE_ID=$(echo "$C_SAMPLE_ID" | tr -d '\r' | xargs)
    C_RPB2_COUNT=$(echo "$C_RPB2_COUNT" | tr -d '\r' | xargs)
    C_EIF3E_COUNT=$(echo "$C_EIF3E_COUNT" | tr -d '\r' | xargs)
    C_PHASE_COUNT=$(echo "$C_PHASE_COUNT" | tr -d '\r' | xargs)
    C_MAX_COPIES=$(echo "$C_MAX_COPIES" | tr -d '\r' | xargs)

    if [ -z "$C_SAMPLE_ID" ]; then continue; fi
    
    # Zjistíme skutečné maximum reálných kopií
    C_MAX_REAL=$(( C_RPB2_COUNT > C_EIF3E_COUNT ? C_RPB2_COUNT : C_EIF3E_COUNT ))

    # 1. LOGIKA PRO DOPLNĚNÍ BLANK TAXA PRO CORE VZORKY (do výše C_PHASE_COUNT)
    if [ "$C_RPB2_COUNT" -lt "$C_PHASE_COUNT" ]; then
        for (( j=C_RPB2_COUNT+1; j<=C_PHASE_COUNT; j++ )); do
            CORE_BLANK_RPB2+="\ndata[1].addMissingTaxa(\"${C_SAMPLE_ID}_copy${j}_BLANK\")"
        done
    fi

    if [ "$C_EIF3E_COUNT" -lt "$C_PHASE_COUNT" ]; then
        for (( j=C_EIF3E_COUNT+1; j<=C_PHASE_COUNT; j++ )); do
            CORE_BLANK_EIF3E+="\ndata[2].addMissingTaxa(\"${C_SAMPLE_ID}_copy${j}_BLANK\")"
        done
    fi

    # 2. LOGIKA PRO NASTAVENÍ FÁZÍ PRO CORE VZORKY
    CORE_PHASE+="    # $C_SAMPLE_ID\n"
    C_CURRENT_LETTER_IDX=1
    
    # A. Přiřazení reálných kopií
    for (( c=1; c<=C_MAX_REAL; c++ )); do
        CORE_PHASE+="    data[i].setHomeologPhase(\"${C_SAMPLE_ID}_copy${c}\", \"${C_SAMPLE_ID}_${LETTERS[$C_CURRENT_LETTER_IDX]}\")\n"
        ((C_CURRENT_LETTER_IDX++))
    done

    # B. Přiřazení BLANK kopií
    if [ "$C_MAX_REAL" -lt "$C_PHASE_COUNT" ]; then
         for (( j=C_MAX_REAL+1; j<=C_PHASE_COUNT; j++ )); do
             CORE_PHASE+="    data[i].setHomeologPhase(\"${C_SAMPLE_ID}_copy${j}_BLANK\", \"${C_SAMPLE_ID}_${LETTERS[$C_CURRENT_LETTER_IDX]}\")\n"
             ((C_CURRENT_LETTER_IDX++))
         done
    fi

    # 3. LOGIKA PRO KOMBINATORICKÉ MOVES PRO CORE VZORKY
    if [ "$C_PHASE_COUNT" -eq 2 ]; then
        CORE_MOVES+="    moves[++mvi] = mvHomeologPhase(ctmc[i], \"${C_SAMPLE_ID}_A\", \"${C_SAMPLE_ID}_B\", weight=2)\n"
    elif [ "$C_PHASE_COUNT" -gt 2 ]; then
        for (( x=1; x<=C_PHASE_COUNT; x++ )); do
            for (( y=x+1; y<=C_PHASE_COUNT; y++ )); do
                CORE_MOVES+="    moves[++mvi] = mvHomeologPhase(ctmc[i], \"${C_SAMPLE_ID}_${LETTERS[$x]}\", \"${C_SAMPLE_ID}_${LETTERS[$y]}\", weight=2)\n"
            done
        done
    fi

done < <(tail -n +2 "$CORE_CSV")


# ==============================================================================
# 1. ZPRACOVÁNÍ TARGET VZORKŮ (Hlavní cyklus a generování skriptů)
# ==============================================================================
while IFS=';' read -r SAMPLE_ID RPB2_COUNT EIF3E_COUNT PHASE_COUNT MAX_COPIES rest; do
    
    # Odstranění bílých znaků
    SAMPLE_ID=$(echo "$SAMPLE_ID" | tr -d '\r' | xargs)
    RPB2_COUNT=$(echo "$RPB2_COUNT" | tr -d '\r' | xargs)
    EIF3E_COUNT=$(echo "$EIF3E_COUNT" | tr -d '\r' | xargs)
    MAX_COPIES=$(echo "$MAX_COPIES" | tr -d '\r' | xargs)

    if [ -z "$SAMPLE_ID" ]; then continue; fi

    # Zjistíme skutečné maximum reálných kopií
    MAX_REAL=$(( RPB2_COUNT > EIF3E_COUNT ? RPB2_COUNT : EIF3E_COUNT ))

    for (( TESTED_PLOIDY=MAX_REAL; TESTED_PLOIDY<=MAX_COPIES; TESTED_PLOIDY++ )); do
        
        OUTPUT_FILE_PATH="${OUTPUT_DIR}/ss_${SAMPLE_ID}_${TESTED_PLOIDY}tips.Rev"
        echo "Generuji skript pro: $SAMPLE_ID (Testovaná ploidie: $TESTED_PLOIDY) -> $OUTPUT_FILE_PATH"

        # ----------------------------------------------------------------------
        # 1. LOGIKA PRO DOPLNĚNÍ BLANK TAXA PRO TARGET
        # ----------------------------------------------------------------------
        BLANK_LINES_RPB2=""
        if [ "$RPB2_COUNT" -lt "$TESTED_PLOIDY" ]; then
            for (( j=RPB2_COUNT+1; j<=TESTED_PLOIDY; j++ )); do
                BLANK_LINES_RPB2+="\ndata[1].addMissingTaxa(\"${SAMPLE_ID}_copy${j}_BLANK\")"
            done
        fi

        BLANK_LINES_EIF3E=""
        if [ "$EIF3E_COUNT" -lt "$TESTED_PLOIDY" ]; then
            for (( j=EIF3E_COUNT+1; j<=TESTED_PLOIDY; j++ )); do
                BLANK_LINES_EIF3E+="\ndata[2].addMissingTaxa(\"${SAMPLE_ID}_copy${j}_BLANK\")"
            done
        fi

        # ----------------------------------------------------------------------
        # 2. LOGIKA PRO NASTAVENÍ FÁZÍ PRO TARGET
        # ----------------------------------------------------------------------
        DYNAMIC_PHASE_LINES=""
        CURRENT_LETTER_IDX=1
        
        for (( c=1; c<=MAX_REAL; c++ )); do
            DYNAMIC_PHASE_LINES+="    data[i].setHomeologPhase(\"${SAMPLE_ID}_copy${c}\", \"${SAMPLE_ID}_${LETTERS[$CURRENT_LETTER_IDX]}\")\n"
            ((CURRENT_LETTER_IDX++))
        done

        if [ "$MAX_REAL" -lt "$TESTED_PLOIDY" ]; then
             for (( j=MAX_REAL+1; j<=TESTED_PLOIDY; j++ )); do
                 DYNAMIC_PHASE_LINES+="    data[i].setHomeologPhase(\"${SAMPLE_ID}_copy${j}_BLANK\", \"${SAMPLE_ID}_${LETTERS[$CURRENT_LETTER_IDX]}\")\n"
                 ((CURRENT_LETTER_IDX++))
             done
        fi

        # ----------------------------------------------------------------------
        # 3. LOGIKA PRO KOMBINATORICKÉ MOVES PRO TARGET
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
        # Zápis do .Rev souboru
        # ======================================================================
        cat << EOF > "$OUTPUT_FILE_PATH"
#
# Specifies a homologizer model that jointly infer the phase and phylogeny.
# Auto-generated script for sample: $SAMPLE_ID (Tested tips:$TESTED_PLOIDY)
#

bayes_factors = FALSE
output_file = "output/stepping_stone_${SAMPLE_ID}_${TESTED_PLOIDY}"

# input sequence alignments
alignments = ["data/${SAMPLE_ID}_RPB2.nex",
              "data/${SAMPLE_ID}_EIF3E.nex"]
num_loci = alignments.size()

for (i in 1:num_loci) {
    data[i] = readDiscreteCharacterData(alignments[i])
}

# --- MISSING TAXA FOR CORE SAMPLES ---$(echo -e "$CORE_BLANK_RPB2")$(echo -e "$CORE_BLANK_EIF3E")

# --- DYNAMIC MISSING TAXA (BLANKS) FOR TARGET SAMPLE ---$(echo -e "$BLANK_LINES_RPB2")$(echo -e "$BLANK_LINES_EIF3E")

# --- INITIAL PHASE SETUP ---
for (i in 1:num_loci) {
    # Core Samples Block
$(echo -e "$CORE_PHASE")
    # Dynamic Target Sample Block
$(echo -e "$DYNAMIC_PHASE_LINES")
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
    # Core Samples Moves
$(echo -e "$CORE_MOVES")
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
    pow_p.burnin(generations=200, tuningInterval=50)
    pow_p.run(generations=1000)
    ss = steppingStoneSampler(file=output_file + ".out", powerColumnName="power", likelihoodColumnName="likelihood")
    print(ss.marginal())

    # summarize results
    treetrace = readTreeTrace(output_file + ".trees", treetype="non-clock", burnin=0.25) 
    map_tree = mapTree(treetrace, output_file + "_map.tree")
    mcc_tree = mccTree(treetrace, output_file + "_mcc.tree")
}
q()
EOF

    done
done < <(tail -n +2 "$TARGET_CSV")