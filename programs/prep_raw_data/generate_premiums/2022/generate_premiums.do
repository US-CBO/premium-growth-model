/***************************************************************************
* Program:    generate_premiums.do
* Purpose:    Generate and adjust private health insurance premiums based on
*             NHE data, HIT data, and the Yamamoto index. Adjust for ACA and
*             COVID era effects.
*
* Prerequisites:
*   - The NHEA, MAD, and CPS data must be processed and available in the repository.
*
* Inputs:
*   - NHEA data: $repo_path\prepped_data\nhe\\`nhe_vintage'\nhe
*   - HIT data: $repo_path\prepped_data\hit_premiums\HIT_Premiums
*   - Macro forecast: $repo_path\prepped_data\mad\\`mad_vintage'\macro_forecast
*   - Demographic index: $repo_path\prepped_data\cps\cps_`cps_vintage'\age_sex_index_`cps_vintage'
*
* Outputs:
*   - Processed data file: $repo_path\prepped_data\phi_premiums\\`nhe_vintage'\phi_premiums.csv
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The vintage year is passed as an argument to this script.
***************************************************************************/

clear

args nhe_vintage mad_vintage cps_vintage

* Define a temporary dataset to save the data
tempfile premiums
	
/* ~~~~~ Merge together the prepped data sources: NHEA, HIT, macro forecast, & Yamamoto index*/

* NHE data
import delimited using "$repo_path\prepped_data\nhe\\`nhe_vintage'\nhe", clear 
save `premiums', replace

* HIT data
import delimited using "$repo_path\prepped_data\hit_premiums\HIT_Premiums", clear
keep year hit_premiums
keep if year >= 2014
merge 1:1 year using `premiums', nogen keep(using match) assert(using match)
replace hit_premiums = 0 if hit_premiums == . /* Replace missing HIT values with zero. */
save `premiums', replace

* Macro forecast
import delimited using "$repo_path\prepped_data\mad\\`mad_vintage'\macro_forecast", clear
merge 1:1 year using `premiums', nogen keep(match) assert(master match)
save `premiums', replace 

* Yamamoto index
import delimited using "$repo_path\prepped_data\cps\cps_`cps_vintage'\age_sex_index_`cps_vintage'", clear
merge 1:1 year using `premiums', nogen keep(match) assert(master match)
save `premiums', replace

* Set as time series
tsset year

/* ~~~~~ Extrapolate Medigap expenditure per capita back to 1987 ~~~~~*/

* Store CPIUMED and  Medigap spending per capita in 2001
sum cpiumed_cy_`mad_vintage' if year == 2001
scalar cpiumed_2001 = r(mean)
sum per_cap_medigap_exp_`nhe_vintage' if year == 2001
scalar per_cap_medigap_exp_2001 = r(mean)

* Extrapolate backwards using the growth in CPIUMED
replace per_cap_medigap_exp_`nhe_vintage' = (cpiumed_cy_`mad_vintage' / cpiumed_2001) * per_cap_medigap_exp_2001 if year < 2001
replace medigap_exp_`nhe_vintage' = (medigap_enrollment_`nhe_vintage' * per_cap_medigap_exp_`nhe_vintage') / 1000 if year < 2001

/* ~~~~~ Adjust revenues and enrollment ~~~~~ */
gen double adj_total_phi_exp_`nhe_vintage' = total_phi_exp_`nhe_vintage'
gen double adj_total_phi_enrollment_`nhe_vintage' = total_phi_enrollment_`nhe_vintage'

* Adjust revenues: Remove Medigap expenditures
replace adj_total_phi_exp_`nhe_vintage' = ///
	adj_total_phi_exp_`nhe_vintage' - medigap_exp_`nhe_vintage'
replace adj_total_phi_enrollment_`nhe_vintage' = ///
	total_phi_enrollment_`nhe_vintage' - medigap_enrollment_`nhe_vintage'
	
* Adjust revenues: Remove health insurance taxes
replace adj_total_phi_exp_`nhe_vintage' = ///
	adj_total_phi_exp_`nhe_vintage' - hit_premiums

