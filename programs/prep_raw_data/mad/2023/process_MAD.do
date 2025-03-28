/***************************************************************************
* Program:    process_MAD.do
* Purpose:    Process the macro forecast data for the specified vintage. 
**
* Inputs:
*   - Raw data file: $raw_data_path\raw_data\mad\\`mad_vintage'\A_MAD_VARS_`mad_vintage'.xlsx
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

args mad_vintage

// Import the MAD forecast file and remove unnecessary columns
import excel using "$raw_data_path\raw_data\raw_mad\\`mad_vintage'\A_MAD_VARS_`mad_vintage'.xlsx", clear
drop A B  // Drop columns A and B

// Extract the years to create column names
foreach var of varlist D-DD {
    rename `var' cy`=`var'[1]'
}
drop in 1/2

// Keep only the relevant series
keep if inlist(C, "gdp", "yd", "nnia", "cpiumed")

// Reshape to long
reshape long cy, i(C) j(year)
reshape wide cy, i(year) j(C) string

// Destring
destring cygdp cyyd cynnia cycpiumed, /// 
    gen(gdp_cy_`mad_vintage' inc_cy_`mad_vintage' pop_cy_`mad_vintage' cpiumed_cy_`mad_vintage')

// Drop any remaining string variables
ds, has(type string)
drop `r(varlist)'  // Drop variables identified as strings

// Export the cleaned and processed data to a CSV file for further use
export delimited using "$repo_path\prepped_data\mad\\`mad_vintage'\macro_forecast", replace
