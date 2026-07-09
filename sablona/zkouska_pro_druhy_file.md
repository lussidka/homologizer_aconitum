2. the second snakefile


postupne se vyberou vzorky z tabulky a pouziji se po jednom k vygenerovani homologizer scriptu - kazdy vzorek bude mit svoji homologizer analyzu - a udela se homologizer analyza - tahle analyza bude mit nejakou output - a s temihle outputy vsechno se to da do Rscriptu - zten se nemusi jet cely, staci ze se projee jen do faze kde se vygeneruje tabulka se spravnym phasingem a ten spravny phasing vzorku se zapíše do tabulky 

vzorovy vypracovany script pro homologizer analyzu pro vzorek n_PPSK4_177: scripts\Aconitum_plus_n_PPSK4_177.Rev
vzor jak vypada jeden z vystupu homologizer analyzy, ktery se doplnuje do rscriptu: scripts\output\homologizer_map.tree
vzor jak musi vypadat .csv soubor, ktery se doplnuje do rscriptu pro vzorek n_PPSK4_177: scripts\data\Aconitum_plus_n_PPSK4_177.csv
vzorove vypracovany rscript: scripts\Aconitum_plot_phase.R

pri generovani scriptu pro homologizer scriptu prdel jim nazvy jako je "homologizer_n_PPSK4_177", kde n_PPSK4_177 replace with {sample}

a oak tuhle polovinu da do jednoho snakefileu.




druhy snakefile se bude poustet az pote co bude ten prvni 100% hotovy - sprvany phasing kazdeho vzorku se zapise do stejne tabulky aby finalnim oututem snakefilu byla jedna tabulka, kde budou zapsany veschyn oprimalni phasing moznosti, které se zjistili pomoci Rscriptu









## description of the workflow

Workflow overview

Rule 1
Input:
    vstupni_obsah_zkouska.csv
    EIF3E_test.nex
    RPB2_test.nex

Output:
    EIF3E_{sample}.nex
    RPB2_{sample}.nex

Description:
    Generate sample-specific NEX files.

so the algorithm is:
    For every sample - generate NEX - generate Rev script for ploidy 1 - run RevBayes - save log - extract likelihood - repeat three times - calculate mean - repeat for next ploidy - compare means - append summary table










    
1. the first snakefile
koukne se do tabulky a na zaklade tabulky se podiva pro jaky vzorek bude generovat nasledujici scripty. 

tabulka kterou bude vkladat uzivatel jako input pro celou analyzu (seznam vzorku tvorici pevne dane jadro + vzorky ktere budou postupne prochazet pipeline analyzou): scripts\data\vtupni_obsah_zkouska.csv

informace pro tabulku - u kazdeho vzorku je napsano jeho jmeno, kolik ruznych sekvenci jsme ziskali pro genovy usek RPB2, kolik ruznych sekvenci jsem ziskali pro usek EIF3E, pote kolik celkove fazi jednotlive useky maji a pote jakou ploidii by jednotlive vzorky meli mit. Ve vzorove tabulce je uvedeno pevne dane jadro pro vsechyn analyzy (to jsou vzorky: n_VJJS2_011;lyc_HHA1_072;n_BHA6_068;n_DSO2_114;var_BOB2_057;deg_UMA2_112) plus dalsi vzorek. Do budoucna se v teto tabulce bude nacházet až 170 ruznych dalsich vzorku, ktere by se meli jeden po druhem zpracovat. 

vezme zasobni nex a vytvori nex pro analyzu toho vzorku - podle vzoru 

zasobni nex pro gen EIF3E: scripts\data\EIF3E_test.nex
zasobni nex pro gen RPB2: scripts\data\RPB2_test.nex

vzorovy nex pro kazdy vzork (soucasti jsou sekvence pevne daneho jadra + vzorek) pro gen EIF3E: scripts\data\EIF3E_tip-test-A.nex
vzorovy nex pro kazdy vzork (soucasti jsou sekvence pevne daneho jadra + vzorek) pro gen RPB2: scripts\data\RPB2_tip-test-A.nex