/* ~~~~~ Generate and adjust premiums ~~~~~ */

* Generate premiums and the a version that holds the age / sex composition of the population constant
* At this point, drop the private health insurance (PHI) prefix
gen double prem_`nhe_vintage' = 1000 * adj_total_phi_exp_`nhe_vintage' / adj_total_phi_enrollment_`nhe_vintage'
gen double prem_demo_`nhe_vintage' = prem_`nhe_vintage' / real_yamamoto

* Generate premium growth
gen pchange_prem_`nhe_vintage' = prem_`nhe_vintage' / L.prem_`nhe_vintage' - 1
gen pchange_prem_demo_`nhe_vintage' = prem_demo_`nhe_vintage' / L.prem_demo_`nhe_vintage' - 1

* Adjust premiums: COVID era
replace pchange_prem_`nhe_vintage' = 0.025 if year == 2020								  
replace prem_`nhe_vintage' = prem_`nhe_vintage'[_n-1]*(1+pchange_prem_`nhe_vintage') if year == 2020
replace pchange_prem_`nhe_vintage' =  0.035 if year == 2021
replace prem_`nhe_vintage' = prem_`nhe_vintage'[_n-1]*(1+pchange_prem_`nhe_vintage') if year == 2021
replace pchange_prem_`nhe_vintage' = 0.02 if year == 2022
replace prem_`nhe_vintage' = prem_`nhe_vintage'[_n-1]*(1+pchange_prem_`nhe_vintage') if year == 2022

replace pchange_prem_demo_`nhe_vintage' = 0.025 if year == 2020								  
replace prem_demo_`nhe_vintage' = prem_demo_`nhe_vintage'[_n-1]*(1+pchange_prem_demo_`nhe_vintage') if year == 2020
replace pchange_prem_demo_`nhe_vintage' =  0.035 if year == 2021
replace prem_demo_`nhe_vintage' = prem_demo_`nhe_vintage'[_n-1]*(1+pchange_prem_demo_`nhe_vintage') if year == 2021
replace pchange_prem_demo_`nhe_vintage' = 0.02 if year == 2022
replace prem_demo_`nhe_vintage' = prem_demo_`nhe_vintage'[_n-1]*(1+pchange_prem_demo_`nhe_vintage') if year == 2022

* Adjust premiums: ACA implementation
* 2013's premium growth was a little slower than usual because of ACA effects
* Research suggests that it should be adjusted upward 0.5% to negate this effect
* 2014's premium growth was a little higher than usual because of ACA effects
* Adjust downward 0.5% to negate this effect
replace pchange_prem_`nhe_vintage' = pchange_prem_`nhe_vintage' + .005 if year == 2013
replace prem_`nhe_vintage' = prem_`nhe_vintage'[_n-1]*(1+pchange_prem_`nhe_vintage') if year == 2013
replace pchange_prem_`nhe_vintage' = pchange_prem_`nhe_vintage' - .005 if year == 2014
replace prem_`nhe_vintage' = prem_`nhe_vintage'[_n-1]*(1+pchange_prem_`nhe_vintage') if year == 2014

replace pchange_prem_demo_`nhe_vintage' = pchange_prem_demo_`nhe_vintage' + .005 if year == 2013
replace prem_demo_`nhe_vintage' = prem_demo_`nhe_vintage'[_n-1]*(1+pchange_prem_demo_`nhe_vintage') if year == 2013
replace pchange_prem_demo_`nhe_vintage' = pchange_prem_demo_`nhe_vintage' - .005 if year == 2014
replace prem_demo_`nhe_vintage' = prem_demo_`nhe_vintage'[_n-1]*(1+pchange_prem_demo_`nhe_vintage') if year == 2014

* Save the updated source data.
keep year prem_* pchange_*
save `premiums', replace

* Save the final merged dataset.
export delimited using "$repo_path\prepped_data\phi_premiums\\`nhe_vintage'\phi_premiums", replace
