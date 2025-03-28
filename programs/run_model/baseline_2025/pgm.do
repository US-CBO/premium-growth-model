/***************************************************************************
* Program:    pgm.do
* Purpose:    Generate the premium growth forecasts through the end of the 
*             baseline window. Generates the step-by-step forecasts for the
*			  PGM report.
*
* Parameters:
*   - Estimation commands for each model
*   - Estimation start and stop dates for each model
*   - Forecast start and stop dates for each model
* 
* Inputs:
*   - Baseline data file: $repo_path\prepped_data\merge_baseline\baseline_`baseline_vintage'\merge_baseline
*   - Current year forecast file: $repo_path\output\baseline_`baseline_vintage'\pgm_current_yr_`baseline_vintage'.csv
*
* Outputs:
*   - Forecasted premium levels and growth rates in wide and long format: 
*     $repo_path\output\baseline_`baseline_vintage'\pgm_current_yr_`baseline_vintage'.csv
*     $repo_path\output\baseline_`baseline_vintage'\pgm_`baseline_vintage'_long_format.csv
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The parameters are passed as arguments to this script.
*   - The program reproduces the previous baseline's forecast and then
*     incrementally updates the forecast using the current baseline's
*     specification and the most recent data. The six steps are:
*     0. Previous baseline's forecast
*     1. Forecast using previous specification estimated on old data 
*        and new NHE vintage / old MAD vintage for forecasting
*     2. Forecast using previous specification estimated on old data 
*        and new NHE vintage / new MAD vintage for forecasting
*     3. Forecast using previous specification estimated on new data 
*        and new NHE vintage / new MAD vintage for forecasting
*     4. Forecast using new specification estimated on new data 
*        and new NHE vintage / new MAD vintage for forecasting
*     5. Forecast using new specification estimated on new data 
*        and new NHE vintage / new MAD vintage for forecasting
*        and manual adjustments to the near-term forecast
*   - The program also creates the forecast for the series that is not
*	  adjusted for demographics.
*	- The program assumes that pgm_current_yr.do has been run to generate
*	  the current year forecast.
***************************************************************************/

clear

* Define data vintages
args baseline_vintage baseline_vintage_prev ///
	nhe_vintage nhe_vintage_prev ///
	mad_vintage mad_vintage_prev ///
	kff_vintage kff_vintage_prev ///
	bls_vintage bls_vintage_prev

* Define estimate start and stop dates for each model
local estimates1_start 2003
local estimates1_stop 2023
local estimates2_start 2003
local estimates2_stop 2023
local estimates3_start 1999
local estimates3_stop 2023

* Define forecast start and stop dates for each model
local forecast1_start 2024
local forecast1_stop 2034
local forecast2_start 2024
local forecast2_stop 2034
local forecast3_start 2025
local forecast3_stop 2035

* Define the estimation command for each model
local estimates1a_command = "prais pchange_prem_demo lndiff_pdi_3yr L.pchange_prem_demo L2.pchange_prem_demo L3.pchange_prem_demo if year >= `estimates1_start' & year <= `estimates1_stop', ssesearch"
local estimates1b_command = "prais pchange_prem lndiff_pdi_3yr L.pchange_prem L2.pchange_prem L3.pchange_prem if year >= `estimates1_start' & year <= `estimates1_stop', ssesearch"
local estimates2_command  = "prais pchange_prem_demo lndiff_pdi_3yr L.pchange_prem_demo L2.pchange_prem_demo L3.pchange_prem_demo if year >= `estimates2_start' & year <= `estimates2_stop', ssesearch"
local estimates3a_command = "regress lndiff_prem_real_demo L.lndiff_prem_real_demo lndiff_pdi_real_6yr if year >= `estimates3_start' & year <= `estimates3_stop'"
local estimates3b_command = "regress lndiff_prem_real L.lndiff_prem_real lndiff_pdi_real_6yr if year >= `estimates3_start' & year <= `estimates3_stop'"

* Define adjustments
local adjustment_2024 = 0.02
local adjustment_2025 = 0.02

