#!/bin/bash

# ==============================================================================
# Generator of the RevBayes scripts for stepping stone analysis
# ==============================================================================

CORE_CSV="scripts/data/core_samples.csv"
TARGET_CSV="scripts/data/target_samples.csv"
OUTPUT_DIR="scripts"

mkdir -p "$OUTPUT_DIR"

# Transformation of the numbers to letters (index 1 = A,..)
LETTERS=(X A B C D E F G H I J K L M N O P)

# ==============================================================================
# 1. PROCESSING OF CORE SAMPLES (generating shared blocks)
# ==============================================================================
CORE_BLANK_RPB2=""
CORE_BLANK_EIF3E=""
CORE_PHASE_DYNAMIC_L1=""
CORE_PHASE_DYNAMIC_L2=""
CORE_PHASE_FIXED_L1=""
CORE_PHASE_FIXED_L2=""
CORE_MOVES=""

while IFS=';,' read -r C_SAMPLE_ID C_RPB2_COUNT C_EIF3E_COUNT C_PHASE_COUNT C_MAX_COPIES rest; do
    
    C_SAMPLE_ID=$(echo "$C_SAMPLE_ID" | tr -d '\r' | xargs)
    C_RPB2_COUNT=$(echo "$C_RPB2_COUNT" | tr -d '\r' | xargs)
    C_EIF3E_COUNT=$(echo "$C_EIF3E_COUNT" | tr -d '\r' | xargs)
    C_PHASE_COUNT=$(echo "$C_PHASE_COUNT" | tr -d '\r' | xargs)
    C_MAX_COPIES=$(echo "$C_MAX_COPIES" | tr -d '\r' | xargs)

    if [ -z "$C_SAMPLE_ID" ]; then continue; fi
    
    # Missing taxa for core samples
    # RPB2 (Lokus 1)
    if [ "$C_RPB2_COUNT" -lt "$C_PHASE_COUNT" ]; then
        blank_idx=1
        for (( j=C_RPB2_COUNT+1; j<=C_PHASE_COUNT; j++ )); do
            CORE_BLANK_RPB2+="\ndata[1].addMissingTaxa(\"${C_SAMPLE_ID}_BLANK${blank_idx}\")"
            ((blank_idx++))
        done
    fi

    # EIF3E (Lokus 2)
    if [ "$C_EIF3E_COUNT" -lt "$C_PHASE_COUNT" ]; then
        blank_idx=1
        for (( j=C_EIF3E_COUNT+1; j<=C_PHASE_COUNT; j++ )); do
            CORE_BLANK_EIF3E+="\ndata[2].addMissingTaxa(\"${C_SAMPLE_ID}_BLANK${blank_idx}\")"
            ((blank_idx++))
        done
    fi

    # Phasing setup for Core samples
    if [ "$C_SAMPLE_ID" == "n_VJJS2_011" ]; then
        
        get_taxon_name() {
            local copy_num=$1
            local real_count=$2
            if [ "$copy_num" -le "$real_count" ]; then
                echo "${C_SAMPLE_ID}_copy${copy_num}"
            else
                local blank_num=$((copy_num - real_count))
                echo "${C_SAMPLE_ID}_BLANK${blank_num}"
            fi
        }

        # Locus 1 (RPB2)
        CORE_PHASE_FIXED_L1+="    # $C_SAMPLE_ID (FIXED)\n"
        CORE_PHASE_FIXED_L1+="    data[1].setHomeologPhase(\"$(get_taxon_name 3 $C_RPB2_COUNT)\", \"${C_SAMPLE_ID}_A\")\n"
        CORE_PHASE_FIXED_L1+="    data[1].setHomeologPhase(\"$(get_taxon_name 2 $C_RPB2_COUNT)\", \"${C_SAMPLE_ID}_B\")\n"
        CORE_PHASE_FIXED_L1+="    data[1].setHomeologPhase(\"$(get_taxon_name 1 $C_RPB2_COUNT)\", \"${C_SAMPLE_ID}_C\")\n"

        # Locus 2 (EIF3E)
        CORE_PHASE_FIXED_L2+="    # $C_SAMPLE_ID (FIXED)\n"
        CORE_PHASE_FIXED_L2+="    data[2].setHomeologPhase(\"$(get_taxon_name 3 $C_EIF3E_COUNT)\", \"${C_SAMPLE_ID}_A\")\n"
        CORE_PHASE_FIXED_L2+="    data[2].setHomeologPhase(\"$(get_taxon_name 2 $C_EIF3E_COUNT)\", \"${C_SAMPLE_ID}_B\")\n"
        CORE_PHASE_FIXED_L2+="    data[2].setHomeologPhase(\"$(get_taxon_name 1 $C_EIF3E_COUNT)\", \"${C_SAMPLE_ID}_C\")\n"

    else
        if [ "$C_PHASE_COUNT" -gt 1 ]; then
            CORE_PHASE_DYNAMIC_L1+="    # $C_SAMPLE_ID (Locus 1)\n"
            CORE_PHASE_DYNAMIC_L2+="    # $C_SAMPLE_ID (Locus 2)\n"
            
            # L1 Phasing
            blank_idx_l1=1
            for (( c=1; c<=C_PHASE_COUNT; c++ )); do
                if [ "$c" -le "$C_RPB2_COUNT" ]; then
                    CORE_PHASE_DYNAMIC_L1+="    data[1].setHomeologPhase(\"${C_SAMPLE_ID}_copy${c}\", \"${C_SAMPLE_ID}_${LETTERS[$c]}\")\n"
                else
                    CORE_PHASE_DYNAMIC_L1+="    data[1].setHomeologPhase(\"${C_SAMPLE_ID}_BLANK${blank_idx_l1}\", \"${C_SAMPLE_ID}_${LETTERS[$c]}\")\n"
                    ((blank_idx_l1++))
                fi
            done
            
            # L2 Phasing
            blank_idx_l2=1
            for (( c=1; c<=C_PHASE_COUNT; c++ )); do
                if [ "$c" -le "$C_EIF3E_COUNT" ]; then
                    CORE_PHASE_DYNAMIC_L2+="    data[2].setHomeologPhase(\"${C_SAMPLE_ID}_copy${c}\", \"${C_SAMPLE_ID}_${LETTERS[$c]}\")\n"
                else
                    CORE_PHASE_DYNAMIC_L2+="    data[2].setHomeologPhase(\"${C_SAMPLE_ID}_BLANK${blank_idx_l2}\", \"${C_SAMPLE_ID}_${LETTERS[$c]}\")\n"
                    ((blank_idx_l2++))
                fi
            done
        fi

        # Moves for dynamic core samples
        if [ "$C_PHASE_COUNT" -eq 2 ]; then
            CORE_MOVES+="    moves[++mvi] = mvHomeologPhase(ctmc[i], \"${C_SAMPLE_ID}_A\", \"${C_SAMPLE_ID}_B\", weight=5)\n"
        elif [ "$C_PHASE_COUNT" -gt 2 ]; then
            for (( x=1; x<=C_PHASE_COUNT; x++ )); do
                for (( y=x+1; y<=C_PHASE_COUNT; y++ )); do
                    CORE_MOVES+="    moves[++mvi] = mvHomeologPhase(ctmc[i], \"${C_SAMPLE_ID}_${LETTERS[$x]}\", \"${C_SAMPLE_ID}_${LETTERS[$y]}\", weight=5)\n"
                done
            done
        fi
    fi

