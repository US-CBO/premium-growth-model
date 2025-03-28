/***************************************************************************
* Program:    process_NHE.do
* Purpose:    Process the National Health Expenditures Account data for the 
*             specified vintage. 
*  
* Inputs:
*   - Raw data file: $raw_data_path\raw_data\raw_nhe\\`nhe_vintage'\Table 21 Expenditures, Enrollment and Per Enrollee Estimates of Health Insurance.xlsx
*
* Outputs:
*   - Processed data file: $repo_path\prepped_data\nhe\\`nhe_vintage'\nhe.csv
*
* Notes:
*  	- This script is called from the main.do script. 
*   - The vintage year is passed as an argument to this script.
***************************************************************************/

clear

args nhe_vintage
	
* Import the excel spreadsheet
import excel "$raw_data_path\raw_data\raw_nhe\\`nhe_vintage'\Table 21 Expenditures, Enrollment and Per Enrollee Estimates of Health Insurance.xlsx", ///
	sheet("Table 21") ///
	cellrange(A2:AL63)

* Extract the years to create column names
foreach var of varlist B-AL {
    rename `var' cy`=`var'[1]'
}
	
* Rename the variables
gen variable_name = ""
replace variable_name = "total_phi_exp" if _n == 3
replace variable_name = "medigap_exp" if _n == 7
replace variable_name = "total_phi_enrollment" if _n == 13
replace variable_name = "medigap_enrollment" if _n == 17
replace variable_name = "per_cap_medigap_exp" if _n == 27
replace variable_name = "per_cap_medicare_exp" if _n == 29
keep if variable_name != ""
order variable_name
drop A

* Reshape to long
reshape long cy, i(variable_name) j(year)
reshape wide cy, i(year) j(variable_name) string
rename cy* *_`nhe_vintage'
destring, replace

* Replace zeroes with missing values in medigap series
replace medigap_exp_`nhe_vintage' = . if medigap_exp_`nhe_vintage' == 0
replace per_cap_medigap_exp_`nhe_vintage' = . if per_cap_medigap_exp_`nhe_vintage' == 0

* Export the processed data to a CSV file
export delimited using "$repo_path\prepped_data\nhe\\`nhe_vintage'\nhe", replace