* Display parameters
#delimit ;
di 			 "Parameters for pgm.do" 
	char(10) "~~~~~~~~~~~~~~~~~~~~~" 
	char(10) "~~~ Estimation and forecast start and stop years ~~~" 
	char(10) "Model 1: Previous baseline specification / Previous data" 
	char(10) "Estimation command: `estimates1a_command'" 
	char(10) "Estimation command -- No demographic adjustment: `estimates1b_command'" 
	char(10) "Estimation start year: `estimates1_start'" 
	char(10) "Estimation stop year: `estimates1_stop'" 
	char(10) "Long-term forecast start year: `forecast1_start'" 
	char(10) "Long-term forecast stop year: `forecast1_stop'" 
	char(10) "Model 2: Previous baseline specification / Current data" 
	char(10) "Estimation command: `estimates2_command'" 
	char(10) "Estimation start year: `estimates2_start'" 
	char(10) "Estimation stop year: `estimates2_stop'" 
	char(10) "Long-term forecast start year: `forecast2_start'" 
	char(10) "Long-term forecast stop year: `forecast2_stop'" 
	char(10) "Model 3: Current baseline specification / Current data" 
	char(10) "Estimation command: `estimates3a_command'" 
	char(10) "Estimation command -- No demographic adjustment: `estimates3b_command'" 
	char(10) "Estimation start year: `estimates3_start'" 
	char(10) "Estimation stop year: `estimates3_stop'" 
	char(10) "Long-term forecast start year: `forecast3_start'" 
	char(10) "Long-term forecast stop year: `forecast3_stop'"
	char(10) "~~~ Adjustments ~~~"
	char(10) "Adjustment for 2024: `adjustment_2024'"
	char(10) "Adjustment for 2025: `adjustment_2025'"
;
#delimit cr
	
tempfile pgm
tempfile forecasts

/* ~~~~~ Compile the data ~~~~~ */
* Import the source data
import delimited using "$repo_path\prepped_data\merge_baseline\baseline_`baseline_vintage'\merge_baseline", clear 
save `pgm', replace

* Merge on the current year forecast
import delimited using "$repo_path\output\baseline_`baseline_vintage'\pgm_current_yr_`baseline_vintage'.csv", clear
merge 1:1 year using `pgm', nogen
sort year
* drop kff_* bls_*

* Declare the data as a time series dataset
tsset year

/* ~~~~~ Estimate PGM's ~~~~~ */
* 1. Previous baseline specification on previous data
*	a. With demographic adjustment
*	b. Without demographic adjustment
* 2. Previous baseline specification on current data
* 3. Current baseline specification on current data
*	a. With demographic adjustment
*	b. Without demographic adjustment

/* Generate the variables necessary to estimate the models */

* 3-year nominal PDI per capita growth rate
gen lndiff_pdi_3yr_`mad_vintage_prev' = ln(inc_cy_`mad_vintage_prev' / pop_cy_`mad_vintage_prev') ///
	- ln(L3.inc_cy_`mad_vintage_prev' / L3.pop_cy_`mad_vintage_prev')

