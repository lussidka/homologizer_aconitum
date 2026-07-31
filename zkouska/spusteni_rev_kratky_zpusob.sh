#!/bin/bash

files=(
ss_n_BDZKHS_128_3tips
ss_n_BDZKHS_128_4tips
ss_n_PPSK4_177_1tips
ss_n_PPSK4_177_2tips
ss_n_PPSK4_177_3tips
ss_n_PPSK4_177_4tips
)

for run in 1 2 3
do
    echo "Spouštím opakování $run"

    for f in "${files[@]}"
    do
        rb "${f}.Rev" > "${f}_${run}.txt" &
    done

    wait
done

echo "Hotovo!"