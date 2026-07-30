#!/bin/bash

# ==============================================================================
# SCRIPT 2: SPOUŠTĚČ ANALÝZ, VÝPOČET PRŮMĚRŮ A VYHODNOCENÍ PLOIDIE
# ==============================================================================

SCRIPT_DIR="scripts/data/ss_scripty"
LOG_DIR="scripts/data/ss_vypisy"
RESULTS_CSV="scripts/data/ss_kompletni_tabulka.csv"
FINAL_REPORT="scripts/data/ss_vyhodnocena_ploidie.txt"

mkdir -p "$LOG_DIR"

# Založení nové, široké tabulky
echo "Vzorek;Testovana_Ploidie;Beh_1;Beh_2;Beh_3;Prumer" > "$RESULTS_CSV"

echo "Začínám spouštět RevBayes analýzy..."

# ------------------------------------------------------------------------------
# FÁZE 1: SPOUŠTĚNÍ A ZÁPIS DO TABULKY
# ------------------------------------------------------------------------------
for rev_script in "$SCRIPT_DIR"/*.Rev; do
    
    [ -e "$rev_script" ] || continue
    
    # Např: ss_n_PPSK4_177_3tips
    BASE_NAME=$(basename "$rev_script" .Rev)
    
    # Chytře vysekáme jméno vzorku a testovanou ploidii z názvu souboru
    # (Odstraní "ss_" na začátku a "_Xtips" na konci)
    SAMPLE_NAME=$(echo "$BASE_NAME" | sed 's/^ss_//; s/_[0-9]*tips$//')
    # Vytáhne jen to číslo před slovem "tips"
    TESTED_PLOIDY=$(echo "$BASE_NAME" | grep -Eo '[0-9]+tips$' | grep -Eo '[0-9]+')

    echo "=========================================================="
    echo "Vzorek: $SAMPLE_NAME | Testovaná ploidie: $TESTED_PLOIDY"
    echo "=========================================================="

    # Připravíme si proměnné pro uložení výsledků ze 3 běhů
    ML1=""
    ML2=""
    ML3=""

    for run in {1..3}; do
        TXT_FILE="${LOG_DIR}/${BASE_NAME}_${run}.txt"
        echo " -> Běh ${run}/3..."
        
        # Spuštění RevBayes (zde případně upravte cestu k rb)
        rb "$rev_script" > "$TXT_FILE" 2>&1
        
        # Extrakce čísla
        VAL=$(grep -A 1 "Step 50 / 50" "$TXT_FILE" | tail -n 1 | tr -d '[:space:]')
        
        # Pokud se hodnota nenajde, dáme tam extrémně nízké číslo, aby to nevyhrálo
        if [ -z "$VAL" ] || [[ "$VAL" == *"*"* ]]; then
            VAL="-999999.99"
            echo "    [!] Chyba extrakce! Dosazuji -999999.99"
        fi

        # Uložení do správné proměnné podle toho, který je to běh
        if [ "$run" -eq 1 ]; then ML1=$VAL; fi
        if [ "$run" -eq 2 ]; then ML2=$VAL; fi
        if [ "$run" -eq 3 ]; then ML3=$VAL; fi
    done

    # Výpočet průměru pomocí kalkulátoru 'bc' (zaokrouhleno na 3 desetinná místa)
    AVERAGE=$(echo "scale=3; ($ML1 + $ML2 + $ML3) / 3" | bc -l | awk '{printf "%.3f", $0}')
    
    echo "    [✓] Průměrná hodnota pro ploidii $TESTED_PLOIDY: $AVERAGE"

    # Zápis jednoho kompletního řádku do CSV
    echo "${SAMPLE_NAME};${TESTED_PLOIDY};${ML1};${ML2};${ML3};${AVERAGE}" >> "$RESULTS_CSV"

done

# ------------------------------------------------------------------------------
# FÁZE 2: AUTOMATICKÉ VYHODNOCENÍ NEJLEPŠÍ PLOIDIE
# ------------------------------------------------------------------------------
FINAL_REPORT="scripts/data/ss_doporucena_ploidie.csv"

echo "Všechny běhy dokončeny. Vyhodnocuji nejlepší ploidie..."

# Pomocí 'awk' projdeme naši tabulku a vygenerujeme čistý CSV výstup
awk -F';' '
BEGIN {
    # Vytiskneme čistou hlavičku tabulky
    print "Vzorek;Doporucena_Ploidie"
}
NR > 1 {
    # Pole $1 je vzorek, $2 je ploidie, $6 je průměr
    vzorek = $1
    ploidie = $2
    prumer = $6
    
    # Pokud vzorek ještě nemáme v paměti, nebo je nový průměr vyšší (blíž k nule)
    if (!(vzorek in max_val) || prumer > max_val[vzorek]) {
        max_val[vzorek] = prumer
        best_ploid[vzorek] = ploidie
    }
}
END {
    # Na konci vypíšeme čistě jen jméno vzorku a vítěznou ploidii oddělené středníkem
    for (v in best_ploid) {
        printf "%s;%s\n", v, best_ploid[v]
    }
}' "$RESULTS_CSV" > "$FINAL_REPORT"

echo "HOTOVO!"
echo "Kompletní data (všechny běhy): $RESULTS_CSV"
echo "Čistý výsledek k dalšímu užití: $FINAL_REPORT"