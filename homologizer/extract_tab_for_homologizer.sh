#!/bin/bash

# Povolí prázdný seznam, pokud žádný soubor neodpovídá masce
shopt -s nullglob
FILES=(*targets.Rev scripts/*targets.Rev)
shopt -u nullglob

if [ ${#FILES[@]} -eq 0 ]; then
    echo "⚠️ Nebyly nalezeny žádné soubory odpovídající vzoru '*targets.Rev'."
    exit 1
fi

echo "Nalezeno ${#FILES[@]} souborů ke zpracování."

for file in "${FILES[@]}"; do
    # Název výstupního CSV podle vstupního souboru (např. h_10_targets.Rev -> h_10_targets.csv)
    output_csv="${file%.Rev}.csv"
    
    echo " -> Zpracovávám: $file -> $output_csv"

    awk '
    BEGIN {
        FS = "\""
    }

    /setHomeologPhase/ {
        subgenome = $4
        if (subgenome != "" && !(subgenome in seen)) {
            seen[subgenome] = 1
            subgenomes[++count] = subgenome
        }
    }

    END {
        print "Sample,Subgenome,RPB,EIF3E"

        for (k = 1; k <= count; k++) {
            subg = subgenomes[k]
            sample = subg
            sub(/_[A-Z0-9]+$/, "", sample)
            print sample "," subg ",,"
        }
    }
    ' "$file" > "$output_csv"

done

echo "Všechny CSV šablony byly úspěšně vygenerovány."