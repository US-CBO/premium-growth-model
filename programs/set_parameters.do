********************************************************************************
* Set parameters for Premium Growth Model (PMG).
*
* Note: Called from main.do
********************************************************************************

* Location of the raw data
global raw_data_path "set/to/your/raw_data/path"

* Data vintages

* Current and previous baseline vintages
global baseline_vintage 2026
global baseline_vintage_prev = $baseline_vintage - 1

* Current and previous NHEA forecast vintages
global nhe_vintage 2023
global nhe_vintage_prev = $nhe_vintage - 1

* RT: Temporary globals for the Winter 2026 baseline since NHEA has not been updated (these affect generate_premiums.do and merge.do)
global phi_vintage 2024
global phi_vintage_prev = $phi_vintage - 1

* Current and previous CPS vintages and filenames
global cps_vintage 2025
global cps_vintage_prev = $cps_vintage - 1
global cps_filename "cps_00002.dat"
global cps_filename_prev "cps_00003.dat"

* Current and previous macro forecast vintages and directories
* The MAD vintages are defined using MAD's conventions
global mad_vintage_dir 2025
global mad_vintage b251028i
global mad_vintage_dir_prev = $mad_vintage_dir - 1
global mad_vintage_prev b241204f 
global pdi_vintage 241213

* Current and previous KFF vintages
global kff_vintage 2025
global kff_vintage_prev = $kff_vintage - 1

* Current and previous BLS vintages and filenames
global bls_vintage 2025
global bls_vintage_prev = $bls_vintage - 1
global bls_filename "SeriesReport-20251021090455_161d54.xlsx"
global bls_filename_prev "SeriesReport-20250121161727_de9ae5.xlsx"

* First year of the forecast for the current and previous baseline
global current_yr 2024 /* For the Winter 2026 baseline, we did not have updated NHEA data */
global current_yr_prev = 2024

* Last year of the baseline
global baseline_lastyear 2036
