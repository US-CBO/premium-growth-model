/***************************************************************************
* Program:    merge.do
* Purpose:    Merge together the prepped data sources
*
* Inputs:
*   - MAD forecast: $repo_path\prepped_data\mad\\`mad_vintage'\macro_forecast
*   - MAD forecast - Previous: $repo_path\prepped_data\mad\\`mad_vintage_prev'\macro_forecast
*   - Adjusted NHEA premiums: $repo_path\prepped_data\phi_premiums\\`nhe_vintage'\phi_premiums
*   - Adjusted NHEA premiums - Previous: $repo_path\prepped_data\phi_premiums\\`nhe_vintage_prev'\phi_premiums
*   - KFF EHBS: $repo_path\prepped_data\kff\\`kff_vintage'\kff
*   - KFF EHBS - Previous: $repo_path\prepped_data\kff\\`kff_vintage_prev'\kff
*   - BLS: $repo_path\prepped_data\bls\\`bls_vintage'\bls
*   - BLS - Previous: $repo_path\prepped_data\bls\\`bls_vintage_prev'\bls
*
* Outputs:
*   - Processed data file: $repo_path\prepped_data\merge_baseline\`baseline_vintage'\merge_baseline.csv
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The parameters are passed as arguments to this script.
***************************************************************************/

set more off
clear


* Define data vintages
args baseline_vintage ///
	phi_vintage phi_vintage_prev /// 
	mad_vintage mad_vintage_prev ///
	kff_vintage kff_vintage_prev ///
	bls_vintage bls_vintage_prev ///
	baseline_lastyear

* Define a temporary dataset to save the data
tempfile merge_baseline
	
/* ~~~~~ Merge together the prepped data sources: NHEA, HIT, macro forecast, KFF, and BLS */

/* ~~~ Adjusted private health insurance premiums based on NHE data ~~~ */

* Current vintage 
import delimited using "$repo_path\prepped_data\phi_premiums\\`phi_vintage'\phi_premiums", clear 
save `merge_baseline', replace

* Previous vintage
import delimited using "$repo_path\prepped_data\phi_premiums\\`phi_vintage_prev'\phi_premiums", clear 
merge 1:1 year using `merge_baseline', nogen assert(using match)
save `merge_baseline', replace

/* ~~~ Macro forecast ~~~ */
import delimited using "$repo_path\prepped_data\mad\\`mad_vintage'\macro_forecast", clear
keep if year >= 1987 & year <= `baseline_lastyear' & year != .
merge 1:1 year using `merge_baseline', nogen keep(master match)
save `merge_baseline', replace 

import delimited using "$repo_path\prepped_data\mad\\`mad_vintage_prev'\macro_forecast", clear
keep if year >= 1987 & year <= `baseline_lastyear' & year != .
merge 1:1 year using `merge_baseline', nogen keep(master match)
save `merge_baseline', replace 

/* ~~~ Other measures of premiums growth ~~~ */
import delimited using "$repo_path\prepped_data\kff\\`kff_vintage'\kff", clear
merge 1:1 year using `merge_baseline', nogen
rename lndiff_prem_kff_single lndiff_prem_kff_single_`kff_vintage'
rename lndiff_prem_kff_family lndiff_prem_kff_family_`kff_vintage'
save `merge_baseline', replace

import delimited using "$repo_path\prepped_data\kff\\`kff_vintage_prev'\kff", clear
merge 1:1 year using `merge_baseline', nogen
rename lndiff_prem_kff_single lndiff_prem_kff_single_`kff_vintage_prev'
rename lndiff_prem_kff_family lndiff_prem_kff_family_`kff_vintage_prev'
save `merge_baseline', replace

import delimited using "$repo_path\prepped_data\bls\\`bls_vintage'\bls", clear
merge 1:1 year using `merge_baseline', nogen
rename lndiff_prem_bls lndiff_prem_bls_`bls_vintage'
save `merge_baseline', replace

import delimited using "$repo_path\prepped_data\bls\\`bls_vintage_prev'\bls", clear
merge 1:1 year using `merge_baseline', nogen
rename lndiff_prem_bls lndiff_prem_bls_`bls_vintage_prev'
save `merge_baseline', replace

*RT: Do not need cpiumed_
order year prem_* pchange_prem_* ///
	gdp_* pop_* pc_* pcmed_* inc_* ///
	lndiff_prem_bls_* lndiff_prem_kff_*
save `merge_baseline', replace

* Save the final merged dataset.
export delimited using "$repo_path\prepped_data\merge_baseline\baseline_`baseline_vintage'\merge_baseline.csv", replace
