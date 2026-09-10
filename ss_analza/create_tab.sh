#!/bin/bash

LOG_DIR="scripts/txt_files"
RESULTS_CSV="scripts/txt_files/results_ss.csv"

mkdir -p scripts/txt_files

echo "sample;ploidy;run1;run2;run3;run4;run5;run6;run7;run8;run9;run10" > "$RESULTS_CSV"

for TXT1 in "$LOG_DIR"/*_1.txt; do

    [ -e "$TXT1" ] || continue

    BASE_NAME=$(basename "$TXT1" "_1.txt")

    SAMPLE_NAME=$(echo "$BASE_NAME" | sed 's/^ss_//; s/_[0-9]*tips$//')
    TESTED_PLOIDY=$(echo "$BASE_NAME" | grep -Eo '[0-9]+tips$' | grep -Eo '[0-9]+')

    echo "===================================================="
    echo "Sample: $SAMPLE_NAME | Tested ploidy: $TESTED_PLOIDY"
    echo "===================================================="

    ML1=""
    ML2=""
    ML3=""
    ML4=""
    ML5=""
    ML6=""
    ML7=""
    ML8=""
    ML9=""
    ML10=""

    for run in 1 2 3 4 5 6 7 8 9 10; do

        TXT_FILE="${LOG_DIR}/${BASE_NAME}_${run}.txt"

        if [ ! -f "$TXT_FILE" ]; then
            echo "  [!] Missing file: $TXT_FILE"
            VAL="-999999.99"

        else
            VAL=$(awk '/Step/ && ($2 == $4) { getline; print $1; exit }' "$TXT_FILE" | tr -d '\r\n[:space:]')

            if [ -z "$VAL" ] || [[ "$VAL" == *"*"* ]]; then
                echo "  [!] Could not extract marginal likelihood from $TXT_FILE"
                VAL="-999999.99"
            fi
        fi

        case $run in
            1) ML1=$VAL ;;
            2) ML2=$VAL ;;
            3) ML3=$VAL ;;
            4) ML4=$VAL ;;
            5) ML5=$VAL ;;
            6) ML6=$VAL ;;
            7) ML7=$VAL ;;
            8) ML8=$VAL ;;
            9) ML9=$VAL ;;
            10) ML10=$VAL ;;
        esac

    done

    echo "${SAMPLE_NAME};${TESTED_PLOIDY};${ML1};${ML2};${ML3};${ML4};${ML5};${ML6};${ML7};${ML8};${ML9};${ML10}" >> "$RESULTS_CSV"

done

echo
echo "Finished."
echo "Results saved in: $RESULTS_CSV"