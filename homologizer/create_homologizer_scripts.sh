#!/bin/bash

# ==========================================
# 1. NASTAVENÍ SLOŽEK A SOUBORŮ
# ==========================================
TABULKA="nejlepsi_ploidie.csv"
SLOZKA_STARYCH="ss_scripty"
SLOZKA_NOVYCH="homologizer_scripty"

# Vytvoření výstupní složky, pokud neexistuje
mkdir -p "$SLOZKA_NOVYCH"

# ==========================================
# 2. DEFINICE NOVÉHO KÓDU PRO HOMOLOGIZER
# ==========================================
# Pozor: Na konci každého řádku (kromě posledního) musí být zpětné lomítko '\'
# Toto je text, kterým se nahradí starý odstavec.
NOVY_KOD='mymcmc = mcmc(mymodel, monitors, moves, nruns=2, combine="mixed")\
mymcmc.run(generations=50000, tuningInterval=200)'

# ==========================================
# 3. ZPRACOVÁNÍ TABULKY
# ==========================================
# Přeskočíme první řádek (hlavičku) pomocí 'tail -n +2'
# IFS=',' říká, že oddělovač sloupců v CSV je čárka
tail -n +2 "$TABULKA" | while IFS=',' read -r vzorek ploidie zbytek_radku; do
    
    # Očištění proměnných od neviditelných znaků (častý problém u CSV z Windows)
    vzorek=$(echo "$vzorek" | tr -d '\r' | xargs)
    ploidie=$(echo "$ploidie" | tr -d '\r' | xargs)
    
    # Sestavení jmen souborů (UPRAV PODLE TOHO, JAK SE TVÉ SOUBORY OPRAVDU JMENUJÍ)
    stary_skript="${SLOZKA_STARYCH}/${vzorek}_ploidy_${ploidie}.Rev"
    novy_skript="${SLOZKA_NOVYCH}/${vzorek}_homologizer.Rev"
    
    # Kontrola, zda starý skript existuje
    if [[ ! -f "$stary_skript" ]]; then
        echo "VAROVÁNÍ: Soubor $stary_skript nebyl nalezen. Přeskakuji..."
        continue
    fi
    
    # ==========================================
    # 4. NAHRAZENÍ TEXTU POMOCÍ 'sed'
    # ==========================================
    # '/ZAČÁTEK/,/KONEC/c\' znamená: najdi blok od ZAČÁTEK do KONEC a nahraď (c\) ho proměnnou NOVY_KOD
    # ZDE UPRAV TEXTY TAK, ABY ODPOVÍDALY PRVNÍMU A POSLEDNÍMU ŘÁDKU STARÉHO ODSTAVCE:
    
    sed '/pow_p = powerPosterior/,/ss.marginal()/c\
'"$NOVY_KOD" "$stary_skript" > "$novy_skript"
    
    echo "Hotovo: $novy_skript"

done

echo "Všechny skripty byly úspěšně vygenerovány!"