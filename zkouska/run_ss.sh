#!/bin/bash

SCRIPT_DIR="scripts/data/ss_scripts"

LOG_DIR="scripts/data/ss_MaLiOutputs"
mkdir -p "$LOG_DIR"

# Cyklus, který najde všechny .Rev soubory ve vaší složce
for rev_script in "$SCRIPT_DIR"/*.Rev; do
    
    # Insurance: if the directory is empty, the loop will be skipped
    [ -e "$rev_script" ] || continue

    BASE_NAME=$(basename "$rev_script" .Rev)

    echo "=========================================================="
    echo " ss analysis of: $BASE_NAME"
    echo "=========================================================="

    # cycle for: 3 replicates 
    for run in {1..3}; do
        
        TXT_FILE="${LOG_DIR}/${BASE_NAME}_${run}.txt"
        
        echo " -> Running ${run}/3... Terminal output will be saved to: $TXT_FILE"
        
        # start of the RevBayes itself (called by the command: rb) 
        rb "$rev_script" > "$TXT_FILE" 2>&1
        
    done
done

echo "All analyses completed successfully"