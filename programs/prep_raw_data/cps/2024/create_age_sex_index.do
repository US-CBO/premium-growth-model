/***************************************************************************
* Program:    create_age_sex_index.do
* Purpose:    Process the CPS data for a given year, calculate age- and
*             sex-specific population weights, and integrates Yamamoto age and sex 
*             factors to compute weighted spending indices.
* 
* Inputs:
*   - Raw data file: ${raw_data_path}\raw_data\raw_cps\\`cps_vintage'\\`cps_filename'
*   - Yamamoto index file: $repo_path\prepped_data\yamamoto\yamamoto_index.csv
*
* Outputs:
*   - Processed data file: $repo_path\\prepped_data\\cps\\cps_`cps_vintage'\\age_sex_index_`cps_vintage'.csv
*   - Intermediate data files: $repo_path\\intermediate_data\\cps\\`cps_vintage'\\cps_int.dta
*                              $repo_path\\intermediate_data\\cps\\`cps_vintage'\\male_matrix.dta
*                              $repo_path\\intermediate_data\\cps\\`cps_vintage'\\female_matrix.dta
*
* Notes:
*   - The script assumes that the Yamamoto index file is available. This file does not change between vintages.
***************************************************************************/

clear

args cps_vintage cps_filename

quietly infix                ///
  int     year      1-4      ///
  long    serial    5-9      ///
  byte    month     10-11    ///
  double  hwtfinl   12-21    ///
  double  cpsid     22-35    ///
  byte    asecflag  36-36    ///
  byte    hflag     37-37    ///
  double  asecwth   38-48    ///
  byte    pernum    49-50    ///
  double  wtfinl    51-64    ///
  double  cpsidv    65-79    ///
  double  cpsidp    80-93    ///
  double  asecwt    94-104   ///
  byte    age       105-106  ///
  byte    sex       107-107  ///
  byte    phinsur   108-108  ///
  double  hinswt    109-117  ///
  byte    hcovpriv  118-118  ///
  using "${raw_data_path}\raw_data\raw_cps\\`cps_vintage'\\`cps_filename'"

replace hwtfinl  = hwtfinl  / 10000
replace asecwth  = asecwth  / 10000
replace wtfinl   = wtfinl   / 10000
replace asecwt   = asecwt   / 10000

format hwtfinl  %10.4f
format cpsid    %14.0f
format asecwth  %11.4f
format wtfinl   %14.4f
format cpsidv   %15.0f
format cpsidp   %14.0f
format asecwt   %11.4f
format hinswt   %9.0g

label var year     `"Survey year"'
label var serial   `"Household serial number"'
label var month    `"Month"'
label var hwtfinl  `"Household weight, Basic Monthly"'
label var cpsid    `"CPSID, household record"'
label var asecflag `"Flag for ASEC"'
label var hflag    `"Flag for the 3/8 file 2014"'
label var asecwth  `"Annual Social and Economic Supplement Household weight"'
label var pernum   `"Person number in sample unit"'
label var wtfinl   `"Final Basic Weight"'
label var cpsidv   `"Validated Longitudinal Identifier"'
label var cpsidp   `"CPSID, person record"'
label var asecwt   `"Annual Social and Economic Supplement Weight"'
label var age      `"Age"'
label var sex      `"Sex"'
label var phinsur  `"Reported covered by private health insurance last year"'
label var hinswt   `"Summary health insurance weight"'
label var hcovpriv `"Any private insurance (summary)"'

label define month_lbl 01 `"January"'
label define month_lbl 02 `"February"', add
label define month_lbl 03 `"March"', add
label define month_lbl 04 `"April"', add
label define month_lbl 05 `"May"', add
label define month_lbl 06 `"June"', add
label define month_lbl 07 `"July"', add
label define month_lbl 08 `"August"', add
label define month_lbl 09 `"September"', add
label define month_lbl 10 `"October"', add
label define month_lbl 11 `"November"', add
label define month_lbl 12 `"December"', add
label values month month_lbl

