#!/bin/bash

LOG_DIR="scripts/data/ss_scripts/txt_files"
RESULTS_CSV="scripts/data/ss_scripts/txt_files/results_ss.csv"
FINAL_REPORT="scripts/data/ss_scripts/txt_files/ss_recommended_ploidy.csv"

mkdir -p scripts/data

# vytvoření hlavičky
echo "Sample;Ploidy;Run1;Run2;Run3;Average" > "$RESULTS_CSV"

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

    for run in 1 2 3; do

        TXT_FILE="${LOG_DIR}/${BASE_NAME}_${run}.txt"

        if [ ! -f "$TXT_FILE" ]; then
            echo "  [!] Missing file: $TXT_FILE"
            VAL="-999999.99"

        else
            VAL=$(grep -A1 "Step 50 / 50" "$TXT_FILE" | tail -n1 | tr -d '[:space:]')

            if [ -z "$VAL" ] || [[ "$VAL" == *"*"* ]]; then
                echo "  [!] Could not extract marginal likelihood from $TXT_FILE"
                VAL="-999999.99"
            fi
        fi

        case $run in
            1) ML1=$VAL ;;
            2) ML2=$VAL ;;
            3) ML3=$VAL ;;
        esac

    done

    AVERAGE=$(echo "scale=3; ($ML1+$ML2+$ML3)/3" | bc -l | awk '{printf "%.3f",$0}')

    echo "Average: $AVERAGE"

    echo "${SAMPLE_NAME};${TESTED_PLOIDY};${ML1};${ML2};${ML3};${AVERAGE}" >> "$RESULTS_CSV"

done

echo
echo "Finished."
echo "Results saved in: $RESULTS_CSV"


# ------------------------------------------------------------------------------
# PHASE 2: EVALUATION OF THE BEST PLOIDY AND BAYES FACTOR
# ------------------------------------------------------------------------------

# Set the standard number format (dots instead of commas), so AWK calculates without errors
export LC_ALL=C

awk -F';' '
BEGIN {
    # Print the clean header of the table
    print "Sample;Recommended_Ploidy;Bayes_Factor;Evidence"
}
NR > 1 {
    sample = $1
    ploidy = $2
    mean = $6
    

    if (!(sample in best_score)) {
        best_score[sample] = mean 
        best_ploid[sample] = ploidy
        # The second place does not yet exist, we give it an extremely low value
        second_score[sample] = -999999999.0
        count[sample] = 1
    } else {
        count[sample]++
        # If we find a NEW BEST value (higher marginal likelihood)
        if (mean > best_score[sample]) {
            # The current best score is moved to second place
            second_score[sample] = best_score[sample]
            # New best score is saved
            best_score[sample] = mean
            best_ploid[sample] = ploidy
            
        } else if (mean > second_score[sample]) {
            second_score[sample] = mean
        }
    }
}
END {
    # All samples are printed into the final table
    for (v in best_score) {
        
        if (count[v] > 1) {
            # Calculate BF: Log Marginal Likelihood 1st model - Log Marginal Likelihood 2nd model
            bf = best_score[v] - second_score[v]
            
            # evidence based on Kass & Raftery (1995)
            if (bf > 150)       evidence = "Very_strong"
            else if (bf >= 20)  evidence = "Strong"
            else if (bf >= 3)   evidence = "Positive"
            else if (bf >= 1)   evidence = "Not_worth_more_than_a_bare_mention"
            else                evidence = "Barely_worth_mentioning"
            
            printf "%s;%s;%.3f;%s\n", v, best_ploid[v], bf, evidence
        } else {
            # If only one model was tested, we cannot calculate the difference
            printf "%s;%s;NA;Cannot_compare\n", v, best_ploid[v]
        }
    }
}' "$RESULTS_CSV" > "$FINAL_REPORT"


# ------------------------------------------------------------------------------
# PHASE 3: FINAL CHECK AND WARNINGS FOR THE USER
# ------------------------------------------------------------------------------

echo "=========================================================="
echo " FINAL CHECK OF RELIABILITY (BAYES FACTOR)"
echo "=========================================================="

# Looking for lines with low evidence in our new table
WARNINGS=$(grep -E "Weak|Barely_worth_mentioning" "$FINAL_REPORT")

if [ -n "$WARNINGS" ]; then
    echo " ⚠️  Warning: Following samples have very low evidence!"
    echo " The difference between the best and the second-best ploidy is too small."
    echo " We recommend manually checking these samples, or not making a definitive ploidy call."
    echo ""
    
    # Hezký formátovaný výpis problémových vzorků do terminálu
    while IFS=';' read -r sample ploidy bf evidence; do
        echo "  -> Sample: $sample"
        echo "     Recommended ploidy: $ploidy | Bayes factor: $bf ($evidence)"
        echo "     (Data may not be sufficiently informative for a definitive call.)"
        echo ""
    done <<< "$WARNINGS"
else
    echo " All tested samples have at least 'Positive' (or better) evidence."
fi

echo "=========================================================="
echo "DONE!"
echo "Complete data (all runs): $RESULTS_CSV"
echo "Clean result with Bayes factor: $FINAL_REPORT"
echo "=========================================================="