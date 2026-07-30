#!/bin/bash

# ==============================================================================
# SCRIPT 2: SPOUŠTĚČ ANALÝZ A SBĚRAČ VÝSLEDKŮ
# ==============================================================================

# Složky
SCRIPT_DIR="scripts/data/ss_scripty"
LOG_DIR="scripts/data/ss_vypisy"
RESULTS_CSV="scripts/data/ss_vysledky.csv"

# Vytvoření složky pro textové výpisy, pokud neexistuje
mkdir -p "$LOG_DIR"

# Založení výsledkové tabulky s hlavičkou (pokud už neexistuje z dřívějška)
if [ ! -f "$RESULTS_CSV" ]; then
    echo "Nazev_Skriptu;Cislo_Behu;Marginal_Likelihood" > "$RESULTS_CSV"
fi

echo "Začínám spouštět RevBayes analýzy..."

# Cyklus přes všechny vygenerované .Rev skripty
for rev_script in "$SCRIPT_DIR"/*.Rev; do
    
    # Pojistka: pokud by složka byla prázdná
    [ -e "$rev_script" ] || continue
    
    # Získáme název bez složek a přípony (např. ss_n_PPSK4_177_3tips)
    BASE_NAME=$(basename "$rev_script" .Rev)

    echo "=========================================================="
    echo "Zpracovávám skript: $BASE_NAME"
    echo "=========================================================="

    # Vnitřní cyklus: 3 opakování pro každý skript
    for run in {1..3}; do
        
        TXT_FILE="${LOG_DIR}/${BASE_NAME}_${run}.txt"
        echo " -> Spouštím běh ${run}/3... Výpis terminálu se ukládá do: $TXT_FILE"
        
        # 1. KROK: SPUŠTĚNÍ REVBAYES
        # (Pokud musíte zadávat cestu k rb, např. /bin/rb, upravte si to zde)
        rb "$rev_script" > "$TXT_FILE" 2>&1
        
        # 2. KROK: EXTRAKCE ČÍSLA HNED PO SKONČENÍ ANALÝZY
        # Najdeme text 'Step 50 / 50', vezmeme hned následující řádek a smažeme z něj mezery
        ML_VALUE=$(grep -A 1 "Step 50 / 50" "$TXT_FILE" | tail -n 1 | tr -d '[:space:]')

        # Zkontrolujeme, jestli se číslo opravdu našlo
        if [ -z "$ML_VALUE" ] || [[ "$ML_VALUE" == *"*"* ]]; then
            ML_VALUE="CHYBA_NENALEZENO"
            echo "    [!] Pozor: Ve výpisu se nepodařilo najít marginal likelihood."
        else
            echo "    [✓] Úspěch! Zapisuji Marginal Likelihood: $ML_VALUE"
        fi

        # 3. KROK: ZÁPIS DO TABULKY
        echo "${BASE_NAME};${run};${ML_VALUE}" >> "$RESULTS_CSV"
        
    done
done

echo "=========================================================="
echo "Všechny analýzy byly úspěšně dokončeny!"
echo "Textové záznamy běhů najdete ve složce: $LOG_DIR"
echo "Finální tabulku s výsledky najdete zde: $RESULTS_CSV"
echo "=========================================================="