*************************************************************************
* Program:    main.do
* Purpose:    Organize and run the scripts to process the raw data and 
*             generate forecasts for premium growth.
*
* Parameters:
*   - Repository path derived from the working directory where this program is located.
*   - $raw_data_path: The location of the raw data files.
*   - $baseline_vintage: The baseline vintage year.
*   - $baseline_vintage_prev: The previous baseline vintage year.
*   - $nhe_vintage: The NHEA data vintage to process.
*   - $nhe_vintage_prev: The previous NHEA data vintage to process.
*   - $cps_vintage: The CPS data vintage to use for demographic adjustment.
*   - $cps_vintage_prev: The CPS data vintage to use for demographic adjustment for the previous vintage.
*   - $cps_filename: The CPS data filename.
*   - $cps_filename_prev: The CPS data filename for the previous vintage.
*   - $mad_vintage: The macro forecast vintage to process. Use the vintage formats used by MAD on their wiki.
*   - $mad_vintage_prev: The previous macro forecast vintage to process.
*   - $pdi_vintage: The adjusted PDI vintage to use for premium growth.
*   - $pdi_vintage_prev: The previous adjusted PDI vintage to use for premium growth.
*   - $kff_vintage: The KFF data vintage to use for premium growth.
*   - $kff_vintage_prev: The previous KFF data vintage to process.
*   - $bls_vintage: The BLS data vintage to use for premium growth.
*   - $bls_vintage_prev: The previous BLS data vintage to process.
*   - $bls_filename: The spreadsheet containing the BLS data.
*   - $bls_filename_prev: The spreadsheet containing the BLS data for the previous vintage.
*   - $current_yr: The first year of the current baseline's forecast window.
*   - $current_yr_prev = The first year of the previous baseline's forecast window.
*   - $baseline_lastyear: The last year of the baseline period.
*
* Instructions:
* - Define the location of the raw data and the data vintages you plan to use in set_parameters.do
* - Set the model execution parameters to 1 for programs you would like to execute.
* - Run this master file.
*
* Notes:
* - This script assumes the user has downloaded the raw data to the appropriate directories.
* - This script defines global parameter variables that are passed as arguments to the other scripts.
*   It is set up this way because the scripts do not change depending on whether
*   they are from the current or previous vintage. So, for example, both the current
*   and previous version of process_BLS.do accept "bls_vintage" as an argument, 
*   but the current version is passed the global variable $bls_vintage, and the previous
*   version is passed the global variable $bls_vintage_prev. 
*************************************************************************

set more off  // Disable output pausing
clear         // Clear all data from memory

* Define the repository path, create a log file, and set the parameters
do define_repo_path.do
do create_log_file.do
do set_parameters.do

* Model execution parameters: 1 will run; 0 will not
* To run the prep code, the user has to have downloaded the raw data to the appropriate directories
local prep_cps_data = 0
local prep_cps_data_prev = 0
local prep_nhe_data = 0
local prep_mad_data = 0 // These scripts are not executable outside of CBO
local prep_bls_data = 0
local prep_kff_data = 0
local generate_premiums = 1
local merge_data = 1
local run_current_year_forecast = 1
local run_forecast = 1

*----------------------------------------------------------
* Run the scripts
*----------------------------------------------------------

*** Prepare the raw data

** Files to create the premium variable based on NHEA expenditures

* CPS Data for demographic adjustment
* As these scripts are time-consuming, we provide the option to run them separately
* for the current and previous vintages.
if `prep_cps_data_prev' == 1 {
    do prep_raw_data/cps/$cps_vintage_prev/create_age_sex_index.do $cps_vintage_prev $cps_filename_prev
}
if `prep_cps_data' == 1 {
    do prep_raw_data/cps/$cps_vintage/create_age_sex_index.do $cps_vintage $cps_filename
}

* NHE Data
if `prep_nhe_data' == 1 {
    do prep_raw_data/nhe/$nhe_vintage_prev/process_NHE.do $nhe_vintage_prev
    do prep_raw_data/nhe/$nhe_vintage/process_NHE.do $nhe_vintage
}

* MAD Data
if `prep_mad_data' == 1 {
    do prep_raw_data/mad/$mad_vintage_dir_prev/process_MAD.do $mad_vintage_prev
    do prep_raw_data/mad/$mad_vintage_dir/process_MAD.do $mad_vintage $pdi_vintage
}

** Files on benchmark data

* BLS Data
if `prep_bls_data' == 1 {
    do prep_raw_data/bls/$bls_vintage_prev/process_BLS.do $bls_vintage_prev
    do prep_raw_data/bls/$bls_vintage/process_BLS.do $bls_vintage $bls_filename
}

* KFF Data
if `prep_kff_data' == 1 {
    do prep_raw_data/kff/$kff_vintage_prev/process_KFF.do $kff_vintage_prev
    do prep_raw_data/kff/$kff_vintage/process_KFF.do $kff_vintage
}

*** Generate the premium variable and compile the data

* Generate premiums
if `generate_premiums' == 1 {
    do prep_raw_data/generate_premiums/$nhe_vintage/generate_premiums.do $nhe_vintage $cps_vintage
    do prep_raw_data/generate_premiums/$nhe_vintage_prev/generate_premiums.do $nhe_vintage_prev $mad_vintage_prev $cps_vintage_prev
}

* Merge the data
if `merge_data' == 1 {
    do prep_raw_data/merge/$baseline_vintage/merge.do ///
        $baseline_vintage ///
        $nhe_vintage $nhe_vintage_prev /// 
        $mad_vintage $mad_vintage_prev ///
        $kff_vintage $kff_vintage_prev ///
        $bls_vintage $bls_vintage_prev ///
        $baseline_lastyear
}

*** Generate the forecast

* Generate the forecast for the first year of the forecast window
if `run_current_year_forecast' == 1 {
    do run_model/baseline_$baseline_vintage/pgm_current_yr.do  ///
        $baseline_vintage ///
        $kff_vintage $kff_vintage_prev ///
        $bls_vintage $bls_vintage_prev ///
        $nhe_vintage $nhe_vintage_prev ///
        $current_yr $current_yr_prev
}

* Generate the forecast for the remainder of the forecast window
if `run_forecast' == 1 {
    do run_model/baseline_$baseline_vintage/pgm.do  ///
        $baseline_vintage $baseline_vintage_prev ///
        $nhe_vintage $nhe_vintage_prev ///
        $mad_vintage $mad_vintage_prev ///
        $kff_vintage $kff_vintage_prev ///
        $bls_vintage $bls_vintage_prev
}

log close
