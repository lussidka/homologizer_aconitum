#!/bin/bash

GENES=("EIF3E" "RPB2")
CORE_CSV_FILE="scripts/data/core_samples.csv" 
TARGET_CSV_FILE="scripts/data/target_samples.csv" 
OUTPUT_DIR="scripts/data/ss_scripty/nexus_files_samples"

mkdir -p "$OUTPUT_DIR"

# ==========================================
# MAIN LOOP FOR ALL GENES
# ==========================================

for GENE in "${GENES[@]}"; do

    NEXUS_FILE="scripts/data/${GENE}_test.nex"

    # Automatically detect the number of characters (nchar) from the NEXUS file
    NCHAR=$(grep -i -E "DIMENSIONS nchar=[0-9]+" "$NEXUS_FILE" | grep -o -E "[0-9]+")
    echo "Number of characters detected: $NCHAR"

    # Load core samples from the CSV file, ignoring empty lines and trimming whitespace
    CORE_SAMPLES=()
    while read -r CORE_SAMPLE; do
        if [[ -n "$CORE_SAMPLE" ]]; then
            CORE_SAMPLES+=("$CORE_SAMPLE")
        fi
    done < <(tail -n +2 "$CORE_CSV_FILE" | tr -d '\r' | awk -F'[,; \t]' '{print $1}')

    echo "Number of core samples loaded from '$CORE_CSV_FILE': ${#CORE_SAMPLES[@]}"

    # search and rename (copy1) core samples in the NEXUS file
    ACTUAL_CORE_RAW=() 
    ACTUAL_CORE_NEW=() 

    for core_base in "${CORE_SAMPLES[@]}"; do
        found_raw_copies=($(grep -o -E "\b${core_base}(_[a-zA-Z0-9]+)?\b" "$NEXUS_FILE" | sort -u))

        if [ ${#found_raw_copies[@]} -eq 0 ]; then
            echo "⚠️ Warning: Core sample '$core_base' not found in the NEXUS file!"
        else
            for raw_copy in "${found_raw_copies[@]}"; do
                ACTUAL_CORE_RAW+=("$raw_copy")
                # If the script found a "bare" name, add "_copy1"
                if [[ "$raw_copy" == "$core_base" ]]; then
                    ACTUAL_CORE_NEW+=("${core_base}_copy1")
                else
                    ACTUAL_CORE_NEW+=("$raw_copy")
                fi
            done
        fi
    done

    NUM_CORE=${#ACTUAL_CORE_RAW[@]}
    echo "Number of core copies found: $NUM_CORE"
    echo "------------------------------------------------------------"

    # ==========================================
    #  MAIN LOOP FOR TARGET SAMPLES
    # ==========================================
    tail -n +2 "$TARGET_CSV_FILE" | tr -d '\r' | awk -F'[,; \t]' '{print $1}' | while read -r TARGET_SAMPLE; do

        if [[ -z "$TARGET_SAMPLE" ]]; then continue; fi

        ACTUAL_TARGET_RAW=()
        ACTUAL_TARGET_NEW=()

        # Regex for Target samples
        found_target_raw=($(grep -o -E "\b${TARGET_SAMPLE}(_[a-zA-Z0-9]+)?\b" "$NEXUS_FILE" | sort -u))
        NUM_TARGET=${#found_target_raw[@]}

        if [ "$NUM_TARGET" -eq 0 ]; then
            echo "⚠️ Warning: Target sample '$TARGET_SAMPLE' not found in the NEXUS file."
            continue
        fi

        # Name processing for Target samples
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

        # --- creation of HEADER (TAXA BLOCK) ---
        echo "#NEXUS" > "$OUT_FILE"
        echo "" >> "$OUT_FILE"
        echo "BEGIN TAXA;" >> "$OUT_FILE"
        echo "  DIMENSIONS ntax=${TOTAL_NTAX};" >> "$OUT_FILE"
        echo -n "   TAXLABELS  " >> "$OUT_FILE"

        # Writing NEW names (already corrected with _copy1) for CORE samples
        for new_copy in "${ACTUAL_CORE_NEW[@]}"; do
            echo -n "$new_copy " >> "$OUT_FILE"
        done

        # Writing NEW names for TARGET samples
        for new_copy in "${ACTUAL_TARGET_NEW[@]}"; do
            echo -n "$new_copy " >> "$OUT_FILE"
        done

        sed -i 's/ $//' "$OUT_FILE" 
        echo ";" >> "$OUT_FILE"
        echo "END;" >> "$OUT_FILE"
        echo "" >> "$OUT_FILE"

        # --- creation of CHARACTER MATRIX (CHARACTERS BLOCK) ---
        echo "BEGIN CHARACTERS;" >> "$OUT_FILE"
        echo " DIMENSIONS nchar=$NCHAR;" >> "$OUT_FILE"
        echo " FORMAT datatype=DNA gap=-;" >> "$OUT_FILE"
        echo " MATRIX" >> "$OUT_FILE"

        for i in "${!ACTUAL_CORE_RAW[@]}"; do
            raw_copy="${ACTUAL_CORE_RAW[$i]}"
            new_copy="${ACTUAL_CORE_NEW[$i]}"
            
            # grep finds the old name, sed replaces it with the new name, and the result goes to the file
            grep -E "^[[:space:]]*${raw_copy}\b" "$NEXUS_FILE" | sed -E "s/\b${raw_copy}\b/${new_copy}/" >> "$OUT_FILE"
        done

        # Extraction of sequences for TARGET copies + immediate renaming
        for i in "${!ACTUAL_TARGET_RAW[@]}"; do
            raw_copy="${ACTUAL_TARGET_RAW[$i]}"
            new_copy="${ACTUAL_TARGET_NEW[$i]}"
            
            grep -E "^[[:space:]]*${raw_copy}\b" "$NEXUS_FILE" | sed -E "s/\b${raw_copy}\b/${new_copy}/" >> "$OUT_FILE"
        done

        echo " ;" >> "$OUT_FILE"
        echo "END;" >> "$OUT_FILE"

        echo "Created file: $OUT_FILE (ntax=$TOTAL_NTAX)"

    done

done

echo "------------------------------------------------------------"
echo "Done. Outputs in file: '$OUTPUT_DIR'."