/***************************************************************************
* Program:    process_MAD.do
* Purpose:    Process the macro forecast data for the specified vintage. 
**
* Inputs:
*   - Raw data file: $raw_data_path\raw_data\mad\\`mad_vintage'\A_MAD_VARS_`mad_vintage'.xlsx
*   - Raw data file: $raw_data_path\raw_data\mad\\`mad_vintage'\AltYD_Data_Request_`pdi_vintage'.xlsx
*
* Outputs:
*   - Processed data file: $repo_path\mad\\`mad_vintage'\macro_forecast.csv
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The vintage year is passed as an argument to this script.
*   - This script uses files that are not publicly available, so the code
*     is not executable outside of CBO. However, the processed data are 
*     available in the repository.
***************************************************************************/

clear

args mad_vintage pdi_vintage

tempfile macro_forecast

/* ~~~~~ Import the MAD forecast file ~~~~~ */
import excel using "$raw_data_path\raw_data\raw_mad\\`mad_vintage'\A_MAD_VARS_`mad_vintage'.xlsx", clear
drop A B  // Drop columns A and B

// Extract the years to create column names
foreach var of varlist D-DE {
    rename `var' cy`=`var'[1]'
}
drop in 1/2

// Keep only the relevant series
keep if inlist(C, "gdp", "yd", "nnia", "pcmed", "pc")

// Reshape to long
reshape long cy, i(C) j(year)
reshape wide cy, i(year) j(C) string

// Destring
destring cygdp cyyd cynnia cypcmed cypc, /// 
    gen(gdp_cy_`mad_vintage' inc_cy_`mad_vintage' pop_cy_`mad_vintage' pcmed_cy_`mad_vintage' pc_cy_`mad_vintage')

// Drop any remaining string variables
ds, has(type string)
drop `r(varlist)'  // Drop variables identified as strings

save `macro_forecast'

/* To account for the gradual impact of the 2020-2021 stimulus payments and temporary tax changes 
on consumer spending, an adjustment was applied to disposable income to distribute these effects 
over time. This approach smooths short-term fluctuations in disposable income, ensuring that the 
effects of these fiscal measures are more accurately reflected in our forecast of premiums. */
gen inc_smooth_taxadj_cy_`mad_vintage' = inc_cy_`mad_vintage'
replace inc_smooth_taxadj_cy_`mad_vintage' = inc_smooth_taxadj_cy_`mad_vintage' * 0.9873529479 if year == 2020
replace inc_smooth_taxadj_cy_`mad_vintage' = inc_smooth_taxadj_cy_`mad_vintage' * 0.9750665034 if year == 2021
replace inc_smooth_taxadj_cy_`mad_vintage' = inc_smooth_taxadj_cy_`mad_vintage' * 1.0379392787 if year == 2022
replace inc_smooth_taxadj_cy_`mad_vintage' = inc_smooth_taxadj_cy_`mad_vintage' * 1.0126096937 if year == 2023
replace inc_smooth_taxadj_cy_`mad_vintage' = inc_smooth_taxadj_cy_`mad_vintage' * 1.0055180486 if year == 2024

// Export the cleaned and processed data to a CSV file for further use
export delimited using "$repo_path\prepped_data\mad\\`mad_vintage'\macro_forecast", replace
