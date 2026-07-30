#!/bin/bash

# ==========================================
#  NASTAVENÍ PROMĚNNÝCH
# ==========================================

GENES=("EIF3E" "RPB2")

CORE_CSV_FILE="scripts/data/core_vzorky.csv" # Tabulka s tvými 7 (či více) stálými vzorky
TARGET_CSV_FILE="scripts/data/dalsi_vzorky.csv" # Tabulka se vzorky, které se budou doplňovat

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

    # Načtení seznamu CORE vzorků z 1. tabulky 
    # (Přeskočí první řádek s hlavičkou, odstraní neviditelné znaky a vezme první sloupec)
    CORE_SAMPLES=()
    while read -r CORE_SAMPLE; do
        if [[ -n "$CORE_SAMPLE" ]]; then
            CORE_SAMPLES+=("$CORE_SAMPLE")
        fi
    done < <(tail -n +2 "$CORE_CSV_FILE" | tr -d '\r' | awk -F'[,; \t]' '{print $1}')

    echo "Z tabulky '$CORE_CSV_FILE' načteno ${#CORE_SAMPLES[@]} základních vzorků."

    # Dynamické dohledání všech kopií/alel pro CORE vzorky přímo v NEXUSu
    ACTUAL_CORE_COPIES=()
    for core_base in "${CORE_SAMPLES[@]}"; do
        found_copies=($(grep -o -E "${core_base}_[a-zA-Z0-9]*" "$NEXUS_FILE" | sort -u))

        if [ ${#found_copies[@]} -eq 0 ]; then
            echo "⚠️ Varování: Core vzorek '$core_base' nebyl v NEXUS souboru nalezen!"
        else
            ACTUAL_CORE_COPIES+=("${found_copies[@]}")
        fi
    done

    NUM_CORE=${#ACTUAL_CORE_COPIES[@]}
    echo "Nalezeno celkem $NUM_CORE reálných alel/kopií pro core vzorky."
    echo "------------------------------------------------------------"

    # ==========================================
    # 3. HLAVNÍ SMYČKA PRO CÍLOVÉ VZORKY (Z 2. TABULKY)
    # ==========================================
    # Prochází 2. tabulku řádek po řádku
        tail -n +2 "$TARGET_CSV_FILE" | tr -d '\r' | awk -F'[,; \t]' '{print $1}' | while read -r TARGET_SAMPLE; do

            if [[ -z "$TARGET_SAMPLE" ]]; then continue; fi

        # Dohledání všech kopií pro cílový vzorek v NEXUSu
        ACTUAL_TARGET_COPIES=($(grep -o -E "${TARGET_SAMPLE}_[a-zA-Z0-9]*" "$NEXUS_FILE" | sort -u))
        NUM_TARGET=${#ACTUAL_TARGET_COPIES[@]}

        if [ "$NUM_TARGET" -eq 0 ]; then
            echo "⚠️ Pozor: Přidávaný vzorek '$TARGET_SAMPLE' nebyl nalezen. Přeskakuji."
            continue
        fi

        # Výpočet celkového ntax pro daný soubor
        TOTAL_NTAX=$((NUM_CORE + NUM_TARGET))
        OUT_FILE="$OUTPUT_DIR/${GENE}_${TARGET_SAMPLE}.nex"

        # --- ZÁPIS HLAVIČKY (TAXA BLOCK) ---
        echo "#NEXUS" > "$OUT_FILE"
        echo "" >> "$OUT_FILE"
        echo "BEGIN TAXA;" >> "$OUT_FILE"
        echo "	DIMENSIONS ntax=${TOTAL_NTAX};" >> "$OUT_FILE"
        echo -n "	TAXLABELS  " >> "$OUT_FILE"

       # Vypsání všech dohledaných CORE kopií
       for core_copy in "${ACTUAL_CORE_COPIES[@]}"; do
           echo -n "$core_copy " >> "$OUT_FILE"
       done

       # Vypsání všech dohledaných cílových kopií
       for target_copy in "${ACTUAL_TARGET_COPIES[@]}"; do
           echo -n "$target_copy " >> "$OUT_FILE"
       done

       sed -i 's/ $//' "$OUT_FILE" # Odstranění mezery na konci
      echo ";" >> "$OUT_FILE"
      echo "END;" >> "$OUT_FILE"
      echo "" >> "$OUT_FILE"

     # --- ZÁPIS MATICE (CHARACTERS BLOCK) ---
     echo "BEGIN CHARACTERS;" >> "$OUT_FILE"
     echo "	DIMENSIONS nchar=$NCHAR;" >> "$OUT_FILE"
     echo "	FORMAT datatype=DNA gap=-;" >> "$OUT_FILE"
     echo "	MATRIX" >> "$OUT_FILE"

     # Vytažení sekvencí pro všechny CORE kopie
     for core_copy in "${ACTUAL_CORE_COPIES[@]}"; do
         grep -E "^[[:space:]]*${core_copy}\b" "$NEXUS_FILE" >> "$OUT_FILE"
     done

     # Vytažení sekvencí pro všechny cílové kopie
     for target_copy in "${ACTUAL_TARGET_COPIES[@]}"; do
         grep -E "^[[:space:]]*${target_copy}\b" "$NEXUS_FILE" >> "$OUT_FILE"
     done

     echo "	;" >> "$OUT_FILE"
     echo "END;" >> "$OUT_FILE"

     echo "Vytvořen soubor: $OUT_FILE (ntax=$TOTAL_NTAX)"

    done

done

echo "------------------------------------------------------------"
echo "Done. Outputs in file: '$OUTPUT_DIR'."