done < <(tail -n +2 "$CORE_CSV")

# ==============================================================================
# 2. PROCESSING OF TARGET SAMPLES
# ==============================================================================
while IFS=';,' read -r SAMPLE_ID RPB2_COUNT EIF3E_COUNT PHASE_COUNT MAX_COPIES rest; do
    
    SAMPLE_ID=$(echo "$SAMPLE_ID" | tr -d '\r' | xargs)
    RPB2_COUNT=$(echo "$RPB2_COUNT" | tr -d '\r' | xargs)
    EIF3E_COUNT=$(echo "$EIF3E_COUNT" | tr -d '\r' | xargs)
    PHASE_COUNT=$(echo "$PHASE_COUNT" | tr -d '\r' | xargs)
    MAX_COPIES=$(echo "$MAX_COPIES" | tr -d '\r' | xargs)

    if [ -z "$SAMPLE_ID" ]; then continue; fi

    MAX_REAL=$(( RPB2_COUNT > EIF3E_COUNT ? RPB2_COUNT : EIF3E_COUNT ))

    # Kontrola anomálie
    if [ "$MAX_REAL" -gt "$MAX_COPIES" ]; then
        echo "❌ CHYBA u vzorku '$SAMPLE_ID': nalezeno $MAX_REAL reálných kopií, ale MAX_COPIES v tabulce je jen $MAX_COPIES!"
        continue
    fi

    # Přeskočení, pokud není co porovnávat
    if [ "$MAX_REAL" -eq "$MAX_COPIES" ]; then
        echo "⏭️ Přeskakuji vzorek '$SAMPLE_ID': má fixní počet fází $MAX_REAL (MAX_REAL == MAX_COPIES)."
        continue
    fi

    # --------------------------------------------------------------------------
    # BLOKY PŘIPRAVENÉ ROVNOU PRO MAXIMÁLNÍ POČET TIPS (MAX_COPIES)
    # --------------------------------------------------------------------------
    
    # 1. Missing Taxa (BLANKs) generované až do MAX_COPIES
    BLANK_LINES_RPB2=""
    if [ "$RPB2_COUNT" -lt "$MAX_COPIES" ]; then
        blank_idx=1
        for (( j=RPB2_COUNT+1; j<=MAX_COPIES; j++ )); do
            BLANK_LINES_RPB2+="\ndata[1].addMissingTaxa(\"${SAMPLE_ID}_BLANK${blank_idx}\")"
            ((blank_idx++))
        done
    fi

    BLANK_LINES_EIF3E=""
    if [ "$EIF3E_COUNT" -lt "$MAX_COPIES" ]; then
        blank_idx=1
        for (( j=EIF3E_COUNT+1; j<=MAX_COPIES; j++ )); do
            BLANK_LINES_EIF3E+="\ndata[2].addMissingTaxa(\"${SAMPLE_ID}_BLANK${blank_idx}\")"
            ((blank_idx++))
        done
    fi

    # 2. Initial Phase Mapping (setHomeologPhase) pro všech 1..MAX_COPIES
    DYNAMIC_PHASE_LINES_L1=""
    DYNAMIC_PHASE_LINES_L2=""
    
    if [ "$MAX_COPIES" -gt 1 ]; then
        DYNAMIC_PHASE_LINES_L1+="    # Target Sample Initial Phasing (Locus 1)\n"
        DYNAMIC_PHASE_LINES_L2+="    # Target Sample Initial Phasing (Locus 2)\n"
        
        # L1 Phasing (až do MAX_COPIES)
        blank_idx_l1=1
        for (( c=1; c<=MAX_COPIES; c++ )); do
            if [ "$c" -le "$RPB2_COUNT" ]; then
                DYNAMIC_PHASE_LINES_L1+="    data[1].setHomeologPhase(\"${SAMPLE_ID}_copy${c}\", \"${SAMPLE_ID}_${LETTERS[$c]}\")\n"
            else
                DYNAMIC_PHASE_LINES_L1+="    data[1].setHomeologPhase(\"${SAMPLE_ID}_BLANK${blank_idx_l1}\", \"${SAMPLE_ID}_${LETTERS[$c]}\")\n"
                ((blank_idx_l1++))
            fi
        done
        
        # L2 Phasing (až do MAX_COPIES)
        blank_idx_l2=1
        for (( c=1; c<=MAX_COPIES; c++ )); do
            if [ "$c" -le "$EIF3E_COUNT" ]; then
                DYNAMIC_PHASE_LINES_L2+="    data[2].setHomeologPhase(\"${SAMPLE_ID}_copy${c}\", \"${SAMPLE_ID}_${LETTERS[$c]}\")\n"
            else
                DYNAMIC_PHASE_LINES_L2+="    data[2].setHomeologPhase(\"${SAMPLE_ID}_BLANK${blank_idx_l2}\", \"${SAMPLE_ID}_${LETTERS[$c]}\")\n"
                ((blank_idx_l2++))
            fi
        done
    fi

    # --------------------------------------------------------------------------
    # SMYČKA PŘES TESTOVANÝ POČET FÁZÍ / TIPS
    # --------------------------------------------------------------------------
    for (( TESTED_PHASES=MAX_REAL; TESTED_PHASES<=MAX_COPIES; TESTED_PHASES++ )); do
        
        OUTPUT_FILE_PATH="${OUTPUT_DIR}/ss_${SAMPLE_ID}_${TESTED_PHASES}tips.Rev"
        echo "Generating script for: $SAMPLE_ID (Tested phases/tips: $TESTED_PHASES) -> $OUTPUT_FILE_PATH"

        # JEDINÁ ČÁST, KTERÁ SE MĚNÍ DLE TESTED_PHASES: MOVES OPERÁTORY
        DYNAMIC_MOVES=""
        if [ "$TESTED_PHASES" -eq 2 ]; then
            DYNAMIC_MOVES+="    moves[++mvi] = mvHomeologPhase(ctmc[i], \"${SAMPLE_ID}_A\", \"${SAMPLE_ID}_B\", weight=5)\n"
        elif [ "$TESTED_PHASES" -gt 2 ]; then
            for (( x=1; x<=TESTED_PHASES; x++ )); do
                for (( y=x+1; y<=TESTED_PHASES; y++ )); do
                    DYNAMIC_MOVES+="    moves[++mvi] = mvHomeologPhase(ctmc[i], \"${SAMPLE_ID}_${LETTERS[$x]}\", \"${SAMPLE_ID}_${LETTERS[$y]}\", weight=5)\n"
                done
            done
        fi

        # ======================================================================
        # Generování samotného souboru .Rev
        # ======================================================================
        cat << EOF > "$OUTPUT_FILE_PATH"