label define asecflag_lbl 1 `"ASEC"'
label define asecflag_lbl 2 `"March Basic"', add
label values asecflag asecflag_lbl

label define hflag_lbl 0 `"5/8 file"'
label define hflag_lbl 1 `"3/8 file"', add
label values hflag hflag_lbl

label define age_lbl 00 `"Under 1 year"'
label define age_lbl 01 `"1"', add
label define age_lbl 02 `"2"', add
label define age_lbl 03 `"3"', add
label define age_lbl 04 `"4"', add
label define age_lbl 05 `"5"', add
label define age_lbl 06 `"6"', add
label define age_lbl 07 `"7"', add
label define age_lbl 08 `"8"', add
label define age_lbl 09 `"9"', add
label define age_lbl 10 `"10"', add
label define age_lbl 11 `"11"', add
label define age_lbl 12 `"12"', add
label define age_lbl 13 `"13"', add
label define age_lbl 14 `"14"', add
label define age_lbl 15 `"15"', add
label define age_lbl 16 `"16"', add
label define age_lbl 17 `"17"', add
label define age_lbl 18 `"18"', add
label define age_lbl 19 `"19"', add
label define age_lbl 20 `"20"', add
label define age_lbl 21 `"21"', add
label define age_lbl 22 `"22"', add
label define age_lbl 23 `"23"', add
label define age_lbl 24 `"24"', add
label define age_lbl 25 `"25"', add
label define age_lbl 26 `"26"', add
label define age_lbl 27 `"27"', add
label define age_lbl 28 `"28"', add
label define age_lbl 29 `"29"', add
label define age_lbl 30 `"30"', add
label define age_lbl 31 `"31"', add
label define age_lbl 32 `"32"', add
label define age_lbl 33 `"33"', add
label define age_lbl 34 `"34"', add
label define age_lbl 35 `"35"', add
label define age_lbl 36 `"36"', add
label define age_lbl 37 `"37"', add
label define age_lbl 38 `"38"', add
label define age_lbl 39 `"39"', add
label define age_lbl 40 `"40"', add
label define age_lbl 41 `"41"', add
label define age_lbl 42 `"42"', add
label define age_lbl 43 `"43"', add
label define age_lbl 44 `"44"', add
label define age_lbl 45 `"45"', add
label define age_lbl 46 `"46"', add
label define age_lbl 47 `"47"', add
label define age_lbl 48 `"48"', add
label define age_lbl 49 `"49"', add
label define age_lbl 50 `"50"', add
label define age_lbl 51 `"51"', add
label define age_lbl 52 `"52"', add
label define age_lbl 53 `"53"', add
label define age_lbl 54 `"54"', add
label define age_lbl 55 `"55"', add
label define age_lbl 56 `"56"', add
label define age_lbl 57 `"57"', add
label define age_lbl 58 `"58"', add
label define age_lbl 59 `"59"', add
label define age_lbl 60 `"60"', add
label define age_lbl 61 `"61"', add
label define age_lbl 62 `"62"', add
label define age_lbl 63 `"63"', add
label define age_lbl 64 `"64"', add
label define age_lbl 65 `"65"', add
label define age_lbl 66 `"66"', add
label define age_lbl 67 `"67"', add
label define age_lbl 68 `"68"', add
label define age_lbl 69 `"69"', add
label define age_lbl 70 `"70"', add
label define age_lbl 71 `"71"', add
label define age_lbl 72 `"72"', add
label define age_lbl 73 `"73"', add
label define age_lbl 74 `"74"', add
label define age_lbl 75 `"75"', add
label define age_lbl 76 `"76"', add
label define age_lbl 77 `"77"', add
label define age_lbl 78 `"78"', add
label define age_lbl 79 `"79"', add
label define age_lbl 80 `"80"', add
label define age_lbl 81 `"81"', add
label define age_lbl 82 `"82"', add
label define age_lbl 83 `"83"', add
label define age_lbl 84 `"84"', add
label define age_lbl 85 `"85"', add
label define age_lbl 86 `"86"', add
label define age_lbl 87 `"87"', add
label define age_lbl 88 `"88"', add
label define age_lbl 89 `"89"', add
label define age_lbl 90 `"90 (90+, 1988-2002)"', add
label define age_lbl 91 `"91"', add
label define age_lbl 92 `"92"', add
label define age_lbl 93 `"93"', add
label define age_lbl 94 `"94"', add
label define age_lbl 95 `"95"', add
label define age_lbl 96 `"96"', add
label define age_lbl 97 `"97"', add
label define age_lbl 98 `"98"', add
label define age_lbl 99 `"99+"', add
label values age age_lbl