vezme vytvoreny nex a tabulku a na základě ty tabulky se podiva na vzorek který je tam navic hned po tech core vzorcich - u tohohle vzorku se podiva co tam je napsano za ploidii a vytvori na zaklade toho cisla nekolik scriptu pro ruzny stepping stone analyzy. Pokud tam je napsano 2 - vytvori script pro 1 ploidii script pro 2 ploidie, pokud tam bude napsano 3, vytvori script pro 1 ploidii, 2 ploidie a 3 ploidie. 

pri genrovani jednotlivych steppingstone scriptu vytvor pro ne nazvy jako je "stepping_stone_n_PPSK4_177_1" , kde n_PPSK4_177 replace with {sample} a 1 na konci replace with {tested_ploidy}

kazdy rev bayes script uprav pomoci navodu: homologizer_navod.md
a vzorech: 
    vzorovy vypracovany script pro stepping stone analyzu vzorku n_PPSK4_177 pro statisticke zhodnoceni 1-ploidie: scripts\Aconitum_tip-test-fix-A-1.Rev
    vzorovy vypracovany script pro stepping stone analyzu vzorku n_PPSK4_177 pro statisticke zhodnoceni 2-ploidie: scripts\Aconitum_tip-test-fix-A-2.Rev


 - pak ty analyzy spusti a cely ten jejich prubeh, který se vypisuje do terminálu zaznamaneá do txt fileu
 
 vzor jak vypadá výsledek stepping stone analýzy:
vzor jak vyada zaznamenany outpur ze stepping stone analyzy vzorku n_PPSK4_177 pro statisticke zhodnoceni 1-ploidie: scripts\output\stepping_stone_n_PPSK4_177_1.txt
vzor jak vyada zaznamenany outpur ze stepping stone analyzy vzorku n_PPSK4_177 pro statisticke zhodnoceni 2-ploidie: scripts\output\stepping_stone_n_PPSK4_177_2.txt

z tehle fileu pak vytahne to cislo likelihoodu (radek cislo 64) pro kazdy pocet ploidie udela 3 opakovani (pusti se ten scrit trikrat a pokazde se zaznamena jeho vysledek do .txt. filey a to cislo likelihoodu do tabulku bez toho aniz by se cokoli prepsalo) - pak se vypočte průmer pro vsechny 3 opakovani - ty prumery pak porovan mezi sebou v ramci jednoho vzorku aby se porovnalo jaka ploidie ma jakou statistickou podporu - a to nejvyssi cislo je to co vypise jako finalni vysledek.
K tomuhle finalnimu vysledku se jeste spocita jak moc je tohle nejvyšší číslo průmeru vzdálene od ostatnich prumeru. Pokud je vzdalene o 10 az 15, tak se  da vedet upozornenim, a pokud bude mensi jak 10 tak se da take vedet upozornenim. 

Zároveň se ještě do tabulky prida sloupec s tím, kde bude ke kazdemu vzorku prirazena jeho finalni determinovana ploidie. 

Pomocí Snakemake vytvor snakefile, kde bude vytvořená celá tahle cesta, který je popsaná pro první snakefile "Snakefile_part1"


tohle plati pro oba snakemake soubory

V budoucnu se bude na tento snakefile navazovat. Pro budouci pouziti jde o to, aby se snakefiley pouzivaly na 170 vzorku najednou. chtela bych tedy aby vysledna analyza fungvala tak, ze se pojede nekolik ruznych steppingstone analyz najednou a vsechny ty jejich vysledky se budou symultalne zapisovat do jednoho souboru s temi cisly pro ikelihood bez toho aniž by se výsledky přepisovali navzájem. Zároven chci, aby nazvy vsech scriptu, txt souborů a nex souboru byli jasne popsane, aby se vedelo o jaký vzorek jde a jaka je testovana ploidie.