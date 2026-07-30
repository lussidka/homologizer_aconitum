#!/bin/bash
set -x  # ZAPNUTÍ RENTGENU - Vypíše vše, co Bash reálně dělá

SCRIPT_DIR="scripts/data/ss_scripts"
LOG_DIR="scripts/data/ss_MaLiOutputs"

mkdir -p "$LOG_DIR"

for rev_script in "$SCRIPT_DIR"/*.Rev; do
    
    [ -e "$rev_script" ] || continue

    BASE_NAME=$(basename "$rev_script" .Rev)

    # Uděláme jen 1 opakování pro test
    for run in {1..1}; do
        
        # Smazáno přesměrování do textového souboru!
        # Upravte si cestu k rb!
        "C:/Users/rycht/Desktop/revbayes-v1.3.2_kopie/bin/rb.exe" "$rev_script"
        
        # Okamžitě ukončíme skript po prvním pokusu
        exit 1
        
    done
done