#
# Specifies a homologizer model that jointly infer the phase and phylogeny.
# Run an MCMC analysis by default. Set bayes_factors = TRUE to calculate
# the marginal likelihood with a stepping stone analysis.
#
# Will Freyman
#
bayes_factors = FALSE
output_file = "output/ss_${SAMPLE_ID}_${TESTED_PHASES}"

# input sequence alignments
alignments = ["nexus_files_samples/RPB2_${SAMPLE_ID}.nex",
              "nexus_files_samples/EIF3E_${SAMPLE_ID}.nex"]
num_loci = alignments.size()

for (i in 1:num_loci) {
    data[i] = readDiscreteCharacterData(alignments[i])
}

# --- MISSING TAXA FOR CORE SAMPLES ---$(echo -e "$CORE_BLANK_RPB2")$(echo -e "$CORE_BLANK_EIF3E")

# --- MISSING TAXA FOR TARGET SAMPLE (prepared for max tips) ---$(echo -e "$BLANK_LINES_RPB2")$(echo -e "$BLANK_LINES_EIF3E")

# Sjednocení taxonů napříč lokusy
for (i in 1:num_loci) {
    for (j in 1:num_loci) {
        data[i].addMissingTaxa(data[j].taxa())
    }
}

# --- INITIAL PHASE SETUP ---
# Locus 1 Setup (RPB2)
$(echo -e "$CORE_PHASE_DYNAMIC_L1")
$(echo -e "$CORE_PHASE_FIXED_L1")
$(echo -e "$DYNAMIC_PHASE_LINES_L1")

