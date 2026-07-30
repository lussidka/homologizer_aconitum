sablona - šablona pro vytvareni souborů, pracovni verze
zkouska - funkcni scripty

sablona/
Stepping stone analýza - soubory:
    nex soubory: 
        data/EIF3E_tip-test-A.nex
        data/RPB2_tip-test-A.nex
    scripty:
        scripts/Aconitum_tip-test-fix-A-1.Rev
        scripts/Aconitum_tip-test-fix-A-2.Rev

Homologizer - soubory:
    nex soubory: 
        data/EIF3E_test_1.nex
        data/RPB2_test_1.nex
    scripty:
        scripts/Aconitum_test_1_fixed-clamp.Rev
    .csv: (to se vklada pak do RStudia k vykresleni grafu)
        Aconitum_prezentace.csv

Zásobní fasta: data/Eif3E_bez-chimer.fas, data/RPB2_bez-chimer.fas

zkouska/
! zkontolovat - jestli tam jsou vsude doplneny substitucni modely spravne plus spravny script - ten po korekci od autoru

 - homologizer script s degeni - funkcni az do konce
 - mame nejaky zaklad: Aconitum_tip-test_1.Rev - ten se použije jako zafixovany zaklad pro vsechny dalsi analyzy a bude se k nemu stavet
 - pridat tam jeden vzorek navic pro stepping stone - n_PPSK4_177 1vs2 tips - přidáno v Aconitum_tip-test-fix-A-1.Rev a Aconitum_tip-test-fix-A-2.Rev - zjistit optimalni reseni pro prepis scriptu 
 - nechat celý postup stepping stone analýzy zapsat - protoze v tom postupu je to cislo, script vygeneruje spousta souborů jakou ouput, ale nas zajima to cislo hlavne - vysledky pro ilustraci: output/RevBayes_Job_Aconitum_tip-test-fix-A-1.o18151193, RevBayes_Job_Aconitum_tip-test-fix-A-2.o18151195

 - výsledky ze stepping stone a. vybrat a vlozit do tabulky (číslo vždy na stejném radku pocitano odshora) - definovat format tak, aby se s nim dalo dale pracovat 
    nazev vzorku, pocet tips - a k nim vysledky
    vysledky: jednotlive opakovani pro kazdy pocet tips je potreba zprumerovat
    prumery opakovani: porovnat mezi sebou prumery a pokud je tam vetsi rozdil nez 10 tak uznat to nejVYSSI reseni (nejaky upozorneni pokud je to tesne?)
    tohle nejvyssi reseni pak pouzit do vysledneho homologizeru (nejak?)
 - homologizer script s novým vzorkem: uprava aby fungovalo vykresleni

UPRAVA VE R-SCRIPTU = 
    19 genecopymap = read.csv(genecopyFn,header=T,stringsAsFactors=FALSE) -místo TRUE - pak funguje i zobrazeni v R pritom kdyz mame vice vzorku a jeste blank

- pridat sem nex soubory - ale az po prvnim propojeni
    nejdrive propojit - ty nex co mame pro vzorek n_PPSK4_177 , pak scripty pr stepping stone, pak vysledny likelihoody - pak ten vysledek - script pro homologizer (a pak idealne vytahahnout spravny phasing do tabulky, plus vytvorit vlastni generovani nex souboru pro kazdy vzorek)

- nez se spusti agent -  pripsat dalsi vzorek do tabulky aby to probehlo hezky i pro dalsi vzorek 
(
    Snakemake + RevBayes pipeline scaffolding

Structure:
- data/: samples.xlsx (or samples.csv) and input.nex
- scripts/: Bash helpers + placeholder RevBayes scripts
- work/: intermediate inputs
- results/: stepping stone logs, likelihoods, homologizer outputs

Usage:
- Install dependencies: `snakemake`, `revbayes`, `xlsx2csv` (optional)
- Populate `data/samples.xlsx` or `data/samples.csv` and `data/input.nex`
- Run: `snakemake -j <cores>`
)


nex soubory - vyreseno
ss analyza 
tabulka kam se bude ss zapisovat
vypocty uvnitr tabulky
    -> cele do snakefilu