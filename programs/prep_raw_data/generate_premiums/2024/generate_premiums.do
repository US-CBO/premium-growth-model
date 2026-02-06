/***************************************************************************
* Program:    generate_premiums.do
* Purpose:    Generate and adjust private health insurance premiums based on
*             NHE data, HIT data, and the Yamamoto index. Adjust for ACA and
*             COVID era effects.
*
* Prerequisites:
*   - The NHEA and CPS data must be processed and available in the repository.
*
* Inputs:
*   - NHEA data: $repo_path\prepped_data\nhe\\`nhe_vintage'\nhe
*   - HIT data: $repo_path\prepped_data\hit_premiums\HIT_Premiums
*   - Demographic index: $repo_path\prepped_data\cps\cps_`cps_vintage'\age_sex_index_`cps_vintage'
*
* Outputs:
*   - Processed data file: $repo_path\prepped_data\phi_premiums\[nhe_vintage]\phi_premiums.csv`
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The vintage year is passed as an argument to this script.
***************************************************************************/

clear
*RT: Add phi_vintage for the Winter 2024 baseline
args phi_vintage nhe_vintage cps_vintage

* Define a temporary dataset to save the data
tempfile premiums
	
/* ~~~~~ Merge together the prepped data sources: NHEA, HIT, & Yamamoto index*/

* NHE data
import delimited using "$repo_path\prepped_data\nhe\\`nhe_vintage'\nhe", clear 
save `premiums', replace

* HIT data
import delimited using "$repo_path\prepped_data\hit_premiums\HIT_Premiums", clear
merge 1:1 year using `premiums', nogen keep(using match) assert(using match)
replace hit_premiums = 0 if hit_premiums == . /* Replace missing HIT values with zero. */
save `premiums', replace

* Yamamoto index
import delimited using "$repo_path\prepped_data\cps\cps_`cps_vintage'\age_sex_index_`cps_vintage'", clear
merge 1:1 year using `premiums', nogen keep(using match) assert(master match)
save `premiums', replace

* Set as time series
tsset year

/* ~~~~~ Extrapolate Medigap expenditure per capita back to 1987 ~~~~~*/

* Store Medicare and Medigap spending per capita in 2001
sum per_cap_medicare_exp_`nhe_vintage' if year == 2001
scalar per_cap_medicare_exp_2001 = r(mean)
sum per_cap_medigap_exp_`nhe_vintage' if year == 2001
scalar per_cap_medigap_exp_2001 = r(mean)

* Extrapolate backwards using the growth in Medicare spending per capita
replace per_cap_medigap_exp_`nhe_vintage' = (per_cap_medicare_exp_`nhe_vintage' / per_cap_medicare_exp_2001) * per_cap_medigap_exp_2001 if year < 2001
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
*RT: Here we need to use phi_vintage parameter or in the merge we wont see the differences from last baseline

* Generate premiums and the a version that holds the age / sex composition of the population constant
* At this point, drop the private health insurance (PHI) prefix
gen double prem_`phi_vintage' = 1000 * adj_total_phi_exp_`nhe_vintage' / adj_total_phi_enrollment_`nhe_vintage'
gen double prem_demo_`phi_vintage' = prem_`phi_vintage' / real_yamamoto

* Generate premium growth
gen pchange_prem_`phi_vintage' = prem_`phi_vintage' / L.prem_`phi_vintage' - 1
gen pchange_prem_demo_`phi_vintage' = prem_demo_`phi_vintage' / L.prem_demo_`phi_vintage' - 1

* Adjust premiums: ACA implementation
* 2013's premium growth was a little slower than usual because of ACA effects
* Research suggests that it should be adjusted upward 0.5% to negate this effect
* 2014's premium growth was a little higher than usual because of ACA effects
* Adjust downward 0.5% to negate this effect
replace pchange_prem_`phi_vintage' = pchange_prem_`phi_vintage' + .005 if year == 2013
replace pchange_prem_`phi_vintage' = pchange_prem_`phi_vintage' - .005 if year == 2014
replace prem_`phi_vintage' = L.prem_`phi_vintage' * (1+pchange_prem_`phi_vintage') if _n > 1

replace pchange_prem_demo_`phi_vintage' = pchange_prem_demo_`phi_vintage' + .005 if year == 2013
replace pchange_prem_demo_`phi_vintage' = pchange_prem_demo_`phi_vintage' - .005 if year == 2014
replace prem_demo_`phi_vintage' = L.prem_demo_`phi_vintage' * (1+pchange_prem_demo_`phi_vintage') if _n > 1

* Adjust premiums: COVID era
sum prem_`phi_vintage' if inlist(year, 2019, 2021)
replace prem_`phi_vintage' = r(mean) if year == 2020
replace pchange_prem_`phi_vintage' = prem_`phi_vintage' / L.prem_`phi_vintage' - 1

sum prem_demo_`phi_vintage' if inlist(year, 2019, 2021)
replace prem_demo_`phi_vintage' = r(mean) if year == 2020
replace pchange_prem_demo_`phi_vintage' = prem_demo_`phi_vintage' / L.prem_demo_`phi_vintage' - 1

* Save the updated source data.
keep year prem_* pchange_*
save `premiums', replace

* Save the final merged dataset.
*export delimited using "$repo_path\prepped_data\phi_premiums\\`nhe_vintage'\phi_premiums", replace
*RT: For the 2026 Winter Baseline we change this to phi_vintage because NHEA data has not been updated
export delimited using "$repo_path\prepped_data\phi_premiums\\`phi_vintage'\phi_premiums", replace
