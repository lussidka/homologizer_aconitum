#!/bin/bash

# ==============================================================================
# RevBayes Stepping Stone - Výpočet a vyhodnocení ploidie
# ==============================================================================

RESULTS_CSV="scripts/data/vysledky_vsechny_behy.csv"
FINAL_REPORT="scripts/data/ss_doporucena_ploidie.csv"

mkdir -p scripts/data

# ------------------------------------------------------------------------------
# FÁZE 1: SPOUŠTĚNÍ REVBAYES A EXTRAKCE DAT
# ------------------------------------------------------------------------------
echo "Spouštím Fázi 1: Sběr dat z RevBayes logů..."

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
# FÁZE 2: AUTOMATICKÉ VYHODNOCENÍ NEJLEPŠÍ PLOIDIE A BAYESOVA FAKTORU
# ------------------------------------------------------------------------------
echo "Všechny běhy dokončeny. Vyhodnocuji nejlepší ploidie a Bayesovy faktory..."

# Nastavíme standardní formát čísel (tečky místo čárek), aby AWK počítal bez chyb
export LC_ALL=C

awk -F';' '
BEGIN {
    # Vytiskneme čistou hlavičku tabulky
    print "Vzorek;Doporucena_Ploidie;Bayes_Factor;Evidence"
}
NR > 1 {
    vzorek = $1
    ploidie = $2
    prumer = $6
    
    # Pokud čteme vzorek úplně poprvé
    if (!(vzorek in best_score)) {
        best_score[vzorek] = prumer
        best_ploid[vzorek] = ploidie
        # Druhé místo zatím neexistuje, dáme extrémně nízkou hodnotu
        second_score[vzorek] = -999999999.0
        count[vzorek] = 1
    } else {
        count[vzorek]++
        # Pokud najdeme NOVOU NEJLEPŠÍ hodnotu (vyšší marginal likelihood)
        if (prumer > best_score[vzorek]) {
            # Dosavadní vítěz se posouvá na druhé místo
            second_score[vzorek] = best_score[vzorek]
            # Uložíme nového vítěze
            best_score[vzorek] = prumer
            best_ploid[vzorek] = ploidie
            
        # Pokud to není nejlepší, ale je to LEPŠÍ NEŽ DOSAVADNÍ DRUHÝ
        } else if (prumer > second_score[vzorek]) {
            second_score[vzorek] = prumer
        }
    }
}
END {
    # Výpis všech vzorků do výsledné tabulky
    for (v in best_score) {
        # Pokud se pro vzorek testovalo VÍCE než 1 ploidií (je s čím srovnávat)
        if (count[v] > 1) {
            
            # Výpočet BF: Log Marginal Likelihood 1. modelu - Log Marginal Likelihood 2. modelu
            bf = best_score[v] - second_score[v]
            
            # Kategorizace evidence podle Kass & Raftery (1995)
            if (bf > 150)       evidence = "Velmi_silna"
            else if (bf >= 20)  evidence = "Silna"
            else if (bf >= 3)   evidence = "Pozorovatelna"
            else if (bf >= 1)   evidence = "Slaba"
            else                evidence = "Zanedbatelna"
            
            # Vytiskneme vzorek; ploidie; BF (na 3 desetiná místa); evidence
            printf "%s;%s;%.3f;%s\n", v, best_ploid[v], bf, evidence
        } else {
            # Pokud se testoval jen jeden model, nelze spočítat rozdíl
            printf "%s;%s;NA;Nelze_porovnat\n", v, best_ploid[v]
        }
    }
}' "$RESULTS_CSV" > "$FINAL_REPORT"


# ------------------------------------------------------------------------------
# FÁZE 3: ZÁVĚREČNÁ KONTROLA A VAROVÁNÍ PRO UŽIVATELE
# ------------------------------------------------------------------------------
echo ""
echo "=========================================================="
echo " ZÁVĚREČNÁ KONTROLA SPOLEHLIVOSTI (BAYES FACTOR)"
echo "=========================================================="

# Hledáme v naší nové tabulce řádky s nízkou evidencí
WARNINGS=$(grep -E "Slaba|Zanedbatelna" "$FINAL_REPORT")

if [ -n "$WARNINGS" ]; then
    echo " ⚠️  POZOR: Následující vzorky mají velmi nízkou evidenci!"
    echo " Rozdíl mezi nejlepší a druhou nejlepší ploidií je příliš malý."
    echo " Doporučujeme tyto vzorky zkontrolovat manuálně, případně ploidii nedělat závaznou."
    echo ""
    
    # Hezký formátovaný výpis problémových vzorků do terminálu
    while IFS=';' read -r vzorek ploidie bf evidence; do
        echo "  -> Vzorek: $vzorek"
        echo "     Vybraná ploidie: $ploidie | Bayesův faktor: $bf ($evidence)"
        echo "     (Data nemusí být dostatečně průkazná pro jednoznačné rozhodnutí.)"
        echo ""
    done <<< "$WARNINGS"
else
    echo " ✅ Vše v pořádku!"
    echo " Všechny porovnávané vzorky dosáhly minimálně 'Pozorovatelné' (nebo lepší) evidence."
fi

echo "=========================================================="
echo "HOTOVO!"
echo "Kompletní data (všechny běhy): $RESULTS_CSV"
echo "Čistý výsledek s Bayesovým faktorem: $FINAL_REPORT"
echo "=========================================================="