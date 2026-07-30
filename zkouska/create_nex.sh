#!/bin/bash

# ==========================================
#  NASTAVENÍ PROMĚNNÝCH
# ==========================================

GENES=("EIF3E" "RPB2")
CORE_CSV_FILE="scripts/data/core_vzorky.csv" 
TARGET_CSV_FILE="scripts/data/dalsi_vzorky.csv" 
OUTPUT_DIR="scripts/data/ss_scripty/male_nexus_soubory"

mkdir -p "$OUTPUT_DIR"

# ==========================================
# HLAVNÍ SMYČKA PRO VŠECHNY GENY
# ==========================================

for GENE in "${GENES[@]}"; do

    NEXUS_FILE="scripts/data/${GENE}_test.nex"

    echo "========================================"
    echo "Zpracovávám gen $GENE"

    # Automaticky zjistí počet znaků (nchar) z NEXUSu
    NCHAR=$(grep -i -E "DIMENSIONS nchar=[0-9]+" "$NEXUS_FILE" | grep -o -E "[0-9]+")
    echo "Zahajuji... Detekován počet znaků: $NCHAR"

    # Načtení seznamu CORE vzorků
    CORE_SAMPLES=()
    while read -r CORE_SAMPLE; do
        if [[ -n "$CORE_SAMPLE" ]]; then
            CORE_SAMPLES+=("$CORE_SAMPLE")
        fi
    done < <(tail -n +2 "$CORE_CSV_FILE" | tr -d '\r' | awk -F'[,; \t]' '{print $1}')

    echo "Z tabulky '$CORE_CSV_FILE' načteno ${#CORE_SAMPLES[@]} základních vzorků."

    # --- HLEDÁNÍ CORE VZORKŮ A JEJICH PŘEJMENOVÁNÍ ---
    ACTUAL_CORE_RAW=() # Názvy přesně jak jsou v master NEXUSu
    ACTUAL_CORE_NEW=() # Názvy s doplněným _copy1 (pokud chybělo)

    for core_base in "${CORE_SAMPLES[@]}"; do
        # Regex najde čistý název I název s podtržítkem
        found_raw_copies=($(grep -o -E "\b${core_base}(_[a-zA-Z0-9]+)?\b" "$NEXUS_FILE" | sort -u))

        if [ ${#found_raw_copies[@]} -eq 0 ]; then
            echo "⚠️ Varování: Core vzorek '$core_base' nebyl v NEXUS souboru nalezen!"
        else
            for raw_copy in "${found_raw_copies[@]}"; do
                ACTUAL_CORE_RAW+=("$raw_copy")
                # Pokud skript našel "holý" název, přidá mu "_copy1"
                if [[ "$raw_copy" == "$core_base" ]]; then
                    ACTUAL_CORE_NEW+=("${core_base}_copy1")
                else
                    ACTUAL_CORE_NEW+=("$raw_copy")
                fi
            done
        fi
    done

    NUM_CORE=${#ACTUAL_CORE_RAW[@]}
    echo "Nalezeno celkem $NUM_CORE reálných alel/kopií pro core vzorky."
    echo "------------------------------------------------------------"

    # ==========================================
    # 3. HLAVNÍ SMYČKA PRO CÍLOVÉ VZORKY 
    # ==========================================
    tail -n +2 "$TARGET_CSV_FILE" | tr -d '\r' | awk -F'[,; \t]' '{print $1}' | while read -r TARGET_SAMPLE; do

        if [[ -z "$TARGET_SAMPLE" ]]; then continue; fi

        ACTUAL_TARGET_RAW=()
        ACTUAL_TARGET_NEW=()

        # Regex pro Target vzorek
        found_target_raw=($(grep -o -E "\b${TARGET_SAMPLE}(_[a-zA-Z0-9]+)?\b" "$NEXUS_FILE" | sort -u))
        NUM_TARGET=${#found_target_raw[@]}

        if [ "$NUM_TARGET" -eq 0 ]; then
            echo "⚠️ Pozor: Přidávaný vzorek '$TARGET_SAMPLE' nebyl nalezen. Přeskakuji."
            continue
        fi

        # Zpracování jmen target vzorku
        for raw_copy in "${found_target_raw[@]}"; do
            ACTUAL_TARGET_RAW+=("$raw_copy")
            if [[ "$raw_copy" == "$TARGET_SAMPLE" ]]; then
                ACTUAL_TARGET_NEW+=("${TARGET_SAMPLE}_copy1")
            else
                ACTUAL_TARGET_NEW+=("$raw_copy")
            fi
        done

        TOTAL_NTAX=$((NUM_CORE + NUM_TARGET))
        OUT_FILE="$OUTPUT_DIR/${GENE}_${TARGET_SAMPLE}.nex"

        # --- ZÁPIS HLAVIČKY (TAXA BLOCK) ---
        echo "#NEXUS" > "$OUT_FILE"
        echo "" >> "$OUT_FILE"
        echo "BEGIN TAXA;" >> "$OUT_FILE"
        echo "  DIMENSIONS ntax=${TOTAL_NTAX};" >> "$OUT_FILE"
        echo -n "   TAXLABELS  " >> "$OUT_FILE"

        # Vypíšeme NOVÉ názvy (již opravené o _copy1) pro CORE
        for new_copy in "${ACTUAL_CORE_NEW[@]}"; do
            echo -n "$new_copy " >> "$OUT_FILE"
        done

        # Vypíšeme NOVÉ názvy pro TARGET
        for new_copy in "${ACTUAL_TARGET_NEW[@]}"; do
            echo -n "$new_copy " >> "$OUT_FILE"
        done

        sed -i 's/ $//' "$OUT_FILE" 
        echo ";" >> "$OUT_FILE"
        echo "END;" >> "$OUT_FILE"
        echo "" >> "$OUT_FILE"

        # --- ZÁPIS MATICE (CHARACTERS BLOCK) ---
        echo "BEGIN CHARACTERS;" >> "$OUT_FILE"
        echo " DIMENSIONS nchar=$NCHAR;" >> "$OUT_FILE"
        echo " FORMAT datatype=DNA gap=-;" >> "$OUT_FILE"
        echo " MATRIX" >> "$OUT_FILE"

        # Vytažení sekvencí pro CORE kopie + okamžité přejmenování
        for i in "${!ACTUAL_CORE_RAW[@]}"; do
            raw_copy="${ACTUAL_CORE_RAW[$i]}"
            new_copy="${ACTUAL_CORE_NEW[$i]}"
            
            # grep najde starý název, sed ho nahradí novým názvem a výsledek jde do souboru
            grep -E "^[[:space:]]*${raw_copy}\b" "$NEXUS_FILE" | sed -E "s/\b${raw_copy}\b/${new_copy}/" >> "$OUT_FILE"
        done

        # Vytažení sekvencí pro TARGET kopie + okamžité přejmenování
        for i in "${!ACTUAL_TARGET_RAW[@]}"; do
            raw_copy="${ACTUAL_TARGET_RAW[$i]}"
            new_copy="${ACTUAL_TARGET_NEW[$i]}"
            
            grep -E "^[[:space:]]*${raw_copy}\b" "$NEXUS_FILE" | sed -E "s/\b${raw_copy}\b/${new_copy}/" >> "$OUT_FILE"
        done

        echo " ;" >> "$OUT_FILE"
        echo "END;" >> "$OUT_FILE"

        echo "Vytvořen soubor: $OUT_FILE (ntax=$TOTAL_NTAX)"

    done

done

echo "------------------------------------------------------------"
echo "Done. Outputs in file: '$OUTPUT_DIR'."