/***************************************************************************
* Program:    process_BLS.do
* Purpose:    Process the 2024 vintage of the BLS data 
*             Computes growth rates and exports cleaned data.
* 
* Inputs:
*   - Raw data file: $raw_data_path\raw_data\BLS\\`bls_vintage'\bls.xlsx`
*
* Outputs:
*   - Processed data file: $repo_path\prepped_data\bls\\`bls_vintage'\bls.csv
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The vintage year is passed as an argument to this script.
***************************************************************************/

clear 

args bls_vintage bls_filename

// Read and reshape the monthly BLS data
di "Reading data from $raw_data_path\raw_data\bls\\`bls_vintage'\\`bls_filename'"
import excel using "$raw_data_path\raw_data\bls\\`bls_vintage'\\`bls_filename'", ///
	sheet("BLS Data Series") cellrange(A11) firstrow clear
drop if Year == .
rename Year year
rename (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) prem_bls#, addnumber
reshape long prem_bls, i(year) j(month)

// Impute any missing months using annual averages and monthly seasonality
regress prem_bls i.year i.month
predict imputed_prem_bls, xb
replace prem_bls = imputed_prem_bls if prem_bls == .

// Collapse to annual averages
collapse (mean) prem_bls, by(year)
tsset year 

// Convert to growth rates
gen lndiff_prem_bls = ln(prem_bls) - ln(L.prem_bls)
drop prem_bls
drop if lndiff_prem_bls == .

// Export the processed data
export delimited using "$repo_path\prepped_data\bls\\`bls_vintage'\bls", replace
