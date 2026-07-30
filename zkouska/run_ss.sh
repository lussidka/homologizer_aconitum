#!/bin/bash

# Složka, kde se nachází vygenerované .Rev skripty
SCRIPT_DIR="scripts/data/ss_scripty"

# Nová složka, kam se budou ukládat .txt výpisy z terminálu
LOG_DIR="scripts/data/ss_vypisy"
mkdir -p "$LOG_DIR"

echo "Začínám spouštět RevBayes analýzy..."

# Cyklus, který najde všechny .Rev soubory ve vaší složce
for rev_script in "$SCRIPT_DIR"/*.Rev; do
    
    # Pojistka: pokud by složka byla prázdná, cyklus se ukončí
    [ -e "$rev_script" ] || continue

    # Získáme čistý název souboru bez složek a bez přípony .Rev
    # Příklad: z "scripts/data/ss_scripty/ss_n_PPSK4_177_3tips.Rev" udělá "ss_n_PPSK4_177_3tips"
    BASE_NAME=$(basename "$rev_script" .Rev)

    echo "=========================================================="
    echo "Zpracovávám skript: $BASE_NAME"
    echo "=========================================================="

    # Vnitřní cyklus, který se pro každý skript zopakuje přesně 3x
    for run in {1..3}; do
        
        # Vytvoření názvu txt souboru přesně podle vašeho požadavku
        TXT_FILE="${LOG_DIR}/${BASE_NAME}_${run}.txt"
        
        echo " -> Spouštím běh ${run}/3... Výpis se ukládá do: $TXT_FILE"
        
        # Samotné spuštění RevBayes (předpokládám, že ho voláte příkazem 'rb').
        # Znak '>' přesměruje normální výpis do souboru.
        # Výraz '2>&1' je trik, který do souboru přesměruje i případné chybové hlášky (stderr),
        # abyste v tom txt souboru měla opravdu úplně všechno, co by jinak vyskočilo na obrazovku.
        
        rb "$rev_script" > "$TXT_FILE" 2>&1
        
    done
done

echo "Všechny analýzy byly úspěšně dokončeny!"