* Use the version of PDI that smoothes income related to pandemic-era stimulus payments 
* and capital gains taxes
gen lndiff_pdi_3yr_`mad_vintage' = ln(inc_smooth_taxadj_cy_`mad_vintage' / pop_cy_`mad_vintage') ///
	- ln(L3.inc_smooth_taxadj_cy_`mad_vintage' / L3.pop_cy_`mad_vintage')
	
* 6-year real PDI per capita growth rate
* Use the version of PDI that smoothes income related to pandemic-era stimulus payments 
* and capital gains taxes
gen pdi_real_`mad_vintage' = inc_smooth_taxadj_cy_`mad_vintage' / pop_cy_`mad_vintage' / pc_cy_`mad_vintage'			
gen lndiff_pdi_real_6yr_`mad_vintage' = (ln(pdi_real_`mad_vintage') - ln(L6.pdi_real_`mad_vintage')) / 6

* Real premium growth (deflated by PCMED)
* Using the NHE vintage to label real premium growth even though it mixes NHE and MAD data
gen lndiff_pcmed_`mad_vintage' = ln(pcmed_cy_`mad_vintage') - ln(L.pcmed_cy_`mad_vintage')
gen lndiff_prem_demo_`nhe_vintage' = ln(prem_demo_current_`nhe_vintage') - ln(L.prem_demo_current_`nhe_vintage')
gen lndiff_prem_real_demo_`nhe_vintage' = lndiff_prem_demo_`nhe_vintage' - lndiff_pcmed_`mad_vintage'
gen lndiff_prem_`nhe_vintage' = ln(prem_current_`nhe_vintage') - ln(L.prem_current_`nhe_vintage')
gen lndiff_prem_real_`nhe_vintage' = lndiff_prem_`nhe_vintage' - lndiff_pcmed_`mad_vintage'

/* Estimate 1a: Previous baseline specification / Previous data / Demographic adjustment */
preserve
gen pchange_prem_demo = pchange_prem_demo_current_`nhe_vintage_prev'
gen lndiff_pdi_3yr = lndiff_pdi_3yr_`mad_vintage_prev'
di "Executing: `estimates1a_command'"
`estimates1a_command'
estimates store estimates1a
restore

/* Estimate 1b: Previous baseline specification / Previous data / No demographic adjustment */
preserve
gen pchange_prem = pchange_prem_current_`nhe_vintage_prev'
gen lndiff_pdi_3yr = lndiff_pdi_3yr_`mad_vintage_prev'
di "Executing: `estimates1b_command'"
`estimates1b_command'
estimates store estimates1b
restore

/* Estimate 2: Previous baseline specification / Current data / Demographic adjustment */
preserve
gen pchange_prem_demo = pchange_prem_demo_`nhe_vintage'
gen lndiff_pdi_3yr = lndiff_pdi_3yr_`mad_vintage'
di "Executing: `estimates2_command'"
`estimates2_command'
estimates store estimates2
restore

/* Estimate 3a: Current baseline specification / Current data / Demographic adjustment */
preserve
gen lndiff_prem_real_demo = lndiff_prem_real_demo_`nhe_vintage'
gen lndiff_pdi_real_6yr = lndiff_pdi_real_6yr_`mad_vintage'
di "Executing: `estimates3a_command'"
`estimates3a_command'
estimates store estimates3a
restore

/* Estimate 3b: Current baseline specification / Current data / No demographic adjustment */
preserve
gen lndiff_prem_real = lndiff_prem_real_`nhe_vintage'
gen lndiff_pdi_real_6yr = lndiff_pdi_real_6yr_`mad_vintage'
di "Executing: `estimates3b_command'"
`estimates3b_command'
estimates store estimates3b
restore

/* ~~~~~ Generate forecasts ~~~~~ */

/* ~~~ Step 0 (Previous baseline): Forecast using previous specification estimated on old data and old NHE vintage / old MAD vintage for forecasting ~~~ */

/* ~ With demographic adjustment ~ */
preserve 
estimates restore estimates1a

* Generate variables for the Spring 2024 baseline's specification
gen pchange_prem_demo = pchange_prem_demo_current_`nhe_vintage_prev'
gen prem_demo = prem_demo_`nhe_vintage_prev'
gen lndiff_pdi_3yr = lndiff_pdi_3yr_`mad_vintage_prev'

* Use the model to predict future years
foreach y of numlist `forecast1_start'/`forecast1_stop' {
	capture drop prediction
	predict prediction, xb
	replace pchange_prem_demo = prediction if year == `y'
}
replace prem_demo = L.prem_demo * (1 + pchange_prem_demo) if prem_demo == .

* Generate and save output variables 
gen pchange_prem_demo_b`baseline_vintage_prev' = pchange_prem_demo
gen prem_demo_b`baseline_vintage_prev' = prem_demo

keep year pchange_prem_demo_b`baseline_vintage_prev' prem_demo_b`baseline_vintage_prev'
save `forecasts', replace
restore

/* ~ Without demographic adjustment ~ */
preserve 
estimates restore estimates1b

* Generate variables for the Spring 2024 baseline's specification
gen pchange_prem = pchange_prem_current_`nhe_vintage_prev'
gen prem = prem_`nhe_vintage_prev'
gen lndiff_pdi_3yr = lndiff_pdi_3yr_`mad_vintage_prev'

* Use the model to predict future years
foreach y of numlist `forecast1_start'/`forecast1_stop' {
	capture drop prediction
	predict prediction, xb
	replace pchange_prem = prediction if year == `y'
}
replace prem = L.prem* (1 + pchange_prem) if prem == .

* Generate and save output variables 
gen pchange_prem_b`baseline_vintage_prev' = pchange_prem
gen prem_b`baseline_vintage_prev' = prem

keep year pchange_prem_b`baseline_vintage_prev' prem_b`baseline_vintage_prev'
merge 1:1 year using `forecasts', nogen
save `forecasts', replace
restore

/* ~~~ Step 1: Forecast using previous specification estimated on old data and new NHE vintage / old MAD vintage for forecasting ~~~ */
preserve 
estimates restore estimates1a

* Generate variables for the Spring 2024 baseline's specification
gen pchange_prem_demo = pchange_prem_demo_current_`nhe_vintage'
gen prem_demo = prem_demo_`nhe_vintage'
gen lndiff_pdi_3yr = lndiff_pdi_3yr_`mad_vintage_prev'

* Use the model to predict future years
foreach y of numlist `forecast1_start'/`forecast1_stop' {
	capture drop prediction
	predict prediction, xb
	replace pchange_prem_demo = prediction if year == `y'
}
replace prem_demo = L.prem_demo * (1 + pchange_prem_demo) if prem_demo == .

* Generate and save output variables 
gen pchange_prem_demo_b`baseline_vintage_prev'_step1 = pchange_prem_demo
gen prem_demo_b`baseline_vintage_prev'_step1 = prem_demo

keep year pchange_prem_demo_b`baseline_vintage_prev'_step1 prem_demo_b`baseline_vintage_prev'_step1
merge 1:1 year using `forecasts', nogen
save `forecasts', replace
restore

/* ~~~ Step 2: Forecast using previous specification estimated on old data and new NHE vintage / new MAD vintage for forecasting ~~~ */
preserve 
estimates restore estimates1a

* Generate variables for the Spring 2024 baseline's specification
gen pchange_prem_demo = pchange_prem_demo_current_`nhe_vintage'
gen prem_demo = prem_demo_`nhe_vintage'
gen lndiff_pdi_3yr = lndiff_pdi_3yr_`mad_vintage'

* Use the model to predict future years
foreach y of numlist `forecast1_start'/`forecast1_stop' {
	capture drop prediction
	predict prediction, xb
	replace pchange_prem_demo = prediction if year == `y'
}
replace prem_demo = L.prem_demo * (1 + pchange_prem_demo) if prem_demo == .

* Generate and save output variables 
gen pchange_prem_demo_b`baseline_vintage_prev'_step2 = pchange_prem_demo
gen prem_demo_b`baseline_vintage_prev'_step2 = prem_demo

keep year pchange_prem_demo_b`baseline_vintage_prev'_step2 prem_demo_b`baseline_vintage_prev'_step2
merge 1:1 year using `forecasts', nogen
save `forecasts', replace
restore

/* ~~~ Step 3: Forecast using previous specification estimated on new data and new NHE vintage / new MAD vintage for forecasting ~~~ */
preserve 
estimates restore estimates2

* Generate variables for the Spring 2024 baseline's specification
gen pchange_prem_demo = pchange_prem_demo_current_`nhe_vintage'
gen prem_demo = prem_demo_`nhe_vintage'
gen lndiff_pdi_3yr = lndiff_pdi_3yr_`mad_vintage'

* Use the model to predict future years
foreach y of numlist `forecast2_start'/`forecast2_stop' {
	capture drop prediction
	predict prediction, xb
	replace pchange_prem_demo = prediction if year == `y'
}
replace prem_demo = L.prem_demo * (1 + pchange_prem_demo) if prem_demo == .

* Generate and save output variables 
gen pchange_prem_demo_b`baseline_vintage_prev'_step3 = pchange_prem_demo
gen prem_demo_b`baseline_vintage_prev'_step3 = prem_demo

keep year pchange_prem_demo_b`baseline_vintage_prev'_step3 prem_demo_b`baseline_vintage_prev'_step3
merge 1:1 year using `forecasts', nogen
save `forecasts', replace
restore

/* ~~~ Step 4: Forecast using new specification estimated on new data and new NHE vintage / new MAD vintage for forecasting ~~~ */

/* ~ With demographic adjustment ~ */
preserve 
estimates restore estimates3a

* Generate variables for the Spring 2024 baseline's specification
gen lndiff_prem_real_demo = lndiff_prem_real_demo_`nhe_vintage'
gen prem_demo = prem_demo_`nhe_vintage'
gen lndiff_pdi_real_6yr = lndiff_pdi_real_6yr_`mad_vintage'
gen lndiff_pcmed = lndiff_pcmed_`mad_vintage'

* Use the model to predict future years
foreach y of numlist `forecast3_start'/`forecast3_stop' {
	capture drop prediction
	predict prediction, xb
	replace lndiff_prem_real_demo = prediction if year == `y'
}
* Convert to the percentage change growth rate of nominal premium growth
gen pchange_prem_demo = exp(lndiff_prem_real_demo + lndiff_pcmed) - 1
replace prem_demo = L.prem_demo * (1 + pchange_prem_demo) if prem_demo == .

* Generate and save output variables 
gen pchange_prem_demo_b`baseline_vintage_prev'_step4 = pchange_prem_demo
gen prem_demo_b`baseline_vintage_prev'_step4 = prem_demo

keep year pchange_prem_demo_b`baseline_vintage_prev'_step4 prem_demo_b`baseline_vintage_prev'_step4
merge 1:1 year using `forecasts', nogen
save `forecasts', replace
restore

/* ~~~ Step 5 (Current baseline): Forecast with adjustments ~~~ */

/* ~ With demographic adjustment ~ */
preserve 
estimates restore estimates3a

* Generate variables for the Spring 2025 baseline's specification
gen lndiff_prem_real_demo = lndiff_prem_real_demo_`nhe_vintage'
gen prem_demo = prem_demo_`nhe_vintage'
gen lndiff_pdi_real_6yr = lndiff_pdi_real_6yr_`mad_vintage'
gen lndiff_pcmed = lndiff_pcmed_`mad_vintage'

/* Boost the 2024 and 2025 values in response to feedback from stakeholder interviews */
replace lndiff_prem_real_demo = lndiff_prem_real_demo + `adjustment_2024' if year == 2024

* Use the model to predict future years
foreach y of numlist `forecast3_start'/`forecast3_stop' {
	capture drop prediction
	predict prediction, xb
	replace lndiff_prem_real_demo = prediction if year == `y'
	if `y' == 2025 {
		replace lndiff_prem_real_demo = lndiff_prem_real_demo + `adjustment_2025' if year == 2025
	}
}
* Convert to the percentage change growth rate of nominal premium growth
gen pchange_prem_demo = exp(lndiff_prem_real_demo + lndiff_pcmed) - 1
replace prem_demo = L.prem_demo * (1 + pchange_prem_demo) if prem_demo == .

* Generate and save output variables 
gen pchange_prem_demo_b`baseline_vintage' = pchange_prem_demo
gen prem_demo_b`baseline_vintage' = prem_demo

keep year pchange_prem_demo_b`baseline_vintage' prem_demo_b`baseline_vintage'
merge 1:1 year using `forecasts', nogen
save `forecasts', replace
restore

/* ~~~ Without demographic adjustment ~~~ */
preserve 
estimates restore estimates3b

* Generate variables for the Spring 2025 baseline's specification
gen lndiff_prem_real = lndiff_prem_real_`nhe_vintage'
gen prem = prem_`nhe_vintage'
gen lndiff_pdi_real_6yr = lndiff_pdi_real_6yr_`mad_vintage'
gen lndiff_pcmed = lndiff_pcmed_`mad_vintage'

/* Boost the 2024 and 2025 values to account for the effect of GLP1s on private spending */
replace lndiff_prem_real = lndiff_prem_real + `adjustment_2024' if year == 2024

* Use the model to predict future years
foreach y of numlist `forecast3_start'/`forecast3_stop' {
	capture drop prediction
	predict prediction, xb
	replace lndiff_prem_real = prediction if year == `y'
	if `y' == 2025 {
		replace lndiff_prem_real = lndiff_prem_real + `adjustment_2025' if year == 2025
	}
}
* Convert to the percentage change growth rate of nominal premium growth
gen pchange_prem = exp(lndiff_prem_real + lndiff_pcmed) - 1
replace prem = L.prem * (1 + pchange_prem) if prem == .

* Generate and save output variables 
gen pchange_prem_b`baseline_vintage' = pchange_prem
gen prem_b`baseline_vintage' = prem

keep year pchange_prem_b`baseline_vintage' prem_b`baseline_vintage'
merge 1:1 year using `forecasts', nogen
save `forecasts', replace
restore

/* ~~~~~ Format and export the data ~~~~~ */

/* Save the output in long format for easy graphing with R */
tempfile source_data
gen pchange_prem_kff_single_`kff_vintage' = exp(lndiff_prem_kff_single_`kff_vintage') - 1
gen pchange_prem_kff_family_`kff_vintage' = exp(lndiff_prem_kff_family_`kff_vintage') - 1
gen pchange_prem_bls_`bls_vintage' = exp(lndiff_prem_bls_`bls_vintage') - 1
keep year pchange_prem_demo_current_`nhe_vintage_prev' pchange_prem_demo_current_`nhe_vintage' ///
	pchange_prem_kff_single_`kff_vintage' pchange_prem_kff_family_`kff_vintage' ///
	pchange_prem_bls_`bls_vintage'
save `source_data'

/* Save the primary output file, which is in wide format and includes description columns */
use `forecasts', clear

* Transpose
xpose, varname clear
order _varname
foreach var of varlist v* {
    rename `var' cy`=`var'[1]'
}
drop in 1
rename _varname series 

* Fill in the metadata
gen first_historical_year = .
gen last_historical_year = .
gen specification = ""
gen description = ""

local step0demo_cond inlist(series, "pchange_prem_demo_b`baseline_vintage_prev'", "prem_demo_b`baseline_vintage_prev'")
local step0_cond inlist(series, "pchange_prem_b`baseline_vintage_prev'", "prem_b`baseline_vintage_prev'")
local step1_cond inlist(series, "pchange_prem_demo_b`baseline_vintage_prev'_step1", "prem_demo_b`baseline_vintage_prev'_step1")
local step2_cond inlist(series, "pchange_prem_demo_b`baseline_vintage_prev'_step2", "prem_demo_b`baseline_vintage_prev'_step2")
local step3_cond inlist(series, "pchange_prem_demo_b`baseline_vintage_prev'_step3", "prem_demo_b`baseline_vintage_prev'_step3")
local step4_cond inlist(series, "pchange_prem_demo_b`baseline_vintage_prev'_step4", "prem_demo_b`baseline_vintage_prev'_step4")
local step5demo_cond inlist(series, "pchange_prem_demo_b`baseline_vintage'", "prem_demo_b`baseline_vintage'")
local step5_cond inlist(series, "pchange_prem_b`baseline_vintage'", "prem_b`baseline_vintage'")

replace first_historical_year = `estimates1_start' if (`step0demo_cond' | `step1_cond' | `step2_cond')
replace last_historical_year = `estimates1_stop' if (`step0demo_cond' | `step1_cond' | `step2_cond')
replace specification = "`estimates1a_command'" if (`step0demo_cond' | `step1_cond' | `step2_cond')
replace first_historical_year = `estimates1_start' if `step0_cond'
replace last_historical_year = `estimates1_stop' if `step0_cond'
replace specification = "`estimates1b_command'" if `step0_cond'
replace first_historical_year = `estimates2_start' if `step3_cond'
replace last_historical_year = `estimates2_stop' if `step3_cond'
replace specification = "`estimates2_command'" if `step3_cond'
replace first_historical_year = `estimates3_start' if `step4_cond'
replace last_historical_year = `estimates3_stop' if `step4_cond'
replace specification = "`estimates3a_command'" if `step4_cond'
replace first_historical_year = `estimates3_start' if `step5demo_cond'
replace last_historical_year = `estimates3_stop' if `step5demo_cond'
replace specification = "`estimates3a_command'" if `step5demo_cond'
replace first_historical_year = `estimates3_start' if `step5_cond'
replace last_historical_year = `estimates3_stop' if `step5_cond'
replace specification = "`estimates3b_command'" if `step5_cond'
replace description = "percent change from last year's final baseline with demographic adjustments" if series == "pchange_prem_demo_b2024"
replace description = "final previous output with demographic adjustments" if series == "prem_demo_b2024"
replace description = "percent change from updating historical data on previous final baseline with demographic adjustments" if series == "pchange_prem_demo_b2024_step1"
replace description = "level shift from updating historical data on previous final baseline with demographic adjustments" if series == "prem_demo_b2024_step1"
replace description = "percent change from updating economic data on previous final baseline with layered on updated historical data with demographic adjustments" if series == "pchange_prem_demo_b2024_step2"
replace description = "level shift from updating economic data on previous final baseline with layered on updated historical data with demographic adjustments" if series == "prem_demo_b2024_step2"
replace description = "percent change from using current coefficients in the previous PGM specification with updated historical and economic data with demographic adjustments" if series == "pchange_prem_demo_b2024_step3"
replace description = "level shift from using current coefficients in the previous PGM specification with updated historical and economic data and demographic adjustments" if series == "prem_demo_b2024_step3"
replace description = "percent change on previous output from updating the model specification with updated historical and economic data and demographic adjustments" if series == "pchange_prem_demo_b2024_step4"
replace description = "level shift on previous output from updating model specification with updated historical and economic data and demographic adjustments" if series == "prem_demo_b2024_step4"
replace description = "percent change on previous output from updating to new specification with updated historical and economic data and demographic adjustments" if series == "pchange_prem_demo_b2025"
replace description = "current final pgm output with demographc adjustments" if series == "prem_demo_b2025"
replace description = "percent change from previous output without demographic adjustments" if series == "pchange_prem_b2024"
replace description = "level shift from previous ouput without demographic adjustments" if series == "prem_b2024"
replace description = "percent change on current output without demographic adjustments" if series == "pchange_prem_b2025"
replace description = "level shift on current output without demographic adjustments" if series == "prem_b2025"

* Sort
gen sort_order = .
replace sort_order = 1 if `step0demo_cond'
replace sort_order = 2 if `step1_cond'
replace sort_order = 3 if `step2_cond'
replace sort_order = 4 if `step3_cond'
replace sort_order = 5 if `step4_cond'
replace sort_order = 6 if `step5demo_cond'
replace sort_order = 7 if `step0_cond'
replace sort_order = 8 if `step5_cond'
sort sort_order series
drop sort_order

order series first_historical_year last_historical_year specification description cy*
export delimited using "$repo_path\output\baseline_`baseline_vintage'\pgm_`baseline_vintage'.csv", replace

* Export a long version for graphics
use `forecasts', clear
merge 1:1 year using `source_data', nogen
reshape long pchange_prem_ prem_, i(year) j(step) string
rename pchange_prem_ pchange_prem
rename prem_ prem
export delimited using "$repo_path\output\baseline_`baseline_vintage'\pgm_`baseline_vintage'_long_format.csv", replace
