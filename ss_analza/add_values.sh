#!/bin/bash

INPUT_CSV="scripts/txt_files/results_ss.csv"
OUTPUT_CSV="scripts/txt_files/results_ss_values.csv"


export LC_ALL=C

awk -F';' '
BEGIN {
    OFS=";"
    MIN_VAL = -999999999.0
}
NR==1 {
    header = $0
    next
}
{
    sample = $1
    ploidy = $2
    run1 = $3
    run2 = $4
    run3 = $5

    sum = 0
    valid_count = 0

    # Control of the validity of individual runs (ignores Error and -999999.99)
    if (run1 !~ /Error/ && run1 != -999999.99 && run1 != "") { sum += run1; valid_count++ }
    if (run2 !~ /Error/ && run2 != -999999.99 && run2 != "") { sum += run2; valid_count++ }
    if (run3 !~ /Error/ && run3 != -999999.99 && run3 != "") { sum += run3; valid_count++ }

    # Calculate average only from valid runs
    if (valid_count > 0) {
        avg = sum / valid_count
        str_avg = sprintf("%.3f", avg)
    } else {
        avg = MIN_VAL
        str_avg = "NA"
    }

    lines[NR] = $0
    avgs[NR] = str_avg
    samples[NR] = sample
    seen_samples[sample] = 1

    # logic for determining the best and second-best ploidy (only for models that did not fail)
    if (valid_count > 0) {
        if (!(sample in valid_models)) {
            best_score[sample] = avg
            best_ploid[sample] = ploidy
            second_score[sample] = MIN_VAL
            valid_models[sample] = 1
        } else {
            valid_models[sample]++
            if (avg > best_score[sample]) {
                second_score[sample] = best_score[sample]
                best_score[sample] = avg
                best_ploid[sample] = ploidy
            } else if (avg > second_score[sample]) {
                second_score[sample] = avg
            }
        }
    }
}
END {
    # final evaluation of Bayes factor and evidence for all samples
    for (v in seen_samples) {
        if (valid_models[v] > 1) {
            bf[v] = best_score[v] - second_score[v]
            
            if (bf[v] > 150)        ev[v] = "Very_strong"
            else if (bf[v] >= 20)   ev[v] = "Strong"
            else if (bf[v] >= 3)    ev[v] = "Positive"
            else if (bf[v] >= 1)    ev[v] = "Not_worth_more_than_a_bare_mention"
            else                    ev[v] = "Barely_worth_mentioning"
            
            out_bf[v] = sprintf("%.3f", bf[v])
            out_ploid[v] = best_ploid[v]
        } else if (valid_models[v] == 1) {
            out_bf[v] = "NA"
            ev[v] = "Cannot_compare"
            out_ploid[v] = best_ploid[v]
        } else {
            out_bf[v] = "NA"
            ev[v] = "Failed"
            out_ploid[v] = "NA"
        }
    }

    print header, "average", "recommended_ploidy", "bayes_factor_between_1stand2nd", "evidence"

    for (i = 2; i <= NR; i++) {
        s = samples[i]
        print lines[i], avgs[i], out_ploid[s], out_bf[s], ev[s]
    }
}' "$INPUT_CSV" > "$OUTPUT_CSV"

echo ""
echo " Expanded table saved to: $OUTPUT_CSV"
echo ""

# ------------------------------------------------------------------------------
# PHASE: FINAL CHECK AND WARNINGS FOR THE USER
# ------------------------------------------------------------------------------

echo "=========================================================="
echo " FINAL CHECK OF RELIABILITY (BAYES FACTOR & RUNS)"
echo "=========================================================="


FAILED_RUNS=$(awk -F';' '
NR > 1 {
    sample = $1
    ploidy = $2
    run1 = $3
    run2 = $4
    run3 = $5
    run4 = $6
    run5 = $7
    run6 = $8
    run7 = $9
    run8 = $10
    run9 = $11
    run10 = $12

    f1 = (run1 ~ /Error/ || run1 == -999999.99 || run1 == "")
    f2 = (run2 ~ /Error/ || run2 == -999999.99 || run2 == "")
    f3 = (run3 ~ /Error/ || run3 == -999999.99 || run3 == "")
    f4 = (run4 ~ /Error/ || run4 == -999999.99 || run4 == "")
    f5 = (run5 ~ /Error/ || run5 == -999999.99 || run5 == "")
    f6 = (run6 ~ /Error/ || run6 == -999999.99 || run6 == "")
    f7 = (run7 ~ /Error/ || run7 == -999999.99 || run7 == "")
    f8 = (run8 ~ /Error/ || run8 == -999999.99 || run8 == "")
    f9 = (run9 ~ /Error/ || run9 == -999999.99 || run9 == "")
    f10 = (run10 ~ /Error/ || run10 == -999999.99 || run10 == "")

    if (f1 || f2 || f3 || f4 || f5 || f6 || f7 || f8 || f9 || f10) {
        msg = "  -> Sample: " sample " (Ploidy: " ploidy ") | Failed replicates:"
        if (f1) msg = msg " Run1"
        if (f2) msg = msg " Run2"
        if (f3) msg = msg " Run3"
        if (f4) msg = msg " Run4"
        if (f5) msg = msg " Run5"
        if (f6) msg = msg " Run6"
        if (f7) msg = msg " Run7"
        if (f8) msg = msg " Run8"
        if (f9) msg = msg " Run9"
        if (f10) msg = msg " Run10"
        print msg
    }
}' "$OUTPUT_CSV")


LOW_EVIDENCE=$(grep -E "Not_worth_more_than_a_bare_mention|Barely_worth_mentioning|Cannot_compare|Failed" "$OUTPUT_CSV" | awk -F';' '!seen[$1]++ {print $1, $(NF-2), $(NF-1), $NF}')

# print warnings for failed runs
if [ -n "$FAILED_RUNS" ]; then
    echo "WARNING: Missing or Failed runs detected!"
    echo " The averages for these models were calculated from fewer replicates (or failed completely)."
    echo ""
    echo "$FAILED_RUNS"
    echo ""
fi

# Only print if there are any samples with low evidence
if [ -n "$LOW_EVIDENCE" ]; then
    echo "WARNING: The following samples have LOW EVIDENCE!"
    echo " The difference between the best and the second-best ploidy is too small."
    echo " We recommend manually checking these samples."
    echo ""
    while read -r sample ploidy bf evidence; do
        echo "  -> Sample: $sample"
        echo "     Recommended ploidy: $ploidy | Bayes factor: $bf ($evidence)"
        echo ""
    done <<< "$LOW_EVIDENCE"
fi

# If there are no failed runs and no low evidence samples, print a success message
if [ -z "$FAILED_RUNS" ] && [ -z "$LOW_EVIDENCE" ]; then
    echo " All runs finished successfully and all samples have at least 'Positive' evidence."
fi

echo "=========================================================="
echo "DONE!"
echo "Combined results and stats in:  $OUTPUT_CSV"
echo "=========================================================="