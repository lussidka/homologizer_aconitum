#!/bin/bash

GENES=("EIF3E" "RPB2")
CORE_CSV_FILE="scripts/data/core_samples.csv" 
TARGET_CSV_FILE="scripts/data/target_samples.csv" 
OUTPUT_DIR="scripts/nexus_files_samples"

# Nastavte požadovaný počet target vzorků (např. 10, 50 atd.)
NUM_TARGET_TO_TAKE=50

mkdir -p "$OUTPUT_DIR"

# ==========================================
# MAIN LOOP FOR ALL GENES
# ==========================================

for GENE in "${GENES[@]}"; do

    NEXUS_FILE="scripts/data/${GENE}_test.nex"

    # Automatically detect the number of characters (nchar) from the NEXUS file
    NCHAR=$(grep -i -E "DIMENSIONS nchar=[0-9]+" "$NEXUS_FILE" | grep -o -E "[0-9]+")
    echo "------------------------------------------------------------"
    echo "Processing gene: $GENE"
    echo "Number of characters detected: $NCHAR"

    # --- 1. Load CORE samples ---
    CORE_SAMPLES=()
    while read -r CORE_SAMPLE; do
        if [[ -n "$CORE_SAMPLE" ]]; then
            CORE_SAMPLES+=("$CORE_SAMPLE")
        fi
    done < <(tail -n +2 "$CORE_CSV_FILE" | tr -d '\r' | awk -F'[,; \t]' '{print $1}')

    echo "Number of core samples loaded: ${#CORE_SAMPLES[@]}"

    ACTUAL_CORE_RAW=() 
    ACTUAL_CORE_NEW=() 

    for core_base in "${CORE_SAMPLES[@]}"; do
        found_raw_copies=($(grep -o -E "\b${core_base}(_[a-zA-Z0-9]+)?\b" "$NEXUS_FILE" | sort -u))

        if [ ${#found_raw_copies[@]} -eq 0 ]; then
            echo "⚠️ Warning: Core sample '$core_base' not found in the NEXUS file!"
        else
            for raw_copy in "${found_raw_copies[@]}"; do
                ACTUAL_CORE_RAW+=("$raw_copy")
                if [[ "$raw_copy" == "$core_base" ]]; then
                    ACTUAL_CORE_NEW+=("${core_base}_copy1")
                else
                    ACTUAL_CORE_NEW+=("$raw_copy")
                fi
            done
        fi
    done

    NUM_CORE=${#ACTUAL_CORE_RAW[@]}

    # --- 2. Load top N TARGET samples ---
    TARGET_SAMPLES=()
    while read -r TARGET_SAMPLE; do
        if [[ -n "$TARGET_SAMPLE" ]]; then
            TARGET_SAMPLES+=("$TARGET_SAMPLE")
        fi
    done < <(tail -n +2 "$TARGET_CSV_FILE" | tr -d '\r' | awk -F'[,; \t]' '{print $1}' | head -n "$NUM_TARGET_TO_TAKE")

    echo "Loaded top ${#TARGET_SAMPLES[@]} target samples from '$TARGET_CSV_FILE'"

    ACTUAL_TARGET_RAW=()
    ACTUAL_TARGET_NEW=()

    for target_base in "${TARGET_SAMPLES[@]}"; do
        found_target_raw=($(grep -o -E "\b${target_base}(_[a-zA-Z0-9]+)?\b" "$NEXUS_FILE" | sort -u))

        if [ ${#found_target_raw[@]} -eq 0 ]; then
            echo "⚠️ Warning: Target sample '$target_base' not found in the NEXUS file."
            continue
        fi

        for raw_copy in "${found_target_raw[@]}"; do
            ACTUAL_TARGET_RAW+=("$raw_copy")
            if [[ "$raw_copy" == "$target_base" ]]; then
                ACTUAL_TARGET_NEW+=("${target_base}_copy1")
            else
                ACTUAL_TARGET_NEW+=("$raw_copy")
            fi
        done
    done

    NUM_TARGET=${#ACTUAL_TARGET_RAW[@]}
    TOTAL_NTAX=$((NUM_CORE + NUM_TARGET))
    OUT_FILE="$OUTPUT_DIR/${GENE}_${NUM_TARGET_TO_TAKE}targets.nex"

    # --- 3. Creation of HEADER (TAXA BLOCK) ---
    echo "#NEXUS" > "$OUT_FILE"
    echo "" >> "$OUT_FILE"
    echo "BEGIN TAXA;" >> "$OUT_FILE"
    echo "  DIMENSIONS ntax=${TOTAL_NTAX};" >> "$OUT_FILE"
    echo -n "   TAXLABELS  " >> "$OUT_FILE"

    for new_copy in "${ACTUAL_CORE_NEW[@]}"; do
        echo -n "$new_copy " >> "$OUT_FILE"
    done

    for new_copy in "${ACTUAL_TARGET_NEW[@]}"; do
        echo -n "$new_copy " >> "$OUT_FILE"
    done

    sed -i 's/ $//' "$OUT_FILE" 
    echo ";" >> "$OUT_FILE"
    echo "END;" >> "$OUT_FILE"
    echo "" >> "$OUT_FILE"

    # --- 4. Creation of MATRIX (CHARACTERS BLOCK) ---
    echo "BEGIN CHARACTERS;" >> "$OUT_FILE"
    echo " DIMENSIONS nchar=$NCHAR;" >> "$OUT_FILE"
    echo " FORMAT datatype=DNA gap=-;" >> "$OUT_FILE"
    echo " MATRIX" >> "$OUT_FILE"

    # Sequences for CORE copies
    for i in "${!ACTUAL_CORE_RAW[@]}"; do
        raw_copy="${ACTUAL_CORE_RAW[$i]}"
        new_copy="${ACTUAL_CORE_NEW[$i]}"
        grep -E "^[[:space:]]*${raw_copy}\b" "$NEXUS_FILE" | sed -E "s/\b${raw_copy}\b/${new_copy}/" >> "$OUT_FILE"
    done

    # Sequences for TARGET copies
    for i in "${!ACTUAL_TARGET_RAW[@]}"; do
        raw_copy="${ACTUAL_TARGET_RAW[$i]}"
        new_copy="${ACTUAL_TARGET_NEW[$i]}"
        grep -E "^[[:space:]]*${raw_copy}\b" "$NEXUS_FILE" | sed -E "s/\b${raw_copy}\b/${new_copy}/" >> "$OUT_FILE"
    done

    echo " ;" >> "$OUT_FILE"
    echo "END;" >> "$OUT_FILE"

    echo "Created file: $OUT_FILE (ntax=$TOTAL_NTAX: $NUM_CORE core copies + $NUM_TARGET target copies)"

done

echo "------------------------------------------------------------"
echo "Done. Outputs saved in: '$OUTPUT_DIR'."