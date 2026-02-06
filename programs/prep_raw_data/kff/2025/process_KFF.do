/***************************************************************************
* Program:    process_KFF.do
* Purpose:    Process KFF Employer Health Benefits Survey (EHBS) data for
*             the specified vintage year. Computes growth rates and exports
*             cleaned data.
* 
* Inputs:
*   - Raw data file: $raw_data_path\raw_data\kff\\`kff_vintage'\kff-ehbs.xlsx
*
* Outputs:
*   - Processed data file: $repo_path\prepped_data\kff\\`kff_vintage'\kff.csv
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The vintage year is passed as an argument to this script.
***************************************************************************/

clear

args kff_vintage
	
// Read and process the KFF EHBS data
import excel using "$raw_data_path\raw_data\kff\\`kff_vintage'\kff-ehbs.xlsx", sheet("Data-Entry") firstrow clear
keep year single family

// Convert to growth rates
gen lndiff_prem_kff_single = ln(single) - ln(single[_n-1])
gen lndiff_prem_kff_family = ln(family) - ln(family[_n-1])
drop single family
drop if lndiff_prem_kff_single == . & lndiff_prem_kff_family == .

// Export the processed data
export delimited using "$repo_path\prepped_data\kff\\`kff_vintage'\kff", replace