# Locus 2 Setup (EIF3E)
$(echo -e "$CORE_PHASE_DYNAMIC_L2")
$(echo -e "$CORE_PHASE_FIXED_L2")
$(echo -e "$DYNAMIC_PHASE_LINES_L2")

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
    moves[++mvi] = mvScale(alpha, weight=2.0)

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
    moves[++mvi] = mvScale(kappa, weight=2.0)

    pi_prior <- v(1,1,1,1)
    pi[i] ~ dnDirichlet(pi_prior)
    pi[i].setValue(simplex(v(1,1,1,1)))
    moves[++mvi] = mvSimplexElementScale(pi[i], weight=5)
    Q[i] := fnHKY(kappa, pi[i])

    alpha ~ dnUniform( 0.0, 10 )
    sr := fnDiscretizeGamma( alpha, alpha, 4 )
    moves[++mvi] = mvScale(alpha, weight=2.0)

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
    # Dynamic Moves for Target Sample (only for tested $TESTED_PHASES phases)
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
    # Stepping stone analysis pro marginální věrohodnost
    pow_p = powerPosterior(mymodel, moves, monitors, output_file + ".out", cats=50, sampleFreq=1) 
    pow_p.burnin(generations=200, tuningInterval=50)
    pow_p.run(generations=1000)  
    ss = steppingStoneSampler(file=output_file + ".out", powerColumnName="power", likelihoodColumnName="likelihood")
    print(ss.marginal())
} else {
    # Standardní MCMC běh
    mymcmc = mcmc(mymodel, monitors, moves, nruns=1, combine="none")
    mymcmc.burnin(generations=200, tuningInterval=50)
    mymcmc.run(generations=1000)

    # Summarize trees
    treetrace = readTreeTrace(output_file + ".trees", treetype="non-clock", burnin=0.25) 
    map_tree = mapTree(treetrace, output_file + "_map.tree")
    mcc_tree = mccTree(treetrace, output_file + "_mcc.tree")
}
EOF

    done
done < <(tail -n +2 "$TARGET_CSV")