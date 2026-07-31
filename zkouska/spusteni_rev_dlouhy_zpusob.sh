#!/bin/bash

# ===== 1. opakování =====
rb ss_n_BDZKHS_128_3tips.Rev > ss_n_BDZKHS_128_3tips_1.txt &
rb ss_n_BDZKHS_128_4tips.Rev > ss_n_BDZKHS_128_4tips_1.txt &
rb ss_n_PPSK4_177_1tips.Rev > ss_n_PPSK4_177_1tips_1.txt &
rb ss_n_PPSK4_177_2tips.Rev > ss_n_PPSK4_177_2tips_1.txt &
rb ss_n_PPSK4_177_3tips.Rev > ss_n_PPSK4_177_3tips_1.txt &
rb ss_n_PPSK4_177_4tips.Rev > ss_n_PPSK4_177_4tips_1.txt &

wait

# ===== 2. opakování =====
rb ss_n_BDZKHS_128_3tips.Rev > ss_n_BDZKHS_128_3tips_2.txt &
rb ss_n_BDZKHS_128_4tips.Rev > ss_n_BDZKHS_128_4tips_2.txt &
rb ss_n_PPSK4_177_1tips.Rev > ss_n_PPSK4_177_1tips_2.txt &
rb ss_n_PPSK4_177_2tips.Rev > ss_n_PPSK4_177_2tips_2.txt &
rb ss_n_PPSK4_177_3tips.Rev > ss_n_PPSK4_177_3tips_2.txt &
rb ss_n_PPSK4_177_4tips.Rev > ss_n_PPSK4_177_4tips_2.txt &

wait

# ===== 3. opakování =====
rb ss_n_BDZKHS_128_3tips.Rev > ss_n_BDZKHS_128_3tips_3.txt &
rb ss_n_BDZKHS_128_4tips.Rev > ss_n_BDZKHS_128_4tips_3.txt &
rb ss_n_PPSK4_177_1tips.Rev > ss_n_PPSK4_177_1tips_3.txt &
rb ss_n_PPSK4_177_2tips.Rev > ss_n_PPSK4_177_2tips_3.txt &
rb ss_n_PPSK4_177_3tips.Rev > ss_n_PPSK4_177_3tips_3.txt &
rb ss_n_PPSK4_177_4tips.Rev > ss_n_PPSK4_177_4tips_3.txt &

wait

echo "Všechny výpočty dokončeny."