label define sex_lbl 1 `"Male"'
label define sex_lbl 2 `"Female"', add
label define sex_lbl 9 `"NIU"', add
label values sex sex_lbl

label define phinsur_lbl 0 `"NIU"'
label define phinsur_lbl 1 `"No"', add
label define phinsur_lbl 2 `"Yes"', add
label values phinsur phinsur_lbl

label define hcovpriv_lbl 1 `"Not covered"'
label define hcovpriv_lbl 2 `"Covered"', add
label values hcovpriv hcovpriv_lbl


/* Top Section - Assigning Weights */
local weight1 "hinswt"
local weight2 "asecwt"

/* Filter to keep only privately insured individuals */
keep if (hcovpriv == 2 & year < 2014) | (phinsur == 2 & year >= 2014)

/* Initialize demographic category variables */
gen demcat1 = .
gen demcat2 = .

/* Split into male and female categories and assign ages */
forval a = 0/64 {
    foreach s in 1 2 {
        replace demcat`s' = `a' if age == `a' & sex == `s'
    }
}
  

save "$repo_path\\intermediate_data\\cps\\`cps_vintage'\\cps_int.dta", replace 

use "$repo_path\\intermediate_data\\cps\\`cps_vintage'\cps_int.dta"
/* Matrix setup for male weights */
mat define male = J((`cps_vintage' - 1987), 66, .)


forval yr = 1988/2013 {
    qui sum `weight1' if year == `yr' & age >= 0 & age <= 64
    local yeartot = r(sum)
    mat male[`yr' - 1987, 1] = `yr'
    forval a = 0/64 {
        qui sum `weight1' if year == `yr' & demcat1 == `a'
        mat male[`yr' - 1987, `a' + 2] = r(sum) / `yeartot'
    }
}

forval yr = 2014/`cps_vintage' {
    qui sum `weight2' if year == `yr' & age >= 0 & age <= 64
    local yeartot = r(sum)
    mat male[`yr' - 1987, 1] = `yr'
    forval a = 0/64 {
        qui sum `weight2' if year == `yr' & demcat1 == `a'
        mat male[`yr' - 1987, `a' + 2] = r(sum) / `yeartot'
    }
}


clear
/* Save male weights to a temporary file */
svmat male
rename male1 year
forval i = 2/66 {
    local age = `i' - 2
    rename male`i' male_`age'
}
drop if year == .
reshape long male_, i(year) j(age)
rename male_ male_popwgt

save "$repo_path\\intermediate_data\\cps\\`cps_vintage'\\male_matrix.dta", replace


use "$repo_path\\intermediate_data\\cps\\`cps_vintage'\\cps_int.dta", clear
/* Repeat the process for female weights */
mat define female = J((`cps_vintage' - 1987), 66, .)

forval yr = 1988/2013 {
    qui sum `weight1' if year == `yr' & age >= 0 & age <= 64
    local yeartot = r(sum)
    mat female[`yr' - 1987, 1] = `yr'
    forval a = 0/64 {
        qui sum `weight1' if year == `yr' & demcat2 == `a'
        mat female[`yr' - 1987, `a' + 2] = r(sum) / `yeartot'
    }
}

forval yr = 2014/`cps_vintage' {
    qui sum `weight2' if year == `yr' & age >= 0 & age <= 64
    local yeartot = r(sum)
    mat female[`yr' - 1987, 1] = `yr'
    forval a = 0/64 {
        qui sum `weight2' if year == `yr' & demcat2 == `a'
        mat female[`yr' - 1987, `a' + 2] = r(sum) / `yeartot'
    }
}

/* Save female weights to a temporary file */
clear
svmat female
rename female1 year
forval i = 2/66 {
    local age = `i' - 2
    rename female`i' female_`age'
}
drop if year == .
reshape long female_, i(year) j(age)
rename female_ female_popwgt

save "$repo_path\\intermediate_data\\cps\\`cps_vintage'\female_matrix.dta", replace

/* Combine male and female weight matrices */
merge m:m year age using "$repo_path\\intermediate_data\\cps\\`cps_vintage'\\male_matrix.dta", keep(match) nogen
recast double female_popwgt male_popwgt
save "$repo_path\\intermediate_data\\cps\\`cps_vintage'\\male_female_matrix.dta", replace
use "$repo_path\\intermediate_data\\cps\\`cps_vintage'\\male_female_matrix.dta"
export delimited using "$repo_path\\prepped_data\\cps\\cps_`cps_vintage'\\male_female_matrix.csv", replace

clear
/* Import Yamamoto age and sex factors and merge with population weights */
import delimited using "$repo_path\prepped_data\yamamoto\yamamoto_index.csv"
merge m:m age using "$repo_path\\intermediate_data\\cps\\`cps_vintage'\\male_female_matrix.dta", keep(match) nogen
sort year age
recast double femfact malefact

/* Calculate age-sex weighted spending index */
gen weighted_female_spending = female_popwgt * femfact
gen weighted_male_spending = male_popwgt * malefact
gen ageyear_spendindex = weighted_female_spending + weighted_male_spending

/* Aggregate Yamamoto weights by year */
collapse (sum) yamamoto_index_`cps_vintage' = ageyear_spendindex, by(year)


/* Add rows for previous years (1987 to 1984) by duplicating data from existing years */

/* Step 1: Add a row for 1987 */
expand 2 if year == 1988   // Duplicate the row for 1988
replace year = 1987 in l   // Set the newly created observation to 1987

/* Step 2: Add a row for 1986 */
expand 2 if year == 1987   // Duplicate the row for 1987
replace year = 1986 in l   // Set the newly created observation to 1986

/* Step 3: Add a row for 1985 */
expand 2 if year == 1986   // Duplicate the row for 1986
replace year = 1985 in l   // Set the newly created observation to 1985

/* Step 4: Add a row for 1984 */
expand 2 if year == 1985   // Duplicate the row for 1985
replace year = 1984 in l   // Set the newly created observation to 1984

/* Step 5: Sort the dataset to ensure observations are in chronological order */
sort year


/* Copy 1988 Yamamoto weight to 1985-1987 */
preserve
keep if year == 1988
local hardcode = yamamoto_index_`cps_vintage'
restore
replace yamamoto_index_`cps_vintage' = `hardcode' if inrange(year, 1985, 1987)

forval i = 1985/1987 {
    replace yamamoto_index_`cps_vintage' = `hardcode' if year == `i'
}

/* Normalize Yamamoto indices to the final year */
sort year
preserve
gen n = _n
keep if n == _N
local normalize = yamamoto_index_`cps_vintage'
restore
gen real_yamamoto_`cps_vintage' = yamamoto_index_`cps_vintage' / `normalize'

/* Adjust year to represent calendar year */
replace year = year - 1

/* Export the final CSV */
export delimited using "$repo_path\\prepped_data\\cps\\cps_`cps_vintage'\\age_sex_index_`cps_vintage'.csv", replace
