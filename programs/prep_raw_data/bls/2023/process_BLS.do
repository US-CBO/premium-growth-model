/***************************************************************************
* Program:    process_BLS.do
* Purpose:    Process the 2023 vintage of the BLS data 
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

args bls_vintage

// Read and process BLS data
import excel using "$raw_data_path\raw_data\bls\\`bls_vintage'\bls.xlsx", sheet("Processed-Data") firstrow clear
keep year bls

// Convert to growth rates
tsset year
rename bls prem_bls
gen lndiff_prem_bls = ln(prem_bls) - ln(L.prem_bls)
drop prem_bls
drop if lndiff_prem_bls == .

// Export the processed data
export delimited using "$repo_path\prepped_data\bls\\`bls_vintage'\bls", replace
