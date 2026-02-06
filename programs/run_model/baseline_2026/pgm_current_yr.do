/***************************************************************************
* Program:    pgm_current_yr.do
* Purpose:    Generate near-term forecasts for premium growth using 
*             baseline data, BLS data, and KFF data for specified vintages. 
*             Outputs the forecasted premium levels and growth rates.
* 
* Inputs:
*   - Baseline data file: $repo_path\prepped_data\merge_baseline\baseline_`baseline_vintage'\merge_baseline`
*
* Outputs:
*   - Processed data file with near-term forecasts: $repo_path\output\baseline_`baseline_vintage'\pgm_current_yr_`baseline_vintage'.csv`
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The parameters are passed as arguments to this script.
*   - For the next baseline, the "current baseline's version" will be moved to
*     the "previous baseline's version" section. 
***************************************************************************/

clear

* Define data vintages
args baseline_vintage ///
	kff_vintage kff_vintage_prev ///
	bls_vintage bls_vintage_prev ///
	phi_vintage phi_vintage_prev ///
	current_yr current_yr_prev

* Import the source data
import delimited using "$repo_path\prepped_data\merge_baseline\baseline_`baseline_vintage'\merge_baseline", clear 
keep year prem* pchange* lndiff_prem_kff* lndiff_prem_bls*
tsset year 

/* ~~~~~ Previous baseline's version ~~~~~ */

* Generate log difference approximation to growth rates 
gen lndiff_prem_`phi_vintage_prev' = ln(prem_`phi_vintage_prev') - ln(L.prem_`phi_vintage_prev')
gen lndiff_prem_demo_`phi_vintage_prev' = ln(prem_demo_`phi_vintage_prev') - ln(L.prem_demo_`phi_vintage_prev')

/* ~ Without demographic adjustment ~ */
* Estimate a regression model for NHEA premium growth in terms of 
* BLS and KFF premium growth
regress lndiff_prem_`phi_vintage_prev' lndiff_prem_bls_`bls_vintage_prev' lndiff_prem_kff_single_`kff_vintage_prev' lndiff_prem_kff_family_`kff_vintage_prev'
predict prediction, xb

* Generate the near term forecast, which is equal to the predicted values in the
* years when NHEA data are not yet available but BLS and KFF data are
replace lndiff_prem_`phi_vintage_prev' = prediction if year >= `current_yr_prev'
replace prem_`phi_vintage_prev' = L.prem_`phi_vintage_prev' * exp(prediction) if year >= `current_yr_prev'
replace pchange_prem_`phi_vintage_prev' = prem_`phi_vintage_prev' / L.prem_`phi_vintage_prev' - 1

/* ~ With demographic adjustment ~ */
* Estimate a regression model for NHEA premium growth in terms of 
* BLS and KFF premium growth
regress lndiff_prem_demo_`phi_vintage_prev' lndiff_prem_bls_`bls_vintage_prev' lndiff_prem_kff_single_`kff_vintage_prev' lndiff_prem_kff_family_`kff_vintage_prev'
predict prediction_demo, xb

* Generate the near term forecast, which is equal to the predicted values in the
* years when NHEA data are not yet available but BLS and KFF data are
replace lndiff_prem_demo_`phi_vintage_prev' = prediction_demo if year >= `current_yr_prev'
replace prem_demo_`phi_vintage_prev' = L.prem_demo_`phi_vintage_prev' * exp(prediction_demo) if year >= `current_yr_prev'
replace pchange_prem_demo_`phi_vintage_prev' = prem_demo_`phi_vintage_prev' / L.prem_demo_`phi_vintage_prev' - 1

drop prediction prediction_demo

/* ~~~~~ Current baseline's version ~~~~~ */

* Generate log difference approximation to growth rates 
gen lndiff_prem_`phi_vintage' = ln(prem_`phi_vintage') - ln(L.prem_`phi_vintage')
gen lndiff_prem_demo_`phi_vintage' = ln(prem_demo_`phi_vintage') - ln(L.prem_demo_`phi_vintage')

/* ~ Without demographic adjustment ~ */
* Estimate a regression model for NHEA premium growth in terms of 
* BLS and KFF premium growth
regress lndiff_prem_`phi_vintage' lndiff_prem_bls_`bls_vintage' lndiff_prem_kff_single_`kff_vintage' lndiff_prem_kff_family_`kff_vintage'
predict prediction, xb

* Generate the near term forecast, which is equal to the predicted values in the
* years when NHEA data are not yet available but BLS and KFF data are
replace lndiff_prem_`phi_vintage' = prediction if year >= `current_yr'
replace prem_`phi_vintage' = L.prem_`phi_vintage' * exp(prediction) if year >= `current_yr'
replace pchange_prem_`phi_vintage' = prem_`phi_vintage' / L.prem_`phi_vintage' - 1

/* ~ With demographic adjustment ~ */
* Estimate a regression model for NHEA premium growth in terms of 
* BLS and KFF premium growth
regress lndiff_prem_demo_`phi_vintage' lndiff_prem_bls_`bls_vintage' lndiff_prem_kff_single_`kff_vintage' lndiff_prem_kff_family_`kff_vintage'
predict prediction_demo, xb

* Generate the near term forecast, which is equal to the predicted values in the
* years when NHEA data are not yet available but BLS and KFF data are
replace lndiff_prem_demo_`phi_vintage' = prediction_demo if year >= `current_yr'
replace prem_demo_`phi_vintage' = L.prem_demo_`phi_vintage' * exp(prediction_demo) if year >= `current_yr'
replace pchange_prem_demo_`phi_vintage' = prem_demo_`phi_vintage' / L.prem_demo_`phi_vintage' - 1

/* ~~~~~ Export the data ~~~~~ */
rename (prem*# pchange*#) (prem*current_# pchange*current_#)
keep year prem_* pchange_*
drop if pchange_prem_demo_current_`phi_vintage' == .
export delimited using "$repo_path\output\baseline_`baseline_vintage'\pgm_current_yr_`baseline_vintage'.csv", replace
